#!/bin/sh
# BXMesh's entrypoint for CoreScope: one container, one process.
# CORESCOPE_ROLE picks which (set per container in deploy/):
#   ingestor  MQTT -> SQLite. Owns the schema migrations.
#   server    the API and web UI on port 3000.
# Both share /app/data, one volume in one pod: the database and the
# ingestor's stats file.
#
# 1. Renders /app/config.json from /app/config.template.json: the MQTT source,
#    our own broker only (BXMESH_BROKER, required), and the admin API key,
#    from /srv/secrets. NSW Mesh's public broker is no longer a source.
# 2. The ingestor: before a new CoreScope release first starts, copies the
#    databases aside to /app/data/backups (migrations can't be undone); keeps 3.
#    Started as an older release that the database was upgraded from (a
#    /rollback: a backup "before-<newer>" whose FROM_RELEASE is this one), it
#    sets the newer databases aside as "after-<newer>-..." and puts that
#    backup back first, and records it in /app/data/.last-restore.
# 3. The server: waits for the ingestor's database and stats file, since it
#    refuses to start before the migrations have run. If it still exits, the
#    container stops and the kubelet starts it again.
set -eu
data=/app/data
release=$(cat /app/RELEASE_TAG)
secret() { tr -d '\r\n' < "/srv/secrets/$1"; }

: "${BXMESH_BROKER:?set BXMESH_BROKER to our broker (deploy/values.yaml, corescope.broker)}"
sources="{\"name\":\"bxmesh\",\"broker\":\"$BXMESH_BROKER\",\"username\":\"corescope\",\"password\":\"$(secret mqtt_password_corescope)\",\"topics\":[\"meshcore/#\"]}"
awk -v sources="[$sources]" -v key="$(secret corescope_api_key)" \
  '{ gsub(/"@@MQTT_SOURCES@@"/, sources); gsub(/@@API_KEY@@/, key); print }' \
  /app/config.template.json > /app/config.json.new
mv /app/config.json.new /app/config.json
cd /app

case "${CORESCOPE_ROLE:-}" in
ingestor)
  previous=$(cat "$data/.corescope-release" 2>/dev/null || true)
  restore=""
  if [ -n "$previous" ] && [ "$previous" != "$release" ]; then
    for b in $(ls -1d "$data"/backups/before-"$previous"-* 2>/dev/null | sort -r); do
      if [ "$(cat "$b/FROM_RELEASE" 2>/dev/null)" = "$release" ]; then restore="$b"; break; fi
    done
  fi
  if [ -n "$restore" ]; then
    aside="$data/backups/after-$previous-$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$aside"
    for f in meshcore.db meshcore.db-wal meshcore.db-shm users.db; do
      if [ -f "$data/$f" ]; then mv "$data/$f" "$aside/"; fi
    done
    for f in meshcore.db meshcore.db-wal meshcore.db-shm users.db; do
      if [ -f "$restore/$f" ]; then cp -p "$restore/$f" "$data/"; fi
    done
    printf '{"from":"%s","to":"%s","restored":"%s","newer_kept":"%s","at":"%s"}\n' "$previous" "$release" \
      "$(basename "$restore")" "$(basename "$aside")" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$data/.last-restore"
    echo "[bxmesh] rolled back $previous -> $release: restored $restore, newer databases kept in $aside"
    ls -1d "$data"/backups/after-* | sort -r | tail -n +4 | xargs -r rm -rf
  elif [ -f "$data/meshcore.db" ] && [ "$previous" != "$release" ]; then
    dest="$data/backups/before-$release-$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$dest"
    for f in meshcore.db meshcore.db-wal meshcore.db-shm users.db; do
      if [ -f "$data/$f" ]; then cp -p "$data/$f" "$dest/"; fi
    done
    cat "$data/.corescope-release" > "$dest/FROM_RELEASE" 2>/dev/null || echo unknown > "$dest/FROM_RELEASE"
    echo "[bxmesh] copied the databases to $dest before starting $release"
    ls -1d "$data"/backups/before-* | sort -r | tail -n +4 | xargs -r rm -rf
  fi
  echo "$release" > "$data/.corescope-release"
  exec /app/corescope-ingestor -config /app/config.json
  ;;
server)
  for _ in $(seq 120); do
    if [ -f "$data/meshcore.db" ] && [ -f "$CORESCOPE_INGESTOR_STATS" ]; then break; fi
    echo "[bxmesh] waiting for the ingestor's database"
    sleep 5
  done
  exec /app/corescope-server -config-dir /app -db "$data/meshcore.db" -public /app/public -port 3000
  ;;
*)
  echo "[bxmesh] set CORESCOPE_ROLE to ingestor or server" >&2
  exit 1
  ;;
esac
