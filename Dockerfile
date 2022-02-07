# syntax=docker/dockerfile:1.2
FROM ubuntu:22.04 as TransmissionBuild

ARG CACHEBUST="1"
RUN echo "$CACHEBUST"
ARG CI=""

RUN --mount=id=apt,sharing=private,target=/var/cache/apt,type=cache \
    --mount=id=apt_lists,sharing=private,target=/var/lib/apt/lists,type=cache \
    apt-get update && \
    [ ! -n "$CI" ] && apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    automake autoconf build-essential clang cmake devscripts libtool pkg-config \
    intltool libcurl4-openssl-dev libglib2.0-dev libevent-dev libminiupnpc-dev \
    xfslibs-dev \
    && sed -i '/deb-src/s/^# //' /etc/apt/sources.list \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee "/usr/share/keyrings/nodesource.gpg" \
    && gpg --no-default-keyring --keyring "/usr/share/keyrings/nodesource.gpg" --list-keys \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x impish main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get build-dep -y transmission \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs \
    && corepack enable

WORKDIR /opt/transmission
ARG YARN_CACHE_FOLDER=/root/.yarn
RUN --mount=id=yarn,target=/root/.yarn,type=cache \
    git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/transmission/transmission.git . \
    && sed -i '/^.*lock"/a \ \ COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_CURRENT_BINARY_DIR}/node_modules" "${CMAKE_CURRENT_SOURCE_DIR}/node_modules"' web/CMakeLists.txt \
    && sed -i '/yarn.lock/d' web/CMakeLists.txt \
    && sed -i '/img-optimize-loader/d' web/package.json \
    && rm web/yarn.lock \
    && mkdir build \ && cd build \
    && cmake .. \
	-DCMAKE_BUILD_TYPE=Release \
	-DENABLE_CLI=ON \
	-DENABLE_GTK=OFF \
	-DENABLE_QT=OFF \
	-DENABLE_TESTS=OFF \
	-DENABLE_WEB=ON \
	-DINSTALL_DOC=OFF \
	-DINSTALL_LIB=ON \
	-DRUN_CLANG_TIDY=OFF \
    && make


FROM alpine:latest as TransmissionUIs

RUN apk --no-cache add curl jq \
    && mkdir -p /opt/transmission-ui \
    && echo "Install Shift" \
    && wget -qO- https://github.com/killemov/Shift/archive/master.tar.gz | tar xz -C /opt/transmission-ui \
    && mv /opt/transmission-ui/Shift-master /opt/transmission-ui/shift \
    && echo "Install Flood for Transmission" \
    && wget -qO- https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz | tar xz -C /opt/transmission-ui \
    && echo "Install Combustion" \
    && wget -qO- https://github.com/Secretmapper/combustion/archive/release.tar.gz | tar xz -C /opt/transmission-ui \
    && echo "Install kettu" \
    && wget -qO- https://github.com/endor/kettu/archive/master.tar.gz | tar xz -C /opt/transmission-ui \
    && mv /opt/transmission-ui/kettu-master /opt/transmission-ui/kettu \
    && echo "Install Transmission-Web-Control" \
    && mkdir /opt/transmission-ui/transmission-web-control \
    && curl -sL $(curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url') | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz


FROM ubuntu:22.04

VOLUME /data
VOLUME /config

COPY --from=TransmissionUIs /opt/transmission-ui /opt/transmission-ui

RUN --mount=id=apt,sharing=private,target=/var/cache/apt,type=cache \
    --mount=id=aptlists,sharing=private,target=/var/lib/apt/lists,type=cache \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    dumb-init openvpn transmission-daemon transmission-cli privoxy \
    tzdata dnsutils iputils-ping ufw openssh-client git jq curl wget unrar unzip bc \
    && ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && apt-get autoremove -y && rm -fr /var/log/* /tmp/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

COPY --from=TransmissionBuild /opt/transmission/build/cli/transmission-cli /usr/bin/transmission-cli
COPY --from=TransmissionBuild /opt/transmission/build/daemon/transmission-daemon /usr/bin/transmission-daemon
COPY --from=TransmissionBuild /opt/transmission/build/utils/transmission-create /usr/bin/transmission-create
COPY --from=TransmissionBuild /opt/transmission/build/utils/transmission-edit /usr/bin/transmission-edit
COPY --from=TransmissionBuild /opt/transmission/build/utils/transmission-remote /usr/bin/transmission-remote
COPY --from=TransmissionBuild /opt/transmission/build/utils/transmission-show /usr/bin/transmission-show
COPY --from=TransmissionBuild /opt/transmission/web/public_html /opt/transmission-ui/trweb

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD scripts /etc/scripts/
ADD privoxy/scripts /opt/privoxy/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_HOME=/data/transmission-home \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    TRANSMISSION_INCOMPLETE_DIR=/data/incomplete \
    TRANSMISSION_WATCH_DIR=/data/watch \
    TRANSMISSION_WEB_HOME=/opt/transmission-ui/trweb \
    CREATE_TUN_DEVICE=true \
    ENABLE_UFW=false \
    UFW_ALLOW_GW_NET=false \
    UFW_EXTRA_PORTS= \
    UFW_DISABLE_IPTABLES_REJECT=false \
    PUID= \
    PGID= \
    PEER_DNS=true \
    PEER_DNS_PIN_ROUTES=true \
    DROP_DEFAULT_ROUTE= \
    WEBPROXY_ENABLED=false \
    WEBPROXY_PORT=8118 \
    WEBPROXY_USERNAME= \
    WEBPROXY_PASSWORD= \
    LOG_TO_STDOUT=false \
    HEALTH_CHECK_HOST=1.1.1.1 \
    SELFHEAL=false

HEALTHCHECK --interval=1m CMD /etc/scripts/healthcheck.sh

# Add labels to identify this image and version
ARG REVISION
# Set env from build argument or default to empty string
ENV REVISION=${REVISION:-""}
LABEL org.opencontainers.image.source=https://github.com/FluxState/docker-transmission-vpn
LABEL org.opencontainers.image.revision=$REVISION

# Compatability with https://hub.docker.com/r/willfarrell/autoheal/
LABEL autoheal=true

# Expose port and run

#Transmission-RPC
EXPOSE 9091
# Privoxy
EXPOSE 8118

CMD ["dumb-init", "/etc/openvpn/start.sh"]
