# CoreScope (github.com/Kpa-clawbot/CoreScope, GPL-3.0), the MeshCore packet
# analyser, for the Bathurst mesh at corescope.bxmesh.net. One image, two
# services: corescope-ingestor and corescope-server, one process each
# (CORESCOPE_ROLE; see bxmesh-entrypoint.sh). Its bundled supervisord, Caddy
# and Mosquitto are not used.
#
# RELEASE_TAG is the CoreScope release to run: the tag the owner approved in
# `release` in dmz/services.yml, passed in by plan, so every build is one
# exact vX.Y.Z, never latest or edge.
ARG RELEASE_TAG
FROM ghcr.io/kpa-clawbot/corescope:${RELEASE_TAG}
ARG RELEASE_TAG
# GOMEMLIMIT: CoreScope wants at least 1.5x its working set. 2GiB is the
# ingestor's; the server overrides it (env in dmz/services.yml, with the caps).
ENV DB_PATH=/app/data/meshcore.db \
    CORESCOPE_INGESTOR_STATS=/app/data/ingestor-stats.json \
    GOMEMLIMIT=2GiB
RUN echo "${RELEASE_TAG}" > /app/RELEASE_TAG
COPY config.json /app/config.template.json
COPY --chmod=0755 bxmesh-entrypoint.sh /bxmesh-entrypoint.sh
ENTRYPOINT ["/bxmesh-entrypoint.sh"]
