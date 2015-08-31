#!/bin/sh

if [ "$OPENVPN_PROVIDER" = "BTGUARD" ]; then
	vpn_provider="btguard"
elif [ "$OPENVPN_PROVIDER" = "PIA" ]; then
	vpn_provider="pia"
elif [ "$OPENVPN_PROVIDER" = "TIGER" ]; then
	vpn_provider="tiger"
elif [ "$OPENVPN_PROVIDER" = "FROOT" ]; then
	vpn_provider="froot"
else
	echo "Could not find OpenVPN provider: $OPENVPN_PROVIDER"
	echo "Please check your settings."
	exit 1
fi

echo "Using OpenVPN provider: $OPENVPN_PROVIDER"

if [ ! -z "$OPENVPN_CONFIG" ]
then
	if [ -f /etc/openvpn/$vpn_provider/"${OPENVPN_CONFIG}".ovpn ]
  	then
		echo "Starting OpenVPN using config ${OPENVPN_CONFIG}.ovpn"
		OPENVPN_CONFIG=/etc/openvpn/$vpn_provider/${OPENVPN_CONFIG}.ovpn
	else
		echo "Supplied config ${OPENVPN_CONFIG}.ovpn could not be found."
		echo "Using default OpenVPN gateway for provider ${vpn_provider}"
		OPENVPN_CONFIG=/etc/openvpn/$vpn_provider/default.ovpn
	fi
else
	echo "No VPN configuration provided. Using default."
	OPENVPN_CONFIG=/etc/openvpn/$vpn_provider/default.ovpn
fi

# override resolv.conf
if [ "$RESOLV_OVERRIDE" != "**None**" ];
then
  echo "Overriding resolv.conf..."
  printf "$RESOLV_OVERRIDE" > /etc/resolv.conf
fi

# add OpenVPN user/pass
if [ "${OPENVPN_USERNAME}" = "**None**" ] || [ "${OPENVPN_PASSWORD}" = "**None**" ] ; then
 echo "PIA credentials not set. Exiting."
 exit 1
else
  echo "Setting OPENVPN credentials..."
  mkdir -p /config
  echo $OPENVPN_USERNAME > /config/openvpn-credentials.txt
  echo $OPENVPN_PASSWORD >> /config/openvpn-credentials.txt
  chmod 600 /config/openvpn-credentials.txt
fi

# add transmission credentials from env vars
echo $TRANSMISSION_RPC_USERNAME > /config/transmission-credentials.txt
echo $TRANSMISSION_RPC_PASSWORD >> /config/transmission-credentials.txt

# Persist transmission settings for use by transmission-daemon
dockerize -template /etc/transmission/environment-variables.tmpl:/etc/transmission/environment-variables.sh /bin/true

exec openvpn --config "$OPENVPN_CONFIG"
