#!/bin/bash

echo
echo "Hello! As you're probably aware this is an early alpha version of WireGuard support."
echo "Things will change and things will break. It might not work as intended, and all that..."
echo "You have been warned :)"
echo

if [[ -n "$REVISION" ]]; then
  echo "Starting container with revision: $REVISION"
fi

##
# Decide if we start with OpenVPN or wireguard
##
if [[ $VPN_PROTOCOL == "wireguard" ]]; then
  /usr/bin/python3 /opt/transmission-vpn/main.py || exit 1
  export TRANSMISSION_RUN_FOREGROUND="--foreground"
  python3 /etc/openvpn/persistEnvironment.py /etc/transmission/environment-variables.sh || exit 1
  /etc/transmission/start.sh 0 0 0 "$(grep Address < /etc/wireguard/wg0.conf | cut -d= -f2 | xargs)"

else
  # shellcheck source=/dev/null
  . /etc/openvpn/start.sh
fi
