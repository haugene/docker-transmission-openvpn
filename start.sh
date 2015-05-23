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

# add transmission credentials from env vars
echo $TRANSMISSION_RPC_USERNAME > /config/transmission-credentials.txt
echo $TRANSMISSION_RPC_PASSWORD >> /config/transmission-credentials.txt

# setup transmission configuration
if [ ! -z ${KEEP_TRANSMISSION_STATE} ]
then
  mkdir -p /data/transmission-data/
  dockerize -template /etc/transmission-daemon/settings.tmpl:/data/transmission-data/settings.json /bin/true
else
  dockerize -template /etc/transmission-daemon/settings.tmpl:/etc/transmission-daemon/settings.json /bin/true
fi

exec openvpn --config "$OPEN_VPN_CONFIG"
