#!/bin/bash
# Source our persisted env variables from container startup

. /etc/transmission/environment-variables.sh
source /etc/openvpn/utils.sh

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  pkill privoxy

fi
