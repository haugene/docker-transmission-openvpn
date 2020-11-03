FROM alpine:3.12

VOLUME /data
VOLUME /config

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk --no-cache add bash dumb-init ip6tables ufw@community openvpn shadow transmission-daemon transmission-cli curl jq tzdata openrc tinyproxy tinyproxy-openrc openssh unrar \
    && mkdir -p /opt/transmission-ui \
    && echo "Install Combustion" \
    && wget -qO- https://github.com/Secretmapper/combustion/archive/release.tar.gz | tar xz -C /opt/transmission-ui \
    && echo "Install kettu" \
    && wget -qO- https://github.com/endor/kettu/archive/master.tar.gz | tar xz -C /opt/transmission-ui \
    && mv /opt/transmission-ui/kettu-master /opt/transmission-ui/kettu \
    && echo "Install Transmission-Web-Control" \
    && mkdir /opt/transmission-ui/transmission-web-control \
    && curl -sL `curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url'` | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz \
    && ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && rm -rf /tmp/* /var/tmp/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD tinyproxy /opt/tinyproxy/
ADD scripts /etc/scripts/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_HOME=/data/transmission-home \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    TRANSMISSION_INCOMPLETE_DIR=/data/incomplete \
    TRANSMISSION_WATCH_DIR=/data/watch \
    CREATE_TUN_DEVICE=true \
    ENABLE_UFW=false \
    UFW_ALLOW_GW_NET=false \
    UFW_EXTRA_PORTS= \
    UFW_DISABLE_IPTABLES_REJECT=false \
    PUID= \
    PGID= \
    DROP_DEFAULT_ROUTE= \
    WEBPROXY_ENABLED=false \
    WEBPROXY_PORT=8888 \
    WEBPROXY_USERNAME= \
    WEBPROXY_PASSWORD= \
    LOG_TO_STDOUT=false \
    HEALTH_CHECK_HOST=google.com

HEALTHCHECK --interval=1m CMD /etc/scripts/healthcheck.sh

# Add labels to identify this image and version
ARG REVISION
# Set env from build argument or default to empty string
ENV REVISION=${REVISION:-""}
LABEL org.opencontainers.image.source=https://github.com/haugene/docker-transmission-openvpn
LABEL org.opencontainers.image.revision=$REVISION

# Expose port and run
EXPOSE 9091
CMD ["dumb-init", "/etc/openvpn/start.sh"]
