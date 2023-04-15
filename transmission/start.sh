#!/bin/bash

source /etc/openvpn/utils.sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# This script will be called with OpenVPN environment variables
# See https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/#scripting-and-environmental-variables
echo "Up script executed with device=$dev ifconfig_local=$ifconfig_local"
if [[ "$ifconfig_local" = "" ]]; then
  echo "ERROR, unable to obtain tunnel address"
  echo "killing $PPID"
  kill -9 $PPID
  exit 1
fi

# Re-create `--up` command arguments to maintain compatibility with old user scripts
USER_SCRIPT_ARGS=("$dev" "$tun_mtu" "$link_mtu" "$ifconfig_local" "$ifconfig_remote" "$script_context")

# If transmission-pre-start.sh exists, run it
if [[ -x /scripts/transmission-pre-start.sh ]]; then
  echo "Executing /scripts/transmission-pre-start.sh"
  /scripts/transmission-pre-start.sh "${USER_SCRIPT_ARGS[@]}"
  echo "/scripts/transmission-pre-start.sh returned $?"
fi

echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $dev : $ifconfig_local"
export TRANSMISSION_BIND_ADDRESS_IPV4=$ifconfig_local
# Also update the persisted settings in case it is already set. First remove any old value, then add new.
sed -i '/TRANSMISSION_BIND_ADDRESS_IPV4/d' /etc/transmission/environment-variables.sh
echo "export TRANSMISSION_BIND_ADDRESS_IPV4=$ifconfig_local" >>/etc/transmission/environment-variables.sh

if [[ "combustion" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Combustion UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/combustion-release
fi

if [[ "kettu" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Kettu UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/kettu
fi

if [[ "transmission-web-control" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Transmission Web Control UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/transmission-web-control
fi

if [[ "flood-for-transmission" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Flood for Transmission UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/flood-for-transmission
fi

if [[ "shift" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Shift UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/shift
fi

case ${TRANSMISSION_LOG_LEVEL,,} in
  "trace" | "debug" | "info" | "warn" | "error" | "critical")
    echo "Will exec Transmission with '--log-level=${TRANSMISSION_LOG_LEVEL,,}' argument"
    export TRANSMISSION_LOGGING="--log-level=${TRANSMISSION_LOG_LEVEL,,}"
    ;;
  *)
    export TRANSMISSION_LOGGING=""
    ;;
esac

. /etc/transmission/userSetup.sh

echo "Updating Transmission settings.json with values from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
python3 /etc/transmission/updateSettings.py /etc/transmission/default-settings.json ${TRANSMISSION_HOME}/settings.json || exit 1

echo "sed'ing True to true"
sed -i 's/True/true/g' ${TRANSMISSION_HOME}/settings.json

if [[ ! -e "/dev/random" ]]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

if [[ "true" = "$DROP_DEFAULT_ROUTE" ]]; then
    echo "DROPPING DEFAULT ROUTE"
    # Remove the original default route to avoid leaks.
    /sbin/ip route del default via "${route_net_gateway}" || exit 1
fi

if [[ "true" = "$LOG_TO_STDOUT" ]]; then
  LOGFILE=/dev/stdout
else
  LOGFILE=${TRANSMISSION_HOME}/transmission.log
fi

echo "STARTING TRANSMISSION"

exec su --preserve-environment ${RUN_AS} -s /bin/bash -c "/usr/local/bin/transmission-daemon ${TRANSMISSION_LOGGING} -g ${TRANSMISSION_HOME} --logfile $LOGFILE" &


# Configure port forwarding if applicable
if [[ -x /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh && (-z $DISABLE_PORT_UPDATER || "false" = "$DISABLE_PORT_UPDATER") ]]; then
  echo "Provider ${OPENVPN_PROVIDER^^} has a script for automatic port forwarding. Will run it now."
  echo "If you want to disable this, set environment variable DISABLE_PORT_UPDATER=true"
  exec /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh &
fi

# If transmission-post-start.sh exists, run it
if [[ -x /scripts/transmission-post-start.sh ]]; then
  echo "Executing /scripts/transmission-post-start.sh"
  /scripts/transmission-post-start.sh "${USER_SCRIPT_ARGS[@]}"
  echo "/scripts/transmission-post-start.sh returned $?"
fi

echo "Transmission startup script complete."
