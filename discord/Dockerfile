# The Discord relay: posts new messages from CoreScope's decoded channels to Discord webhooks
# (relay.py). Python's standard library only, nothing installed. Python 3.15.2 on Debian trixie,
# pinned by digest (Docker Hub, read 2 November 2026).
FROM python:3.15.2-slim-trixie@sha256:8c13a3f37a6a5b71498228e902c4b9f51c1f7900d49fabf71f9a650c6120e0d0
COPY relay.py /app/relay.py
USER 10001:10001
ENTRYPOINT ["python", "-u", "/app/relay.py"]
