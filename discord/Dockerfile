# The Discord relay: posts new messages from CoreScope's decoded channels to Discord webhooks
# (relay.py). Python's standard library only, nothing installed. Python 3.15.2 on Debian trixie,
# pinned by digest (Docker Hub, read 2 November 2026).
FROM python:3.15.2-slim-trixie@sha256:c4158543ecb725b99e57d129dfd43d761d4c43e4577b5e23326aabb223cf7f4e
COPY relay.py /app/relay.py
USER 10001:10001
ENTRYPOINT ["python", "-u", "/app/relay.py"]
