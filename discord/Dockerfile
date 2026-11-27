# The Discord relay: posts new messages from CoreScope's decoded channels to Discord webhooks
# (relay.py). Python's standard library only, nothing installed. Python 3.15.2 on Debian trixie,
# pinned by digest (Docker Hub, read 2 November 2026).
FROM python:3.15.2-slim-trixie@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5
COPY relay.py /app/relay.py
USER 10001:10001
ENTRYPOINT ["python", "-u", "/app/relay.py"]
