#!/bin/sh

if [ "$OPENVPN_PROVIDER" = "BTGUARD" ]
then
	echo "VPN PROVIDER: BTGUARD"
	vpn_provider="btguard"
else
	echo "VPN PROVIDER: PIA"
	vpn_provider="pia"
fi

if [ ! -z "$OPEN_VPN_CONFIG" ]
then
	if [ -f /etc/openvpn/$vpn_provider/"${OPEN_VPN_CONFIG}".ovpn ]
  	then
		echo "Starting OpenVPN using config ${OPEN_VPN_CONFIG}.ovpn"
		OPEN_VPN_CONFIG=/etc/openvpn/$vpn_provider/${OPEN_VPN_CONFIG}.ovpn
	else
		echo "Supplied config ${OPEN_VPN_CONFIG}.ovpn could not be found."
		echo "Using default OpenVPN gateway for provider ${vpn_provider}"
		OPEN_VPN_CONFIG=/etc/openvpn/$vpn_provider/default.ovpn
	fi
else
	echo "No VPN configuration provided. Using default."
	OPEN_VPN_CONFIG=/etc/openvpn/$vpn_provider/default.ovpn
fi

# override resolv.conf
if [ "$RESOLV_OVERRIDE" != "**None**" ];
then
  echo "Overriding resolv.conf..."
  printf "$RESOLV_OVERRIDE" > /etc/resolv.conf
fi

# add PIA user/pass
if [ "${OPENVPN_USERNAME}" = "**None**" ] || [ "${OPENVPN_PASSWORD}" = "**None**" ] ; then
 echo "PIA credentials not set. Exiting."
 exit 1
else
  echo "Setting OPENVPN credentials..."
  mkdir -p /config
  echo $OPENVPN_USERNAME > /config/openvpn-credentials.txt
  echo $OPENVPN_PASSWORD >> /config/openvpn-credentials.txt
fi

# add transmission credentials from env vars
echo $TRANSMISSION_RPC_USERNAME > /config/transmission-credentials.txt
echo $TRANSMISSION_RPC_PASSWORD >> /config/transmission-credentials.txt

# Persist transmission settings for use by transmission-daemon
dockerize -template /etc/transmission-daemon/environment-variables.tmpl:/etc/transmission-daemon/environment-variables.sh /bin/true

exec openvpn --config "$OPEN_VPN_CONFIG"
