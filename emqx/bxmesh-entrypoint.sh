#!/bin/bash
# Secrets (root-only files in /srv/secrets) into the files and variables
# emqx.conf points at, then the image's own entrypoint. /run is a fresh tmpfs
# on every start, so nothing secret lands on disk.
set -euo pipefail
s=/srv/secrets r=/run/emqx-secrets
mkdir -p "$r" && chmod 0700 "$r"

export EMQX_NODE__COOKIE="$(cat "$s/emqx_cookie")"
# The image's entrypoint would name the node after the container's address;
# the built-in database is tied to the name, so keep it fixed.
export EMQX_NODE__NAME="emqx@127.0.0.1"
printf '%s' "$(cat "$s/emqx_dashboard_password")" > "$r/dashboard_password"
# key:secret, from the EMQX_API_KEY secret; the portal and the operator script use it.
printf '%s:administrator\n' "$(cat "$s/emqx_api_key")" > "$r/api_keys"
# CoreScope's subscribe-only login. Imported only while the user doesn't exist
# yet; change its password later through the API.
printf 'user_id,password,is_superuser\ncorescope,%s,false\n' "$(cat "$s/corescope_mqtt_password")" > "$r/bootstrap_users.csv"
chmod 0400 "$r"/*

exec /usr/bin/docker-entrypoint.sh "$@"
