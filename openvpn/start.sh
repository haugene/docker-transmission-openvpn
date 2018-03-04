#!/bin/bash
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
	n=$(echo "$OPENVPN_CONFIG" | wc -w)
	if [ $n -gt 1 ]
	then
        	rnd=$((RANDOM%n+1))
        	srv=$(echo "$OPENVPN_CONFIG" | awk -vrnd=$rnd '{print $rnd}')
        	echo "$n servers found in OPENVPN_CONFIG, $srv chosen randomly"
        	OPENVPN_CONFIG=$srv
	fi

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
  if [ ! -f /config/openvpn-credentials.txt ] ; then
    echo "OpenVPN credentials not set. Exiting."
    exit 1
  fi
  echo "Found existing OPENVPN credentials..."
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
dockerize -template /etc/transmission/environment-variables.tmpl:/etc/transmission/environment-variables.sh

TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/tunnelUp.sh --down /etc/openvpn/tunnelDown.sh"

if [ "true" = "$ENABLE_UFW" ]; then
  # Enable firewall
  echo "enabling firewall"
  sed -i -e s/IPV6=yes/IPV6=no/ /etc/default/ufw
  ufw enable

  if [ "true" = "$TRANSMISSION_PEER_PORT_RANDOM_ON_START" ]; then
    PEER_PORT="$TRANSMISSION_PEER_PORT_RANDOM_LOW:$TRANSMISSION_PEER_PORT_RANDOM_HIGH/tcp"
  else
    PEER_PORT=$TRANSMISSION_PEER_PORT
  fi

  echo "allowing $PEER_PORT through the firewall"
  ufw allow $PEER_PORT

  if [ "true" = "$WEBPROXY_ENABLED" ]; then
    echo "allowing $WEBPROXY_PORT through the firewall"
    ufw allow $WEBPROXY_PORT
  fi

  eval $(/sbin/ip r l m 0.0.0.0 | awk '{if($5!="tun0"){print "GW="$3"\nINT="$5; exit}}')
  echo "allowing access to $TRANSMISSION_RPC_PORT from $GW"
  ufw allow proto tcp from $GW to any port $TRANSMISSION_RPC_PORT
  if [ ! -z "${UFW_EXTRA_PORTS}"  ]; then
    for port in ${UFW_EXTRA_PORTS//,/ }; do
      echo "allowing access to ${port} from $GW"
      ufw allow proto tcp from $GW to any port ${port}
    done
  fi
fi

if [ -n "${LOCAL_NETWORK-}" ]; then
  eval $(/sbin/ip r l m 0.0.0.0 | awk '{if($5!="tun0"){print "GW="$3"\nINT="$5; exit}}')
  if [ -n "${GW-}" -a -n "${INT-}" ]; then
    echo "adding route to local network $LOCAL_NETWORK via $GW dev $INT"
    /sbin/ip r a "$LOCAL_NETWORK" via "$GW" dev "$INT"
    if [ "true" = "$ENABLE_UFW" ]; then
      echo "allowing access to $TRANSMISSION_RPC_PORT from $LOCAL_NETWORK"
      ufw allow proto tcp from $LOCAL_NETWORK to any port $TRANSMISSION_RPC_PORT
      if [ ! -z "${UFW_EXTRA_PORTS}" ]; then
        for port in ${UFW_EXTRA_PORTS//,/ }; do
          echo "allowing access to ${port} from $LOCAL_NETWORK"
          ufw allow proto tcp from $LOCAL_NETWORK to any port ${port}
        done
      fi
    fi
  fi
fi

echo WAN IPv4: $(curl --silent --max-time 2 http://ipv4.plain-text-ip.com)
echo WAN IPv6: $(curl --silent --max-time 2 http://ipv6.plain-text-ip.com)

exec openvpn $TRANSMISSION_CONTROL_OPTS $OPENVPN_OPTS --config "$OPENVPN_CONFIG"
