#!/bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

find_proxy_conf()
{
    if [[ -f /usr/local/etc/privoxy/config ]]; then
      PROXY_CONF='/usr/local/etc/privoxy/config'
    elif [[ -f /usr/local/etc/privoxy/privoxy/config ]]; then
      PROXY_CONF='/usr/local/etc/privoxy/privoxy/config'
    else
     echo "ERROR: Could not find privoxy config file. Exiting..."
     exit 1
    fi
}

set_port()
{
  expr $1 + 0 1>/dev/null 2>&1
  status=$?
  if test ${status} -gt 1
  then
    echo "Port [$1]: Not a number" >&2; exit 1
  fi

  # Port: Specify the port which privoxy will listen on.  Please note
  # that should you choose to run on a port lower than 1024 you will need
  # to start privoxy using root.

  if test $1 -lt 1024
  then
    echo "privoxy: $1 is lower than 1024. Ports below 1024 are not permitted.";
    exit 1
  fi

  echo "Setting privoxy port to $1";
  sed -i -e"s,^listen-address .*,listen-address 0.0.0.0:$1," $2
}

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  echo "STARTING PRIVOXY"

    find_proxy_conf
    echo "Found config file $PROXY_CONF, updating settings."

    set_port ${WEBPROXY_PORT} ${PROXY_CONF}

    cd /usr/local/etc/privoxy
    /usr/local/sbin/privoxy config

  echo "privoxy startup script complete."

fi
