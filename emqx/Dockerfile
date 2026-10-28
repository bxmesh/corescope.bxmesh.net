# EMQX, the MQTT broker observers in Bathurst and the Central West stream into
# (mqtt.bxmesh.net). The official image, with our config, ACL and an entrypoint
# that turns /srv/secrets into EMQX's settings.
FROM emqx/emqx:6.3.2@sha256:135116400e11b25224350b2e55c874f4e224d357b593fb554ca1b1f398c631ac

# EMQX runs as the image's own user, emqx (uid 1000), as the dmz zone's Pod
# Security (restricted) requires. On cluster-01 it ran as root only because
# /srv/secrets was readable by root alone; the chart makes the secrets readable
# by the pod's group (fsGroup 1000) instead. The files below stay root-owned
# and read-only to EMQX, which writes only to data/ and log/.
COPY emqx.conf /opt/emqx/etc/emqx.conf
COPY acl.conf /opt/emqx/etc/acl.conf
COPY --chmod=0755 bxmesh-entrypoint.sh /usr/local/bin/bxmesh-entrypoint.sh
USER 1000:1000
ENTRYPOINT ["/usr/local/bin/bxmesh-entrypoint.sh"]
CMD ["/opt/emqx/bin/emqx", "foreground"]
