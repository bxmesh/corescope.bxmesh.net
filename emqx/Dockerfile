# EMQX, the MQTT broker observers in Bathurst and the Central West stream into
# (mqtt.bxmesh.net). The official image, with our config, ACL and an entrypoint
# that turns /srv/secrets into EMQX's settings.
FROM emqx/emqx:6.3.2

# /srv/secrets is readable by root only and this image has no tool to drop
# privileges afterwards, so EMQX runs as root. That's root inside an
# unprivileged container (host uid 100000), and EMQX allows it.
USER root
COPY emqx.conf /opt/emqx/etc/emqx.conf
COPY acl.conf /opt/emqx/etc/acl.conf
COPY --chmod=0755 bxmesh-entrypoint.sh /usr/local/bin/bxmesh-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/bxmesh-entrypoint.sh"]
CMD ["/opt/emqx/bin/emqx", "foreground"]
