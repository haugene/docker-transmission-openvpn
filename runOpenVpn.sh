#!/bin/sh

if [ ! -z "$OPEN_VPN_CONFIG" ]
then
	if [ -f /etc/openvpn/"${OPEN_VPN_CONFIG}".ovpn ]
  	then
		echo "Starting OpenVPN using config ${OPEN_VPN_CONFIG}.ovpn"
		OPEN_VPN_CONFIG=/etc/openvpn/${OPEN_VPN_CONFIG}.ovpn
	else
		echo "Supplied config ${OPEN_VPN_CONFIG}.ovpn could not be found."
		echo "Using default OpenVPN gateway: Netherlands"
		OPEN_VPN_CONFIG=/etc/openvpn/Netherlands.ovpn
	fi
else
	echo "No VPN configuration provided. Using default: Netherlands"
	OPEN_VPN_CONFIG=/etc/openvpn/Netherlands.ovpn
fi

# override resolv.conf
if [ "$RESOLV_OVERRIDE" != "**None**" ];
then
  echo "Overriding resolv.conf..."
  printf "$RESOLV_OVERRIDE" > /etc/resolv.conf
fi

# add PIA user/pass
if [ "${PIA_USERNAME}" = "**None**" ] || [ "${PIA_PASSWORD}" = "**None**" ] ; then
 echo "PIA credentials not set. Exiting."
 exit 1
else
  echo "Setting PIA credentials..."
  mkdir -p /config
  echo $PIA_USERNAME > /config/pia-credentials.txt
  echo $PIA_PASSWORD >> /config/pia-credentials.txt
fi

dockerize \
  -template /etc/transmission-daemon/settings.json:/etc/transmission-daemon/settings.json \
  true

exec openvpn --config "$OPEN_VPN_CONFIG"
