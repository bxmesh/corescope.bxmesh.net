# CLAUDE.md — bxmesh/corescope.bxmesh.net

CoreScope and the MQTT broker, EMQX. Read
[`zindello-cluster/cluster-docs`](https://github.com/zindello-cluster/cluster-docs) before doing
anything here: its `CLAUDE.md`, the spec (`spec/design.md`), the binding layout (`spec/layout.md`)
and the rules (`spec/rules.md`). The rules apply here in full: an agent prepares a pull request and
never merges it or syncs in Argo. BxMesh never deploys itself (O14). CoreScope's release is the one
the owner approved; a new one is a pull request with its changelog, risks and rollback.
