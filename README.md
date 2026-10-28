# corescope.bxmesh.net

CoreScope and the MQTT broker, EMQX, serving `corescope.bxmesh.net`, `mqtt.bxmesh.net` and
`mqtt-admin.bxmesh.net` (behind Access). The design, the layout and the rules are in
[`zindello-cluster/cluster-docs`](https://github.com/zindello-cluster/cluster-docs).

| Path | What it is |
| --- | --- |
| `emqx/` | EMQX 6.3.2 with our config (`emqx.conf`), who may do what (`acl.conf`) and the entrypoint that turns the secrets into its settings. Image `ghcr.io/bxmesh/corescope.bxmesh.net/emqx` |
| `corescope/` | CoreScope v3.15.0 with our config and entrypoint: the ingestor and the server, one process each. Image `ghcr.io/bxmesh/corescope.bxmesh.net/corescope` |
| `deploy/` | The chart Argo CD deploys into `dmz-corescope`, from `main`, when the owner syncs (O14) |
| `.github/workflows/build.yml` | On each pull request: builds the images it changes, pushes them tagged with the commit SHA, and writes the tags into `deploy/values.yaml` on the pull request's branch |

Observers connect to `mqtt.bxmesh.net` (MQTT over WebSockets, TLS ended at Cloudflare); CoreScope
reads the broker over plain MQTT inside the cluster. bxmesh.net's observers app creates the
observers' logins through EMQX's API, on port 18083 of the `emqx` Service (O127). CoreScope reads
only our broker, and started fresh here: cluster-01's data isn't restored.

## The region (geofence)

CoreScope keeps only nodes inside BxMesh's region: `geo_filter` in `corescope/config.json` is the
BHS region, simplified to 22 points, with a 25 km buffer. With `foreignAdverts.mode` set to `drop`,
an advert from outside it isn't stored at all, so that node never appears. Packets relayed across
the region are still stored. A hop through an out-of-region repeater can't be matched to a known
node, so it may show as unresolved or be credited to an in-region repeater with the same 1-byte
prefix.

The polygon is derived from NSW Mesh's BHS region (feature `IATA` `BHS` in
<https://nswmesh.au/geo/All-NSW-Regions-Mini.geojson>, which carries no licence). It's used here
with the permission of an NSW Mesh admin, the owner, given on 28 October 2026.

The customizer's GeoFilter tab is hidden (`customizer.disabledTabs`): the entrypoint renders
`config.json` from the image at every start, so a change saved there would be lost.
