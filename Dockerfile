FROM alpine:latest AS TransmissionUIs

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
    && echo "Install Transmissionic" \
    && wget -qO- https://github.com/6c65726f79/Transmissionic/releases/download/v1.8.0/Transmissionic-webui-v1.8.0.zip | unzip -q - \
    && mv web /opt/transmission-ui/transmissionic

#copied transmission web control from local archive
ADD transmission_web_control_1.6.33.tar.xz /opt/transmission-ui/

RUN  echo "Install Transmission-Web-Control" \
     && ln -fs /usr/local/share/transmission/public_html/images /opt/transmission-ui/transmission-web-control/ \
     && ln -fs /usr/local/share/transmission/public_html/transmission-app.js /opt/transmission-ui/transmission-web-control/transmission-app.js \
     && ln -fs /usr/local/share/transmission/public_html/index.html /opt/transmission-ui/transmission-web-control/index.original.html ;

FROM ubuntu:24.04 AS base

ARG TBT_VERSION=4.0.6
ARG DEBIAN_FRONTEND=noninteractive

RUN set -ex; \
    apt-get update; \
    apt-get dist-upgrade -y; \
    apt-get install -y --no-install-recommends \
        tzdata \
        iproute2 \
        net-tools \
        nano \
        ca-certificates \
        curl \
        libcurl4-openssl-dev \
        libdeflate-dev \
        libevent-dev \
        libfmt-dev \
        libminiupnpc-dev \
        libnatpmp-dev \
        libpsl-dev \
        libssl-dev \
        natpmpc \
  && apt-get clean -y

FROM base AS TransmissionBuilder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        checkinstall \
        cmake \
        intltool \
        libappindicator3-dev \
        libglib2.0-dev \
        libgtk-3-dev \
        libtool \
        pkg-config \
        xz-utils \
 && mkdir -p /home/transmission4/ \
 && cd /home/transmission4/ \
 && curl -L -o transmission4.tar.xz "https://github.com/transmission/transmission/releases/download/${TBT_VERSION}/transmission-${TBT_VERSION}.tar.xz" \
 && tar -xf transmission4.tar.xz \
 && cd "transmission-${TBT_VERSION}" \
 && mkdir build \
 && cd build \
 && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. \
 && make \
 && make install \
 && checkinstall -y -D --pkgname transmission --pakdir /var/tmp --pkgversion=${TBT_VERSION} \
 && apt-get clean -y

FROM base

VOLUME /data
VOLUME /config

COPY --from=TransmissionUIs /opt/transmission-ui /opt/transmission-ui
COPY --from=TransmissionBuilder /var/tmp/*.deb /var/tmp/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing transmission ${TBT_VERSION}" \
  && ls -alh /var/tmp/*.deb  \
  && debfile="$(compgen -G /var/tmp/transmission_*_$(dpkg --print-architecture).deb)" \
  && dpkg -i "${debfile}" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
        bc \
        dnsutils \
        dumb-init \
        git \
        iputils-ping \
        jq \
        openssh-client \
        openvpn \
        privoxy \
        ufw \
        unrar \
        unzip \
        wget \
  && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
  && groupmod -g 1001 ubuntu \
  && groupmod -g 1000 users \
  && useradd -u 911 -U -d /config -s /bin/false abc \
  && usermod -G users abc

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD scripts /etc/scripts/
ADD privoxy/scripts /opt/privoxy/

# Support legacy IPTables commands
RUN update-alternatives --set iptables $(which iptables-legacy) && \
    update-alternatives --set ip6tables $(which ip6tables-legacy)

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    OPENVPN_OPTS= \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_HOME=/config/transmission-home \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_RPC_USERNAME= \
    TRANSMISSION_RPC_PASSWORD= \
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
    PEER_DNS=true \
    PEER_DNS_PIN_ROUTES=true \
    DROP_DEFAULT_ROUTE= \
    WEBPROXY_ENABLED=false \
    WEBPROXY_PORT=8118 \
    WEBPROXY_BIND_ADDRESS= \
    WEBPROXY_USERNAME= \
    WEBPROXY_PASSWORD= \
    LOG_TO_STDOUT=false \
    HEALTH_CHECK_HOST=google.com \
    SELFHEAL=false

HEALTHCHECK --interval=1m CMD /etc/scripts/healthcheck.sh

# Pass revision as a build arg, set it as env var
ARG REVISION
ENV REVISION=${REVISION:-""}

# Compatability with https://hub.docker.com/r/willfarrell/autoheal/
LABEL autoheal=true

# Expose ports and run

#Transmission-RPC
EXPOSE 9091
# Privoxy
EXPOSE 8118

CMD ["dumb-init", "/etc/openvpn/start.sh"]
