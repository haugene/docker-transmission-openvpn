#!/bin/sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# If transmission-pre-start.sh exists, run it
if [ -x /scripts/transmission-pre-start.sh ]
then
   echo "Executing /scripts/transmission-pre-start.sh"
   /scripts/transmission-pre-start.sh
   echo "/scripts/transmission-pre-start.sh returned $?"
fi

# This script will be called with tun/tap device name as parameter 1, and local IP as parameter 4
# See https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html (--up cmd)
echo "Up script executed with $*"
if [ "$4" = "" ]; then
   echo "ERROR, unable to obtain tunnel address"
   echo "killing $PPID"
   kill -9 $PPID
   exit 1
fi
echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $1 : $4"
export TRANSMISSION_BIND_ADDRESS_IPV4=$4

if [ "combustion" = "$TRANSMISSION_WEB_UI" ]; then
  echo "Using Combustion UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/combustion-release
fi

if [ "kettu" = "$TRANSMISSION_WEB_UI" ]; then
  echo "Using Kettu UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/kettu
fi

echo "Generating transmission settings.json from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
dockerize -template /etc/transmission/settings.tmpl:${TRANSMISSION_HOME}/settings.json

if [ ! -e "/dev/random" ]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

. /etc/transmission/userSetup.sh

echo "STARTING TRANSMISSION"
exec sudo -E -u ${RUN_AS} /usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${TRANSMISSION_HOME}/transmission.log &

if [ "$OPENVPN_PROVIDER" = "PIA" ]
then
    echo "CONFIGURING PORT FORWARDING"
    exec /etc/transmission/updatePort.sh &
else
    echo "NO PORT UPDATER FOR THIS PROVIDER"
fi

# If transmission-post-start.sh exists, run it
if [ -x /scripts/transmission-post-start.sh ]
then
   echo "Executing /scripts/transmission-post-start.sh"
   /scripts/transmission-post-start.sh
   echo "/scripts/transmission-post-start.sh returned $?"
fi

echo "Transmission startup script complete."
