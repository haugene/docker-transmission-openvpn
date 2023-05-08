FROM haugene/transmission-base:sha-1956659

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y wireguard nginx \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ADD start.sh /opt/wireguard/start.sh
ADD nginx_server.conf /opt/nginx/server.conf
ADD transmission-default-settings.json /opt/transmission/default-settings.json

# Set some environment variables needed in various scripts
ENV TRANSMISSION_HOME=/config/transmission-home \
    TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    TRANSMISSION_INCOMPLETE_DIR=/data/incomplete \
    TRANSMISSION_WATCH_DIR=/data/watch \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_UMASK=2

# Get base_revision passed as a build argument and set it as env var
ARG REVISION
ENV REVISION=${REVISION:-""}

CMD ["dumb-init", "/opt/wireguard/start.sh"]