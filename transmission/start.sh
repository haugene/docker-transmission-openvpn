#!/bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# This script will be called with tun/tap device name as parameter 1, and local IP as parameter 4
# See https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html (--up cmd)
echo "Up script executed with $*"
if [[ "$4" = "" ]]; then
   echo "ERROR, unable to obtain tunnel address"
   echo "killing $PPID"
   kill -9 $PPID
   exit 1
fi

# If transmission-pre-start.sh exists, run it
if [[ -x /scripts/transmission-pre-start.sh ]]
then
   echo "Executing /scripts/transmission-pre-start.sh"
   /scripts/transmission-pre-start.sh "$@"
   echo "/scripts/transmission-pre-start.sh returned $?"
fi

echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $1 : $4"
export TRANSMISSION_BIND_ADDRESS_IPV4=$4
# Also update the persisted settings in case it is already set. First remove any old value, then add new.
sed -i '/TRANSMISSION_BIND_ADDRESS_IPV4/d' /etc/transmission/environment-variables.sh
echo "export TRANSMISSION_BIND_ADDRESS_IPV4=$4" >> /etc/transmission/environment-variables.sh

if [[ "combustion" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Combustion UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/combustion-release
fi

if [[ "kettu" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Kettu UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/kettu
fi

if [[ "transmission-web-control" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Transmission Web Control  UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/transmission-web-control
fi

echo "Updating Transmission settings.json with values from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
python3 /etc/transmission/updateSettings.py /etc/transmission/default-settings.json ${TRANSMISSION_HOME}/settings.json

echo "sed'ing True to true"
sed -i 's/True/true/g' ${TRANSMISSION_HOME}/settings.json

if [[ ! -e "/dev/random" ]]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

. /etc/transmission/userSetup.sh

if [[ "true" = "$DROP_DEFAULT_ROUTE" ]]; then
  echo "DROPPING DEFAULT ROUTE"
  ip r del default || exit 1
fi

if [[ "true" = "$LOG_TO_STDOUT" ]]; then
  LOGFILE=/dev/stdout
else
  LOGFILE=${TRANSMISSION_HOME}/transmission.log
fi

if [ ! -z ${TZ} ]; then
  cp -f "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone
fi

echo "STARTING TRANSMISSION"
exec su --preserve-environment ${RUN_AS} -s /bin/bash -c "/usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile $LOGFILE" &

# Configure port forwarding if applicable
if [[ -x /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh && -z $DISABLE_PORT_UPDATER ]]; then
    echo "Provider ${OPENVPN_PROVIDER^^} has a script for automatic port forwarding. Will run it now."
    echo "If you want to disable this, set environment variable DISABLE_PORT_UPDATER=yes"
    exec /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh &
fi

# If transmission-post-start.sh exists, run it
if [[ -x /scripts/transmission-post-start.sh ]]
then
   echo "Executing /scripts/transmission-post-start.sh"
   /scripts/transmission-post-start.sh "$@"
   echo "/scripts/transmission-post-start.sh returned $?"
fi

echo "Transmission startup script complete."
