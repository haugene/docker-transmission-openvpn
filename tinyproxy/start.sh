#!/bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

find_proxy_conf()
{
    if [[ -f /etc/tinyproxy.conf ]]; then
      PROXY_CONF='/etc/tinyproxy.conf'
    elif [[ -f /etc/tinyproxy/tinyproxy.conf ]]; then
      PROXY_CONF='/etc/tinyproxy/tinyproxy.conf'
    else
     echo "ERROR: Could not find tinyproxy config file. Exiting..."
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

set_authentication()
{
  echo "Setting tinyproxy basic auth";
  echo "BasicAuth $1 $2" >> $3
}

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  echo "STARTING TINYPROXY"

  find_proxy_conf
  echo "Found config file $PROXY_CONF, updating settings."

  set_port ${WEBPROXY_PORT} ${PROXY_CONF}

  if [[ ! -z "${WEBPROXY_USERNAME}" ]] && [[ ! -z "${WEBPROXY_PASSWORD}" ]]; then
    set_authentication ${WEBPROXY_USERNAME} ${WEBPROXY_PASSWORD} ${PROXY_CONF}
  fi

  # Allow all clients
  sed -i -e"s/^Allow /#Allow /" ${PROXY_CONF}

  # Disable Via Header for privacy (leaks that you're using a proxy)
  sed -i -e "s/#DisableViaHeader/DisableViaHeader/" ${PROXY_CONF}

  # Lower log level for privacy (writes dns names by default)
  sed -i -e "s/LogLevel Info/LogLevel Critical/" ${PROXY_CONF}

  /etc/init.d/tinyproxy start
  echo "Tinyproxy startup script complete."

fi
