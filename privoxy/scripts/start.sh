#!/bin/bash


# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh
source /etc/openvpn/utils.sh

set_port()
{
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
    echo "Privoxy: ERROR. Supplied port $1 is not a number" >&2; exit 1
  fi

  # Port: Specify the port which privoxy will listen on.  Please note
  # that should you choose to run on a port lower than 1024 you will need
  # to start privoxy using root.

  if test "$1" -lt 1024
  then
    echo "privoxy: $1 is lower than 1024. Ports below 1024 are not permitted.";
    exit 1
  fi

  echo "Privoxy: Setting port to $1";

# Remove the listen-address for IPv6 for now. IPv6 compatibility should come later
  sed -i -E "s/^listen-address\s+\[\:\:1.*//" "$3"

  # Set the port for the IPv4 interface
  if [[ "$2" = "" ]]; then
    adr=$(ip -4  a show eth0| grep -oP "(?<=inet )([^/]+)")
    adr=${adr:-"0.0.0.0"}
  else
    adr=$2
  fi
  echo "Privoxy: Setting listen address to $adr";
  sed -i -E "s/^listen-address.*/listen-address ${adr}:$1/" "$3"
}

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  echo "Privoxy: Starting"

  PROXY_CONF=/etc/privoxy/config
  echo "Privoxy: Using config file at $PROXY_CONF"

  set_port "${WEBPROXY_PORT}" "${WEBPROXY_BIND_ADDRESS}" "${PROXY_CONF}"

  /usr/sbin/privoxy --pidfile /opt/privoxy/pidfile ${PROXY_CONF}
  sleep 1 # Give it one sec to start up, or at least create the pidfile

  if [[ -f /opt/privoxy/pidfile ]]; then
    privoxy_pid=$(cat /opt/privoxy/pidfile)
    echo "Privoxy: Running as PID $privoxy_pid"
  else
    echo "Privoxy: ERROR. Did not start correctly, outputting logs"
    echo
    cat /var/log/privoxy/logfile
    echo
  fi

fi
