# Build Flood UI seperately to keep image size small
FROM node:15.7.0-alpine3.12 AS FloodUIBuilder
WORKDIR /tmp/flood

RUN echo "Build Flood UI" \
    && wget -qO- https://github.com/johman10/flood-for-transmission/archive/master.tar.gz | tar xz -C . --strip=1 \
    && npm ci \
    && npm run build

FROM alpine:latest AS PrivoxyBuilder
WORKDIR /tmp/privoxy

RUN echo "Build Privoxy" \
    && apk --no-cache add curl bash brotli-dev autoconf build-base libc-utils pkgconf lzip zlib-dev pcre-dev mbedtls-dev w3m \
    && addgroup -S privoxy && adduser -S privoxy -G privoxy \
    && curl -sL https://www.privoxy.org/sf-download-mirror/Sources/3.0.29%20%28stable%29/privoxy-3.0.29-stable-src.tar.gz | tar -C . --strip-components=2 -xz \
    && autoheader \
    && autoconf \
    && ./configure --enable-compression --with-brotli  --with-mbedtls --enable-extended-statistics  \
    && make -j4 \
    && make install-strip

FROM alpine:3.13

VOLUME /data
VOLUME /config

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk --no-cache add bash dumb-init ip6tables ufw@community openvpn shadow transmission-daemon transmission-cli \
        curl jq tzdata openrc openssh unrar git pcre mbedtls \
    && mkdir -p /opt/transmission-ui \
    && echo "Install Combustion" \
    && wget -qO- https://github.com/Secretmapper/combustion/archive/release.tar.gz | tar xz -C /opt/transmission-ui \
    && echo "Install kettu" \
    && wget -qO- https://github.com/endor/kettu/archive/master.tar.gz | tar xz -C /opt/transmission-ui \
    && mv /opt/transmission-ui/kettu-master /opt/transmission-ui/kettu \
    && echo "Install Transmission-Web-Control" \
    && mkdir /opt/transmission-ui/transmission-web-control \
    && curl -sL $(curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url') | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz \
    && ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && rm -rf /tmp/* /var/tmp/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc \
    && addgroup -S privoxy && adduser -S privoxy -G privoxy

# Bring over flood UI from previous build stage
COPY --from=FloodUIBuilder /tmp/flood/public /opt/transmission-ui/flood

COPY --from=PrivoxyBuilder /usr/local/etc/privoxy /usr/local/etc/privoxy
COPY --from=PrivoxyBuilder /usr/local/sbin/privoxy /usr/local/sbin/privoxy

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD scripts /etc/scripts/
ADD privoxy/scripts /opt/privoxy/
ADD privoxy/config /usr/local/etc/privoxy/config

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
    WEBPROXY_PORT=8118 \
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

# Compatability with https://hub.docker.com/r/willfarrell/autoheal/
LABEL autoheal=true

# Expose port and run

#Transmission-RPC
EXPOSE 9091
# Privoxy
EXPOSE 8118

CMD ["dumb-init", "/etc/openvpn/start.sh"]
