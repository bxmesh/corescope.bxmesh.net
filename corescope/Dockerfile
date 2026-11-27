# CoreScope (github.com/Kpa-clawbot/CoreScope, GPL-3.0), the MeshCore packet
# analyser, for the Bathurst mesh at corescope.bxmesh.net. One image, two
# containers in one pod: the ingestor and the server, one process each
# (CORESCOPE_ROLE; see bxmesh-entrypoint.sh). Its bundled supervisord, Caddy
# and Mosquitto are not used.
#
# The CoreScope release to run is the one the owner approved: an exact vX.Y.Z,
# never latest or edge, pinned by digest. Change both lines together; Renovate's
# bump does (renovate.json).
# Built by BXMesh's fork, bxmesh/corescope: upstream's release with three of the
# Live page's defaults changed (its BXMESH.md; O292). An identical change
# upstream is weighed on its merits, never taken in place of ours by itself
# (O723).
FROM ghcr.io/bxmesh/corescope:v3.19.0-bxmesh@sha256:2fddb0380df71212f84e88e60e249d6cbc476c5026cbdbd7511bb9ea93371303
ARG RELEASE_TAG=v3.19.0
# GOMEMLIMIT: CoreScope wants at least 1.5x its working set. 2GiB is the
# ingestor's; the server overrides it (deploy/values.yaml, with the caps).
ENV DB_PATH=/app/data/meshcore.db \
    CORESCOPE_INGESTOR_STATS=/app/data/ingestor-stats.json \
    GOMEMLIMIT=2GiB
RUN echo "${RELEASE_TAG}" > /app/RELEASE_TAG
COPY config.json /app/config.template.json
COPY --chmod=0755 bxmesh-entrypoint.sh /bxmesh-entrypoint.sh
# Not root: the dmz zone's Pod Security is restricted. The image's own
# unprivileged account, corescope (uid 1000), which upstream provides for
# exactly this; it owns /app only so the entrypoint can write config.json
# there. The data volume is the pod's group's (fsGroup 1000, in the chart).
RUN chown 1000:1000 /app
USER 1000:1000
ENTRYPOINT ["/bxmesh-entrypoint.sh"]
