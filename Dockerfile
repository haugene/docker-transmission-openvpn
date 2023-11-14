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
    && curl -sL $(curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url') | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz \
    && echo "Install Transmissionic" \
    && wget -qO- https://github.com/6c65726f79/Transmissionic/releases/download/v1.8.0/Transmissionic-webui-v1.8.0.zip | unzip -q - \
    && mv web /opt/transmission-ui/transmissionic


FROM ubuntu:22.04 AS base

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
      libssl-dev

FROM haugene/transmission-builder:4.0.4 as TransmissionBuilder

FROM base

VOLUME /data
VOLUME /config

COPY --from=TransmissionUIs /opt/transmission-ui /opt/transmission-ui
COPY --from=TransmissionBuilder /var/tmp/*.deb /var/tmp/

ARG TBT_VERSION=4.0.4
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "installing Transmission" && set -x \
    && if [[ ${TBT_VERSION} =~ ^4 ]]; then \
      ls -alh /var/tmp/*.deb ;\
      debfile=$(compgen -G /var/tmp/transmission_*_$(dpkg --print-architecture).deb); \
      if [[ -n ${debfile} ]]; then \
      echo "Installing transmission ${TBT_VERSION}" && dpkg -i ${debfile} ;\
      else echo "No /var/tmp/transmission_*_$(dpkg --print-architecture).deb found. Exiting" \
      ; exit ; fi ; \
    else echo "Installing transmission from repository" \
    && export TBT_VERSION=3.00 \
    && apt-get install -y --no-install-recommends transmission-daemon transmission-cli; fi

RUN apt-get update && apt-get install -y \
    dumb-init openvpn privoxy \
    tzdata dnsutils iputils-ping ufw openssh-client git jq curl wget unrar unzip bc \
    && ln -s /usr/local/share/transmission/public_html/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/local/share/transmission/public_html/transmission-app.js /opt/transmission-ui/transmission-web-control/transmission-app.js \
    && ln -s /usr/local/share/transmission/public_html/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
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
