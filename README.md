# corescope.bxmesh.net

CoreScope and the MQTT broker, EMQX, serving `corescope.bxmesh.net`, `mqtt.bxmesh.net` and
`mqtt-admin.bxmesh.net` (behind Access). The design, the layout and the rules are in
[`zindello-cluster/cluster-docs`](https://github.com/zindello-cluster/cluster-docs).

| Path | What it is |
| --- | --- |
| `emqx/` | EMQX 6.3.2 with our config (`emqx.conf`), who may do what (`acl.conf`) and the entrypoint that turns the secrets into its settings. Image `ghcr.io/bxmesh/corescope.bxmesh.net/emqx` |
| `corescope/` | CoreScope v3.15.0 with our config and entrypoint: the ingestor and the server, one process each. Image `ghcr.io/bxmesh/corescope.bxmesh.net/corescope` |
| `deploy/` | The chart Argo CD deploys into `dmz-corescope`, from `main`, when the owner syncs (O14) |
| `discord/` | The Discord relay (`relay.py`, Python's standard library only): posts new messages on `#bathurst` and `Public` to their Discord channels. Image `ghcr.io/bxmesh/corescope.bxmesh.net/discord` |
| `.github/workflows/build.yml` | On each pull request: builds the images it changes, pushes them tagged with the commit SHA, and writes the tags into `deploy/values.yaml` on the pull request's branch |

Observers connect to `mqtt.bxmesh.net` (MQTT over WebSockets, TLS ended at Cloudflare); CoreScope
reads the broker over plain MQTT inside the cluster. bxmesh.net's observers app creates the
observers' logins through EMQX's API, on port 18083 of the `emqx` Service (O127). CoreScope reads
only our broker, and started fresh here: cluster-01's data isn't restored.

## The region (geofence)

CoreScope keeps only nodes inside BxMesh's region: `geo_filter` in `corescope/config.json` is NSW
Mesh's BHS boundary exactly, all 14,414 points of the GeoJSON's ring as published, with no buffer
(the owner, 5 November 2026: the boundary MeshMapper's BHS region uses). Until then it was a
22-point simplification with a 25 km buffer, carried over from cluster-01's setup (zindello/cluster
956d351, 24 October); the owner never asked for or approved either, and the simplified edge strayed
up to 37 km from the boundary, taking in Blackheath, Medlow Bath and Leura. GeoJSON points are
[lon, lat]; CoreScope's are [lat, lon]. With `foreignAdverts.mode` set to `drop`,
an advert from outside it isn't stored at all, so that node never appears. Packets relayed across
the region are still stored. A hop through an out-of-region repeater can't be matched to a known
node, so it may show as unresolved or be credited to an in-region repeater with the same 1-byte
prefix.

Narrowing the filter doesn't remove nodes already stored. CoreScope's geo-prune does
(`POST /api/admin/prune-geo-filter`, admin only): a dry run lists the stored nodes with a GPS fix
outside the filter, and a confirmed run deletes those nodes' records. Nodes without a GPS fix are
always kept, and the packets they sent or relayed stay until the packet retention ages them out.

The polygon is NSW Mesh's BHS region (feature `IATA` `BHS` in
<https://nswmesh.au/geo/All-NSW-Regions-Mini.geojson>, which carries no licence). It's used here
with the permission of an NSW Mesh admin, the owner, given on 28 October 2026.

## Path hops: 1-byte hashes aren't used for mapping

A MeshCore path names each repeater by a short hash of its key, often 1 byte: only 256 values, so
on a busy mesh several repeaters share each one. With `pathTrust.minHashBytesForMapping` at 2 in
`corescope/config.json` (the owner, 2 November 2026), CoreScope doesn't use 1-byte hops as
evidence for its map of links and its neighbour graph, so it draws fewer guessed links. Packets and
their paths are still stored as received. The cost, in CoreScope's own words: it "can remove a
large share of your neighbour-graph edges and resolved paths with nothing in the UI explaining
why", since most of the mesh still uses 1-byte hashes. Back to 1 to undo it.

The customizer's GeoFilter tab is hidden (`customizer.disabledTabs`): the entrypoint renders
`config.json` from the image at every start, so a change saved there would be lost.

## Channels on Discord

`discord/relay.py` posts each new message on MeshCore's `#bathurst` and `Public` channels to a
Discord channel through its webhook: `#bathurst` to #bathurst, `Public` to #nsw-public-traffic (the
owner, 2 November 2026). It reads the messages CoreScope has already decoded, from CoreScope's API
inside the namespace, every 5 seconds, so a message heard by several observers is posted once.
Each post shows as from its mesh sender: the webhook post's name is the sender's name on the mesh.

- It remembers the last message posted on each channel on a small volume, so a restart neither
  skips nor repeats. On its very first start it posts nothing older than the newest message.
- Mentions are off: a mesh message can't ping anyone on Discord. Discord's markdown is escaped, so
  the text shows as it was sent.
- The webhook URLs are secrets, in OpenBao at `secret/dmz-corescope/discord` (`bathurst`, `public`).
- A channel is added in `deploy/values.yaml` (`discord.channels`) with its webhook under a new key
  at that path. `discord.enabled: false` stops it.
