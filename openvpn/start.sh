#!/bin/bash

##
# Get some initial setup out of the way.
##

[[ "${DEBUG}" == "true" ]] && set -x

# If openvpn-pre-start.sh exists, run it
if [[ -x /scripts/openvpn-pre-start.sh ]]; then
  echo "Executing /scripts/openvpn-pre-start.sh"
  /scripts/openvpn-pre-start.sh "$@"
  echo "/scripts/openvpn-pre-start.sh returned $?"
fi

# If create_tun_device is set, create /dev/net/tun
if [[ "${CREATE_TUN_DEVICE,,}" == "true" ]]; then
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 0666 /dev/net/tun
fi

##
# Configure OpenVPN.
# This basically means to figure out the config file to use as well as username/password
##

# If no OPENVPN_PROVIDER is given, we default to "custom" provider.
VPN_PROVIDER="${OPENVPN_PROVIDER:-custom}"
VPN_PROVIDER="${VPN_PROVIDER,,}" # to lowercase
VPN_PROVIDER_HOME="/etc/openvpn/${VPN_PROVIDER}"
mkdir -p "$VPN_PROVIDER_HOME"

# Make sure that we have enough information to start OpenVPN
if [[ -z $OPENVPN_CONFIG_URL ]] && [[ "${OPENVPN_PROVIDER}" == "**None**" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
  echo "ERROR: Cannot determine where to find your OpenVPN config. Both OPENVPN_CONFIG_URL and OPENVPN_PROVIDER is unset."
  echo "You have to either provide a URL to the config you want to use, or set a configured provider that will download one for you."
  echo "Exiting..." && exit 1
fi
echo "Using OpenVPN provider: ${VPN_PROVIDER^^}"

if [[ -n $OPENVPN_CONFIG_URL ]]; then
  echo "Found URL to OpenVPN config, will download it."
  CHOSEN_OPENVPN_CONFIG=$VPN_PROVIDER_HOME/downloaded_config.ovpn
  curl -o "$CHOSEN_OPENVPN_CONFIG" -sSL "$OPENVPN_CONFIG_URL"
  # shellcheck source=/dev/null
  . /etc/openvpn/modify-openvpn-config.sh
elif [[ -x $VPN_PROVIDER_HOME/configure-openvpn.sh ]]; then
  echo "Provider $OPENVPN_PROVIDER has a custom startup script, executing it"
  # shellcheck source=/dev/null
  . "$VPN_PROVIDER_HOME"/configure-openvpn.sh
fi

if [[ -z ${CHOSEN_OPENVPN_CONFIG} ]]; then
  # We still don't have a config. The user might have set a config in OPENVPN_CONFIG.
  if [[ -n "${OPENVPN_CONFIG-}" ]]; then
    readarray -t OPENVPN_CONFIG_ARRAY <<< "${OPENVPN_CONFIG//,/$'\n'}"

    ## Trim leading and trailing spaces from all entries. Inefficient as all heck, but works like a champ.
    for i in "${!OPENVPN_CONFIG_ARRAY[@]}"; do
      OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]#"${OPENVPN_CONFIG_ARRAY[${i}]%%[![:space:]]*}"}"
      OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]%"${OPENVPN_CONFIG_ARRAY[${i}]##*[![:space:]]}"}"
    done

    # If there were multiple configs (comma separated), select one of them
    if (( ${#OPENVPN_CONFIG_ARRAY[@]} > 1 )); then
      OPENVPN_CONFIG_RANDOM=$((RANDOM%${#OPENVPN_CONFIG_ARRAY[@]}))
      echo "${#OPENVPN_CONFIG_ARRAY[@]} servers found in OPENVPN_CONFIG, ${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]} chosen randomly"
      OPENVPN_CONFIG="${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]}"
    fi

    # Check that the chosen config exists.
    if [[ -f "${VPN_PROVIDER_HOME}/${OPENVPN_CONFIG}.ovpn" ]]; then
      echo "Starting OpenVPN using config ${OPENVPN_CONFIG}.ovpn"
      CHOSEN_OPENVPN_CONFIG="${VPN_PROVIDER_HOME}/${OPENVPN_CONFIG}.ovpn"
    else
      echo "Supplied config ${OPENVPN_CONFIG}.ovpn could not be found."
      exit 1 # No longer fall back to default. The user chose a specific config - we should use it or fail.
    fi
  else
    echo "No VPN configuration provided. Using default."
    CHOSEN_OPENVPN_CONFIG="${VPN_PROVIDER_HOME}/default.ovpn"
  fi
fi

# add OpenVPN user/pass
if [[ "${OPENVPN_USERNAME}" == "**None**" ]] || [[ "${OPENVPN_PASSWORD}" == "**None**" ]] ; then
  if [[ ! -f /config/openvpn-credentials.txt ]] ; then
    echo "OpenVPN credentials not set. Exiting."
    exit 1
  fi
  echo "Found existing OPENVPN credentials at /config/openvpn-credentials.txt"
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
python3 /etc/openvpn/persistEnvironment.py /etc/transmission/environment-variables.sh

TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/tunnelUp.sh --down /etc/openvpn/tunnelDown.sh"

## If we use UFW or the LOCAL_NETWORK we need to grab network config info
if [[ "${ENABLE_UFW,,}" == "true" ]] || [[ -n "${LOCAL_NETWORK-}" ]]; then
  eval $(/sbin/ip route list match 0.0.0.0 | awk '{if($5!="tun0"){print "GW="$3"\nINT="$5; exit}}')
  ## IF we use UFW_ALLOW_GW_NET along with ENABLE_UFW we need to know what our netmask CIDR is
  if [[ "${ENABLE_UFW,,}" == "true" ]] && [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
    eval $(/sbin/ip route list dev ${INT} | awk '{if($5=="link"){print "GW_CIDR="$1; exit}}')
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
      /sbin/ip route add "${localNet}" via "${GW}" dev "${INT}"
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

# shellcheck disable=SC2086
exec openvpn ${TRANSMISSION_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${CHOSEN_OPENVPN_CONFIG}"