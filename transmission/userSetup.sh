#!/bin/sh

# More/less taken from https://github.com/linuxserver/docker-baseimage-alpine/blob/3eb7146a55b7bff547905e0d3f71a26036448ae6/root/etc/cont-init.d/10-adduser

RUN_AS=root

if [ -n "$PUID" ] && [ ! "$(id -u root)" -eq "$PUID" ]; then
    RUN_AS=abc
    if [ ! "$(id -u ${RUN_AS})" -eq "$PUID" ]; then
        usermod -o -u "$PUID" ${RUN_AS};
    fi
    if [ ! "$(id -g ${RUN_AS})" -eq "$PGID" ]; then
        groupmod -o -g "$PGID" ${RUN_AS};
    fi

    if [[ "true" = "$DOCKER_LOG" ]]; then
      chown ${RUN_AS}:${RUN_AS} /dev/stdout
    fi

    # Make sure directories exist before chown and chmod
    mkdir -p /config \
        ${TRANSMISSION_HOME} \
        ${TRANSMISSION_DOWNLOAD_DIR} \
        ${TRANSMISSION_INCOMPLETE_DIR} \
        ${TRANSMISSION_WATCH_DIR}

    echo "Enforcing ownership on transmission config directories"
    chown -R ${RUN_AS}:${RUN_AS} \
        /config \
        ${TRANSMISSION_HOME}

    echo "Applying permissions to transmission config directories"
    chmod -R go=rX,u=rwX \
        /config \
        ${TRANSMISSION_HOME}

    if [ "$GLOBAL_APPLY_PERMISSIONS" = true ] ; then
        echo "Setting owner for transmission paths to ${PUID}:${PGID}"
        chown -R ${RUN_AS}:${RUN_AS} \
            ${TRANSMISSION_DOWNLOAD_DIR} \
            ${TRANSMISSION_INCOMPLETE_DIR} \
            ${TRANSMISSION_WATCH_DIR}

        echo "Setting permission for files (644) and directories (755)"
        chmod -R go=rX,u=rwX \
            ${TRANSMISSION_DOWNLOAD_DIR} \
            ${TRANSMISSION_INCOMPLETE_DIR} \

        echo "Setting permission for watch directory (775) and its files (664)"
        chmod -R o=rX,ug=rwX \
            ${TRANSMISSION_WATCH_DIR}
    fi
fi

echo "
-------------------------------------
Transmission will run as
-------------------------------------
User name:   ${RUN_AS}
User uid:    $(id -u ${RUN_AS})
User gid:    $(id -g ${RUN_AS})
-------------------------------------
"

export PUID
export PGID
export RUN_AS
