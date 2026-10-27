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
observers' logins through EMQX's API, on port 18083 of the `emqx` Service (O127). CoreScope stays
off until the T620 moves, where its data is (O94).
