#!/bin/sh
vpn_provider="$(echo $OPENVPN_PROVIDER | tr '[A-Z]' '[a-z]')"
vpn_provider_configs="/etc/openvpn/$vpn_provider"
if [ ! -d "$vpn_provider_configs" ]; then
	echo "Could not find OpenVPN provider: $OPENVPN_PROVIDER"
	echo "Please check your settings."
	exit 1
fi

echo "Using OpenVPN provider: $OPENVPN_PROVIDER"

if [ ! -z "$OPENVPN_CONFIG" ]
then
	if [ -f $vpn_provider_configs/"${OPENVPN_CONFIG}".ovpn ]
  	then
		echo "Starting OpenVPN using config ${OPENVPN_CONFIG}.ovpn"
		OPENVPN_CONFIG=$vpn_provider_configs/${OPENVPN_CONFIG}.ovpn
	else
		echo "Supplied config ${OPENVPN_CONFIG}.ovpn could not be found."
		echo "Using default OpenVPN gateway for provider ${vpn_provider}"
		OPENVPN_CONFIG=$vpn_provider_configs/default.ovpn
	fi
else
	echo "No VPN configuration provided. Using default."
	OPENVPN_CONFIG=$vpn_provider_configs/default.ovpn
fi

# add OpenVPN user/pass
if [ "${OPENVPN_USERNAME}" = "**None**" ] || [ "${OPENVPN_PASSWORD}" = "**None**" ] ; then
 echo "OpenVPN credentials not set. Exiting."
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

TRANSMISSION_CONTROL_OPTS="--script-security 2 --up /etc/transmission/start.sh --down /etc/transmission/stop.sh"

if [ -n "${LOCAL_NETWORK-}" ]; then
  eval $(/sbin/ip r l m 0.0.0.0 | awk '{if($5!="tun0"){print "GW="$3"\nINT="$5; exit}}')
  if [ -n "${GW-}" -a -n "${INT-}" ]; then
    echo "adding route to local network $LOCAL_NETWORK via $GW dev $INT"
    /sbin/ip r a "$LOCAL_NETWORK" via "$GW" dev "$INT"
  fi
fi

exec openvpn $TRANSMISSION_CONTROL_OPTS $OPENVPN_OPTS --config "$OPENVPN_CONFIG"
