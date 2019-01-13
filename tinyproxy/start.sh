#!/bin/sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

PROXY_CONF='/etc/tinyproxy/tinyproxy.conf'

set_port()
{
  expr $1 + 0 1>/dev/null 2>&1
  statut=$?
  if test $statut -gt 1
  then
    echo "Port [$1]: Not a number" >&2; exit 1
  fi

  # Port: Specify the port which tinyproxy will listen on.  Please note
  # that should you choose to run on a port lower than 1024 you will need
  # to start tinyproxy using root.

  if test $1 -lt 1024
  then
    echo "tinyproxy: $1 is lower than 1024. Ports below 1024 are not permitted.";
    exit 1
  fi

  echo "Setting tinyproxy port to $1";
  sed -i -e"s,^Port .*,Port $1," $2
}

if [ "${WEBPROXY_ENABLED}" = "true" ]; then

  echo "STARTING TINYPROXY"

  set_port ${WEBPROXY_PORT} ${PROXY_CONF}

  # Allow all clients
  sed -i -e"s/^Allow /#Allow /" ${PROXY_CONF}

  /etc/init.d/tinyproxy start
  echo "Tinyproxy startup script complete."

fi
