#!/bin/bash

# More/less taken from https://github.com/linuxserver/docker-baseimage-alpine/blob/3eb7146a55b7bff547905e0d3f71a26036448ae6/root/etc/cont-init.d/10-adduser
# source /etc/openvpn/utils.sh

RUN_AS=root

if [ -n "$PUID" ] && [ ! "$(id -u root)" -eq "$PUID" ]; then
    RUN_AS=abc
    if [ ! "$(id -u ${RUN_AS})" -eq "$PUID" ]; then
        usermod -o -u "$PUID" ${RUN_AS};
    fi
    if [ -n "$PGID" ] && [ ! "$(id -g ${RUN_AS})" -eq "$PGID" ]; then
        groupmod -o -g "$PGID" ${RUN_AS};
    fi

    if [[ "true" = "$LOG_TO_STDOUT" ]]; then
      chown ${RUN_AS}:${RUN_AS} /dev/stdout
    fi


    # Make sure directories exist before chown and chmod
    mkdir -p /config \
        "${TRANSMISSION_HOME}" \
        "${TRANSMISSION_DOWNLOAD_DIR}" \
        "${TRANSMISSION_INCOMPLETE_DIR}" \
        "${TRANSMISSION_WATCH_DIR}"

    echo "Enforcing ownership on transmission directories"
    chown -R ${RUN_AS}:${RUN_AS} \
        /config \
        "${TRANSMISSION_HOME}"

    echo "Applying permissions to transmission directories"
    chmod -R go=rX,u=rwX \
        /config \
        "${TRANSMISSION_HOME}"

    if [ "$GLOBAL_APPLY_PERMISSIONS" = true ] ; then
        echo "Setting owner for transmission paths to ${PUID}:${PGID}"
        chown -R ${RUN_AS}:${RUN_AS} \
            "${TRANSMISSION_DOWNLOAD_DIR}" \
            "${TRANSMISSION_INCOMPLETE_DIR}" \
            "${TRANSMISSION_WATCH_DIR}"

        echo "Setting permissions for download and incomplete directories"
        
        if [ -z "$TRANSMISSION_UMASK" ] ; then
            # fetch from settings.json if not defined in environment
            # because updateSettings.py is called after this script is run
            TRANSMISSION_UMASK=$(jq .umask ${TRANSMISSION_HOME}/settings.json)
        fi

        TRANSMISSION_UMASK_OCTAL=$( printf "%o\n" "${TRANSMISSION_UMASK}" )

        DIR_PERMS=$( printf '%o\n' $(( 8#777 & ~TRANSMISSION_UMASK)) )
        FILE_PERMS=$( printf '%o\n' $(( 8#666 & ~TRANSMISSION_UMASK)) )
        
        echo "umask: ${TRANSMISSION_UMASK_OCTAL}"
        echo "Directories: ${DIR_PERMS}"
        echo "Files: ${FILE_PERMS}"

        find "${TRANSMISSION_DOWNLOAD_DIR}" "${TRANSMISSION_INCOMPLETE_DIR}" -type d \
        -exec chmod "${DIR_PERMS}" {} +
        find "${TRANSMISSION_DOWNLOAD_DIR}" "${TRANSMISSION_INCOMPLETE_DIR}" -type  f \
        -exec chmod "${FILE_PERMS}" {} +

        echo "Setting permission for watch directory (775) and its files (664)"
        chmod -R o=rX,ug=rwX \
            "${TRANSMISSION_WATCH_DIR}"
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