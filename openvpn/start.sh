#!/bin/bash
VPN_PROVIDER="${OPENVPN_PROVIDER,,}"
VPN_PROVIDER_CONFIGS="/etc/openvpn/${VPN_PROVIDER}"
export VPN_PROVIDER_CONFIGS

# If create_tun_device is set, create /dev/net/tun
if [[ "${CREATE_TUN_DEVICE,,}" == "true" ]]; then
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 0666 /dev/net/tun
fi

if [[ "${OPENVPN_PROVIDER}" == "**None**" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
  echo "OpenVPN provider not set. Exiting."
  exit 1
elif [[ ! -d "${VPN_PROVIDER_CONFIGS}" ]]; then
  echo "Could not find OpenVPN provider: ${OPENVPN_PROVIDER}"
  echo "Please check your settings."
  exit 1
fi

echo "Using OpenVPN provider: ${OPENVPN_PROVIDER}"

# If openvpn-pre-start.sh exists, run it
if [ -x /scripts/openvpn-pre-start.sh ]
then
   echo "Executing /scripts/openvpn-pre-start.sh"
   /scripts/openvpn-pre-start.sh "$@"
   echo "/scripts/openvpn-pre-start.sh returned $?"
fi

if [[ "${OPENVPN_PROVIDER^^}" = "NORDVPN" ]]
then
    if [[ -z "$OPENVPN_CONFIG" ]]
    then
        # Update config files
        . ${VPN_PROVIDER_CONFIGS}/updateConfigs.sh
        export OPENVPN_CONFIG=$(${VPN_PROVIDER_CONFIGS}/NordVPN_Server_Selector.sh)
        echo "Setting best server ${OPENVPN_CONFIG}"
    fi
fi

if [[ -n "${OPENVPN_CONFIG-}" ]]; then
  readarray -t OPENVPN_CONFIG_ARRAY <<< "${OPENVPN_CONFIG//,/$'\n'}"
  ## Trim leading and trailing spaces from all entries. Inefficient as all heck, but works like a champ.
  for i in "${!OPENVPN_CONFIG_ARRAY[@]}"; do
    OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]#"${OPENVPN_CONFIG_ARRAY[${i}]%%[![:space:]]*}"}"
    OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]%"${OPENVPN_CONFIG_ARRAY[${i}]##*[![:space:]]}"}"
  done
  if (( ${#OPENVPN_CONFIG_ARRAY[@]} > 1 )); then
    OPENVPN_CONFIG_RANDOM=$((RANDOM%${#OPENVPN_CONFIG_ARRAY[@]}))
    echo "${#OPENVPN_CONFIG_ARRAY[@]} servers found in OPENVPN_CONFIG, ${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]} chosen randomly"
    OPENVPN_CONFIG="${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]}"
  fi

  if [[ -f "${VPN_PROVIDER_CONFIGS}/${OPENVPN_CONFIG}.ovpn" ]]; then
    echo "Starting OpenVPN using config ${OPENVPN_CONFIG}.ovpn"
    OPENVPN_CONFIG="${VPN_PROVIDER_CONFIGS}/${OPENVPN_CONFIG}.ovpn"
  else
    echo "Supplied config ${OPENVPN_CONFIG}.ovpn could not be found."
    echo "Using default OpenVPN gateway for provider ${VPN_PROVIDER}"
    OPENVPN_CONFIG="${VPN_PROVIDER_CONFIGS}/default.ovpn"
  fi
else
  echo "No VPN configuration provided. Using default."
  OPENVPN_CONFIG="${VPN_PROVIDER_CONFIGS}/default.ovpn"
fi

# add OpenVPN user/pass
if [[ "${OPENVPN_USERNAME}" == "**None**" ]] || [[ "${OPENVPN_PASSWORD}" == "**None**" ]] ; then
  if [[ ! -f /config/openvpn-credentials.txt ]] ; then
    echo "OpenVPN credentials not set. Exiting."
    exit 1
  fi
  echo "Found existing OPENVPN credentials..."
else
  echo "Setting OPENVPN credentials..."
  mkdir -p /config
  echo "${OPENVPN_USERNAME}" > /config/openvpn-credentials.txt
  echo "${OPENVPN_PASSWORD}" >> /config/openvpn-credentials.txt
  chmod 600 /config/openvpn-credentials.txt
fi

# add transmission credentials from env vars
echo "${TRANSMISSION_RPC_USERNAME}" > /config/transmission-credentials.txt
echo "${TRANSMISSION_RPC_PASSWORD}" >> /config/transmission-credentials.txt

# Persist transmission settings for use by transmission-daemon
dockerize -template /etc/transmission/environment-variables.tmpl:/etc/transmission/environment-variables.sh

TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/tunnelUp.sh --down /etc/openvpn/tunnelDown.sh"

## If we use UFW or the LOCAL_NETWORK we need to grab network config info
if [[ "${ENABLE_UFW,,}" == "true" ]] || [[ -n "${LOCAL_NETWORK-}" ]]; then
  eval $(/sbin/ip r l m 0.0.0.0 | awk '{if($5!="tun0"){print "GW="$3"\nINT="$5; exit}}')
  ## IF we use UFW_ALLOW_GW_NET along with ENABLE_UFW we need to know what our netmask CIDR is
  if [[ "${ENABLE_UFW,,}" == "true" ]] && [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
    eval $(ip r l dev ${INT} | awk '{if($5=="link"){print "GW_CIDR="$1; exit}}')
  fi
fi

## Open port to any address
function ufwAllowPort {
  typeset -n portNum=${1}
  if [[ "${ENABLE_UFW,,}" == "true" ]] && [[ -n "${portNum-}" ]]; then
    echo "allowing ${portNum} through the firewall"
    ufw allow ${portNum}
  fi
}

## Open port to specific address.
function ufwAllowPortLong {
  typeset -n portNum=${1} sourceAddress=${2}

  if [[ "${ENABLE_UFW,,}" == "true" ]] && [[ -n "${portNum-}" ]] && [[ -n "${sourceAddress-}" ]]; then
    echo "allowing ${sourceAddress} through the firewall to port ${portNum}"
    ufw allow from ${sourceAddress} to any port ${portNum}
  fi
}

if [[ "${ENABLE_UFW,,}" == "true" ]]; then
  if [[ "${UFW_DISABLE_IPTABLES_REJECT,,}" == "true" ]]; then
    # A horrible hack to ufw to prevent it detecting the ability to limit and REJECT traffic
    sed -i 's/return caps/return []/g' /usr/lib/python3/dist-packages/ufw/util.py
    # force a rewrite on the enable below
    echo "Disable and blank firewall"
    ufw disable
    echo "" > /etc/ufw/user.rules
  fi
  # Enable firewall
  echo "enabling firewall"
  sed -i -e s/IPV6=yes/IPV6=no/ /etc/default/ufw
  ufw enable

  if [[ "${TRANSMISSION_PEER_PORT_RANDOM_ON_START,,}" == "true" ]]; then
    PEER_PORT="${TRANSMISSION_PEER_PORT_RANDOM_LOW}:${TRANSMISSION_PEER_PORT_RANDOM_HIGH}"
  else
    PEER_PORT="${TRANSMISSION_PEER_PORT}"
  fi

  ufwAllowPort PEER_PORT

  if [[ "${WEBPROXY_ENABLED,,}" == "true" ]]; then
    ufwAllowPort WEBPROXY_PORT
  fi
  if [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
    ufwAllowPortLong TRANSMISSION_RPC_PORT GW_CIDR
  else
    ufwAllowPortLong TRANSMISSION_RPC_PORT GW
  fi

  if [[ -n "${UFW_EXTRA_PORTS-}"  ]]; then
    for port in ${UFW_EXTRA_PORTS//,/ }; do
      if [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
        ufwAllowPortLong port GW_CIDR
      else
        ufwAllowPortLong port GW
      fi
    done
  fi
fi

if [[ -n "${LOCAL_NETWORK-}" ]]; then
  if [[ -n "${GW-}" ]] && [[ -n "${INT-}" ]]; then
    for localNet in ${LOCAL_NETWORK//,/ }; do
      echo "adding route to local network ${localNet} via ${GW} dev ${INT}"
      /sbin/ip r a "${localNet}" via "${GW}" dev "${INT}"
      if [[ "${ENABLE_UFW,,}" == "true" ]]; then
        ufwAllowPortLong TRANSMISSION_RPC_PORT localNet
        if [[ -n "${UFW_EXTRA_PORTS-}" ]]; then
          for port in ${UFW_EXTRA_PORTS//,/ }; do
            ufwAllowPortLong port localNet
          done
        fi
      fi
    done
  fi
fi

exec openvpn ${TRANSMISSION_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${OPENVPN_CONFIG}"
