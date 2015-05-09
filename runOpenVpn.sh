#!/bin/sh

if [ "$RESOLV_OVERRIDE" != "**None**" ];
then
  echo "Overriding resolv.conf..."
  printf "$RESOLV_OVERRIDE" > /etc/resolv.conf
fi

if [ "$PIA_USERNAME" != "**None**" ];
then
  echo "Setting PIA credentials..."
  echo $PIA_USERNAME > /pia-credentials.txt
  echo $PIA_PASSWORD >> /pia-credentials.txt
else
  echo "Not setting PIA credentials."
fi

dockerize \
  -template /etc/openvpn/config.ovpn:/etc/openvpn/config.ovpn \
  -template /etc/transmission-daemon/settings.json:/etc/transmission-daemon/settings.json \
  true

exec openvpn --config /etc/openvpn/config.ovpn
