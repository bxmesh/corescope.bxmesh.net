# The Discord relay: posts new messages from CoreScope's decoded channels to Discord webhooks
# (relay.py). Python's standard library only, nothing installed. Python 3.15.2 on Debian trixie,
# pinned by digest (Docker Hub, read 2 November 2026).
FROM python:3.15.2-slim-trixie@sha256:08a4c22c92b79ec821a7ad49768480039ee5b7accac3955228e75366e30abc8e
COPY relay.py /app/relay.py
USER 10001:10001
ENTRYPOINT ["python", "-u", "/app/relay.py"]
