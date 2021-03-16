#!/bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  echo "STARTING PRIVOXY"

    cd /usr/local/etc/privoxy
    /usr/local/sbin/privoxy config

  echo "privoxy startup script complete."

fi
