# CoreScope (github.com/Kpa-clawbot/CoreScope, GPL-3.0), the MeshCore packet
# analyser, for the Bathurst mesh at corescope.bxmesh.net. One image, two
# containers in one pod: the ingestor and the server, one process each
# (CORESCOPE_ROLE; see bxmesh-entrypoint.sh). Its bundled supervisord, Caddy
# and Mosquitto are not used.
#
# The CoreScope release to run is the one the owner approved, v3.15.0: an exact
# vX.Y.Z, never latest or edge, pinned by digest. Change both lines together.
FROM ghcr.io/kpa-clawbot/corescope:v3.15.0@sha256:1b263a5bec2fa9eac2ed7f5b9fbaa40265af3472d3ed5706b3ecc1cd7f6a93a7
ARG RELEASE_TAG=v3.15.0
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
