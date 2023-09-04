FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TBT_VERSION=4.0.4

RUN set -ex; \
    apt-get update; \
    apt-get dist-upgrade -y; \
    apt-get install -y --no-install-recommends \
      automake \
      autoconf \
      build-essential \
      ca-certificates \
      checkinstall \
      cmake \
      curl \
      intltool \
      iproute2 \
      libappindicator3-dev \
      libcurl4-openssl-dev \
      libdeflate-dev \
      libevent-dev \
      libfmt-dev \
      libglib2.0-dev \
      libgtk-3-dev \
      libminiupnpc-dev \
      libnatpmp-dev \
      libpsl-dev \
      libssl-dev \
      libtool \
      nano \
      net-tools \
      pkg-config \ 
      tzdata \
      xz-utils
#This will build the transmission image to re-use in our container
RUN mkdir -p /home/transmission4/ && cd /home/transmission4/ \
    && curl -L -o transmission4.tar.xz "https://github.com/transmission/transmission/releases/download/${TBT_VERSION}/transmission-${TBT_VERSION}.tar.xz" \
    && tar -xf transmission4.tar.xz && cd "transmission-${TBT_VERSION}" && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make && make install \
    && checkinstall -y -D --pkgname transmission  --pakdir /var/tmp --pkgversion=${TBT_VERSION}
