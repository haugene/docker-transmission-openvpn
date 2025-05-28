FROM alpine:3.13 as TransmissionUIs

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


FROM base as TransmissionBuilder

ARG DEBIAN_FRONTEND=noninteractive
ARG TBT_VERSION=4.0.3

RUN apt-get update && apt-get install -y curl \
    build-essential automake autoconf libtool pkg-config intltool libcurl4-openssl-dev \
    libglib2.0-dev libevent-dev libminiupnpc-dev libgtk-3-dev libappindicator3-dev libssl-dev cmake xz-utils checkinstall


RUN mkdir -p /home/transmission4/ && cd /home/transmission4/ \
  && curl -L -o transmission4.tar.xz "https://github.com/transmission/transmission/releases/download/4.0.3/transmission-4.0.3.tar.xz" \
  && tar -xf transmission4.tar.xz && cd transmission-4.0.3* && mkdir build && cd build \
  && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make && make install \
  && checkinstall -y -D --pkgname transmission  --pakdir /var/tmp --pkgversion=${TBT_VERSION}


FROM base

VOLUME /data
VOLUME /config

COPY --from=TransmissionUIs /opt/transmission-ui /opt/transmission-ui
COPY --from=TransmissionBuilder /var/tmp/*.deb /var/tmp/

ARG TBT_VERSION=4.0.3
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
    dumb-init jq \
    && ln -s /usr/local/share/transmission/public_html/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/local/share/transmission/public_html/transmission-app.js /opt/transmission-ui/transmission-web-control/transmission-app.js \
    && ln -s /usr/local/share/transmission/public_html/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

ADD updateSettings.py /opt/transmission/
ADD userSetup.sh /opt/transmission/

# Get revision passed as a build argument and set it as env var
ARG BASE_REVISION
ENV BASE_REVISION=${BASE_REVISION:-""}
