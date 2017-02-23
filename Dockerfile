# Transmission and OpenVPN
#
# Version 1.15

FROM ubuntu:14.04
MAINTAINER Kristian Haugene

VOLUME /data
VOLUME /config

# Update packages and install software
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository multiverse \
    && add-apt-repository ppa:transmissionbt/ppa \
    && apt-get update \
    && apt-get install -y transmission-cli transmission-common transmission-daemon \
    && apt-get install -y openvpn curl rar unrar zip unzip wget \
    && curl -sLO https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64.deb \
    && dpkg -i dumb-init_*.deb \
    && rm -rf dumb-init_*.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -L https://github.com/jwilder/dockerize/releases/download/v0.0.2/dockerize-linux-amd64-v0.0.2.tar.gz | tar -C /usr/local/bin -xzv \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    "TRANSMISSION_ALT_SPEED_DOWN=50" \
    "TRANSMISSION_ALT_SPEED_ENABLED=false" \
    "TRANSMISSION_ALT_SPEED_TIME_BEGIN=540" \
    "TRANSMISSION_ALT_SPEED_TIME_DAY=127" \
    "TRANSMISSION_ALT_SPEED_TIME_ENABLED=false" \
    "TRANSMISSION_ALT_SPEED_TIME_END=1020" \
    "TRANSMISSION_ALT_SPEED_UP=50" \
    "TRANSMISSION_BIND_ADDRESS_IPV4=0.0.0.0" \
    "TRANSMISSION_BIND_ADDRESS_IPV6=::" \
    "TRANSMISSION_BLOCKLIST_ENABLED=false" \
    "TRANSMISSION_BLOCKLIST_URL=http://www.example.com/blocklist" \
    "TRANSMISSION_CACHE_SIZE_MB=4" \
    "TRANSMISSION_DHT_ENABLED=true" \
    "TRANSMISSION_DOWNLOAD_DIR=/data/completed" \
    "TRANSMISSION_DOWNLOAD_LIMIT=100" \
    "TRANSMISSION_DOWNLOAD_LIMIT_ENABLED=0" \
    "TRANSMISSION_DOWNLOAD_QUEUE_ENABLED=true" \
    "TRANSMISSION_DOWNLOAD_QUEUE_SIZE=5" \
    "TRANSMISSION_ENCRYPTION=1" \
    "TRANSMISSION_IDLE_SEEDING_LIMIT=30" \
    "TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED=false" \
    "TRANSMISSION_INCOMPLETE_DIR=/data/incomplete" \
    "TRANSMISSION_INCOMPLETE_DIR_ENABLED=true" \
    "TRANSMISSION_LPD_ENABLED=false" \
    "TRANSMISSION_MAX_PEERS_GLOBAL=200" \
    "TRANSMISSION_MESSAGE_LEVEL=2" \
    "TRANSMISSION_PEER_CONGESTION_ALGORITHM=" \
    "TRANSMISSION_PEER_ID_TTL_HOURS=6" \
    "TRANSMISSION_PEER_LIMIT_GLOBAL=200" \
    "TRANSMISSION_PEER_LIMIT_PER_TORRENT=50" \
    "TRANSMISSION_PEER_PORT=51413" \
    "TRANSMISSION_PEER_PORT_RANDOM_HIGH=65535" \
    "TRANSMISSION_PEER_PORT_RANDOM_LOW=49152" \
    "TRANSMISSION_PEER_PORT_RANDOM_ON_START=false" \
    "TRANSMISSION_PEER_SOCKET_TOS=default" \
    "TRANSMISSION_PEX_ENABLED=true" \
    "TRANSMISSION_PORT_FORWARDING_ENABLED=false" \
    "TRANSMISSION_PREALLOCATION=1" \
    "TRANSMISSION_PREFETCH_ENABLED=1" \
    "TRANSMISSION_QUEUE_STALLED_ENABLED=true" \
    "TRANSMISSION_QUEUE_STALLED_MINUTES=30" \
    "TRANSMISSION_RATIO_LIMIT=2" \
    "TRANSMISSION_RATIO_LIMIT_ENABLED=false" \
    "TRANSMISSION_RENAME_PARTIAL_FILES=true" \
    "TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=false" \
    "TRANSMISSION_RPC_BIND_ADDRESS=0.0.0.0" \
    "TRANSMISSION_RPC_ENABLED=true" \
    "TRANSMISSION_RPC_PASSWORD=password" \
    "TRANSMISSION_RPC_PORT=9091" \
    "TRANSMISSION_RPC_URL=/transmission/" \
    "TRANSMISSION_RPC_USERNAME=username" \
    "TRANSMISSION_RPC_WHITELIST=127.0.0.1" \
    "TRANSMISSION_RPC_WHITELIST_ENABLED=false" \
    "TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=true" \
    "TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED=false" \
    "TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME=" \
    "TRANSMISSION_SEED_QUEUE_ENABLED=false" \
    "TRANSMISSION_SEED_QUEUE_SIZE=10" \
    "TRANSMISSION_SPEED_LIMIT_DOWN=100" \
    "TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED=false" \
    "TRANSMISSION_SPEED_LIMIT_UP=100" \
    "TRANSMISSION_SPEED_LIMIT_UP_ENABLED=false" \
    "TRANSMISSION_START_ADDED_TORRENTS=true" \
    "TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES=false" \
    "TRANSMISSION_UMASK=2" \
    "TRANSMISSION_UPLOAD_LIMIT=100" \
    "TRANSMISSION_UPLOAD_LIMIT_ENABLED=0" \
    "TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT=14" \
    "TRANSMISSION_UTP_ENABLED=true" \
    "TRANSMISSION_WATCH_DIR=/data/watch" \
    "TRANSMISSION_WATCH_DIR_ENABLED=true" \
    "TRANSMISSION_HOME=/data/transmission-home" \
    PUID=\
    PGID=

# Expose port and run
EXPOSE 9091
CMD ["dumb-init", "/etc/openvpn/start.sh"]
