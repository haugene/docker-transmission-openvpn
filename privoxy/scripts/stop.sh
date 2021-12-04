#!/bin/bash
# Source our persisted env variables from container startup
DEBUG=${DEBUG:-"false"}
[[ ${DEBUG} != "false" ]] && set -x

. /etc/transmission/environment-variables.sh

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  pkill privoxy

fi
