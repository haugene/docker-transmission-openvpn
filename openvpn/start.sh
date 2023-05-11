#!/bin/bash

##
# Get some initial setup out of the way.
##

set -e

source /etc/openvpn/utils.sh

if [[ -n "$REVISION" ]]; then
  echo "Starting container with revision: $REVISION"
fi

#
# We have moved the default location of TRANSMISSION_HOME. Should be fully backwards compatible, but display an early warning.
# Will probably keep the compatibility for a long time but should nudge users to update their setup.
#
echo "TRANSMISSION_HOME is currently set to: ${TRANSMISSION_HOME}"
if [[ "${TRANSMISSION_HOME%/*}" != "/config" ]]; then
        echo "WARNING: TRANSMISSION_HOME is not set to the default /config/transmission-home, this is not recommended."
        echo "TRANSMISSION_HOME should be set to /config/transmission-home OR another custom directory on /config/<directory>"
        echo "If you would like to migrate your existing TRANSMISSION_HOME, please stop the container, add volume /config and move the transmission-home directory there."
fi
#Old default transmission-home exists, use as fallback
if [ -d "/data/transmission-home" ]; then
    TRANSMISSION_HOME="/data/transmission-home"
    echo "WARNING: Deprecated. Found old default transmission-home folder at ${TRANSMISSION_HOME}, setting this as TRANSMISSION_HOME. This might break in future versions."
    echo "We will fallback to this directory as long as the folder exists. Please consider moving it to /config/transmission-home"
fi

# If openvpn-pre-start.sh exists, run it
if [[ -x /scripts/openvpn-pre-start.sh ]]; then
  echo "Executing /scripts/openvpn-pre-start.sh"
  /scripts/openvpn-pre-start.sh "$@"
  echo "/scripts/openvpn-pre-start.sh returned $?"
fi

# Allow for overriding the DNS used directly in the /etc/resolv.conf
if compgen -e | grep -q "OVERRIDE_DNS"; then
    echo "One or more OVERRIDE_DNS addresses found. Will use them to overwrite /etc/resolv.conf"
    echo "" > /etc/resolv.conf
    for var in $(compgen -e | grep "OVERRIDE_DNS"); do
        echo "nameserver $(printenv "$var")" >> /etc/resolv.conf
    done
fi

# Test DNS resolution
if ! nslookup ${HEALTH_CHECK_HOST:-"google.com"} 1>/dev/null 2>&1; then
    echo "WARNING: initial DNS resolution test failed"
fi

# If create_tun_device is set, create /dev/net/tun
if [[ "${CREATE_TUN_DEVICE,,}" == "true" ]] ; then
  echo "Creating TUN device /dev/net/tun"
  rm -f /dev/net/tun
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
export VPN_PROVIDER="${VPN_PROVIDER,,}" # to lowercase
export VPN_PROVIDER_HOME="/etc/openvpn/${VPN_PROVIDER}"
mkdir -p "$VPN_PROVIDER_HOME"

# Make sure that we have enough information to start OpenVPN
if [[ -z $OPENVPN_CONFIG_URL ]] && [[ "${OPENVPN_PROVIDER}" == "**None**" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
  echo "ERROR: Cannot determine where to find your OpenVPN config. Both OPENVPN_CONFIG_URL and OPENVPN_PROVIDER is unset."
  echo "You have to either provide a URL to the config you want to use, or set a configured provider that will download one for you."
  echo "Exiting..." && exit 1
fi
echo "Using OpenVPN provider: ${VPN_PROVIDER^^}"
if [[ "${VPN_PROVIDER}" == "custom" ]]; then
  if [[ -f $VPN_PROVIDER_HOME/default.ovpn ]]; then
    CHOSEN_OPENVPN_CONFIG=$VPN_PROVIDER_HOME/default.ovpn
  fi
elif [[ -n $OPENVPN_CONFIG_URL ]]; then
  echo "Found URL to single OpenVPN config, will download and use it."
  CHOSEN_OPENVPN_CONFIG=$VPN_PROVIDER_HOME/downloaded_config.ovpn
  curl -o "$CHOSEN_OPENVPN_CONFIG" -sSL "$OPENVPN_CONFIG_URL"
fi

if [[ -z ${CHOSEN_OPENVPN_CONFIG} ]]; then

  # Support pulling configs from external config sources
  VPN_CONFIG_SOURCE="${VPN_CONFIG_SOURCE:-auto}"
  VPN_CONFIG_SOURCE="${VPN_CONFIG_SOURCE,,}" # to lowercase

  echo "Running with VPN_CONFIG_SOURCE ${VPN_CONFIG_SOURCE}"

  if [[ "${VPN_CONFIG_SOURCE}" == "auto" ]]; then
    if [[ -f $VPN_PROVIDER_HOME/configure-openvpn.sh ]]; then
      echo "Provider ${VPN_PROVIDER^^} has a bundled setup script. Defaulting to internal config"
      VPN_CONFIG_SOURCE=internal
    elif [[ "${VPN_PROVIDER}" == "custom" ]]; then
      echo "CUSTOM provider specified but not using default.ovpn, will try to find a valid config mounted to $VPN_PROVIDER_HOME"
      VPN_CONFIG_SOURCE=custom
    else
      echo "No bundled config script found for ${VPN_PROVIDER^^}. Defaulting to external config"
      VPN_CONFIG_SOURCE=external
    fi
  fi

  if [[ "${VPN_CONFIG_SOURCE}" == "external" ]] && [[ "${VPN_PROVIDER}" != "custom" ]]; then
    # shellcheck source=openvpn/fetch-external-configs.sh
    ./etc/openvpn/fetch-external-configs.sh
  fi

  if [[ -f $VPN_PROVIDER_HOME/configure-openvpn.sh ]]; then
    echo "Executing setup script for $OPENVPN_PROVIDER"
    # Preserve $PWD in case it changes when sourcing the script
    pushd -n "$PWD" > /dev/null
    # shellcheck source=/dev/null
    . "$VPN_PROVIDER_HOME"/configure-openvpn.sh
    # Restore previous PWD
    popd > /dev/null
  fi
fi

if [[ -z ${CHOSEN_OPENVPN_CONFIG:-""} ]]; then
  # We still don't have a config. The user might have set a config in OPENVPN_CONFIG.
  if [[ -n "${OPENVPN_CONFIG-}" ]]; then
    # Read from file.
    if [ -e /data/openvpn/OPENVPN_CONFIG ]; then
      OPENVPN_CONFIG=$(cat /data/openvpn/OPENVPN_CONFIG)
    fi

    readarray -t OPENVPN_CONFIG_ARRAY <<< "${OPENVPN_CONFIG//,/$'\n'}"

    ## Trim leading and trailing spaces from all entries. Inefficient as all heck, but works like a champ.
    for i in "${!OPENVPN_CONFIG_ARRAY[@]}"; do
      OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]#"${OPENVPN_CONFIG_ARRAY[${i}]%%[![:space:]]*}"}"
      OPENVPN_CONFIG_ARRAY[${i}]="${OPENVPN_CONFIG_ARRAY[${i}]%"${OPENVPN_CONFIG_ARRAY[${i}]##*[![:space:]]}"}"
    done

    # If there were multiple configs (comma separated), select one of them.
    if (( ${#OPENVPN_CONFIG_ARRAY[@]} > 1 )); then
      if [[ ${OPENVPN_CONFIG_SEQUENTIAL:-false} == "false" ]]; then
        # Select randomly.
        OPENVPN_CONFIG_RANDOM=$((RANDOM%${#OPENVPN_CONFIG_ARRAY[@]}))
        echo "${#OPENVPN_CONFIG_ARRAY[@]} servers found in OPENVPN_CONFIG, ${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]} chosen randomly"
        OPENVPN_CONFIG="${OPENVPN_CONFIG_ARRAY[${OPENVPN_CONFIG_RANDOM}]}"
      else
        # Select sequentially.
        echo "${#OPENVPN_CONFIG_ARRAY[@]} servers found in OPENVPN_CONFIG, ${OPENVPN_CONFIG_ARRAY[0]} chosen sequentially"
        OPENVPN_CONFIG="${OPENVPN_CONFIG_ARRAY[0]}"

        # Reorder and save to file.
        OPENVPN_CONFIG_ARRAY=("${OPENVPN_CONFIG_ARRAY[@]:1}" "${OPENVPN_CONFIG_ARRAY[@]::1}")
        mkdir -p /data/openvpn/
        printf "%s," "${OPENVPN_CONFIG_ARRAY[@]}" | sed "s/,$//" > /data/openvpn/OPENVPN_CONFIG
      fi
    fi

    # Check that the chosen config exists.
    if [[ -f "${VPN_PROVIDER_HOME}/${OPENVPN_CONFIG}.ovpn" ]]; then
      echo "Starting OpenVPN using config ${OPENVPN_CONFIG}.ovpn"
      CHOSEN_OPENVPN_CONFIG="${VPN_PROVIDER_HOME}/${OPENVPN_CONFIG}.ovpn"
    else
      echo "Supplied config ${OPENVPN_CONFIG}.ovpn could not be found."
      echo "Your options for this provider are:"
      ls "${VPN_PROVIDER_HOME}" | grep .ovpn
      echo "NB: Remember to not specify .ovpn as part of the config name."
      exit 1 # No longer fall back to default. The user chose a specific config - we should use it or fail.
    fi
  else
    echo "No VPN configuration provided. Using default."
    CHOSEN_OPENVPN_CONFIG="${VPN_PROVIDER_HOME}/default.ovpn"
  fi
fi

# log message and fail if attempting to mount config directly
if mountpoint -q "$CHOSEN_OPENVPN_CONFIG"; then
  fatal_error "You're mounting a openvpn config directly, dont't do this it causes issues (see #2274). Mount the directory where the config is instead."
fi

MODIFY_CHOSEN_CONFIG="${MODIFY_CHOSEN_CONFIG:-true}"
# The config file we're supposed to use is chosen, modify it to fit this container setup
if [[ "${MODIFY_CHOSEN_CONFIG,,}" == "true" ]]; then
  # shellcheck source=openvpn/modify-openvpn-config.sh
  /etc/openvpn/modify-openvpn-config.sh "$CHOSEN_OPENVPN_CONFIG"
fi

# If openvpn-post-config.sh exists, run it
if [[ -x /scripts/openvpn-post-config.sh ]]; then
  echo "Executing /scripts/openvpn-post-config.sh"
  /scripts/openvpn-post-config.sh "$CHOSEN_OPENVPN_CONFIG"
  echo "/scripts/openvpn-post-config.sh returned $?"
fi

mkdir -p /config
#Handle secrets if found
if [[ -f /run/secrets/openvpn_creds ]]; then
  #write creds if no file or contents are not the same.
  if [[ ! -f /config/openvpn-credentials.txt ]] || [[ "$(cat /run/secrets/openvpn_creds)" != "$(cat /config/openvpn-credentials.txt)" ]]; then
    echo "Setting OpenVPN credentials..."
    cp /run/secrets/openvpn_creds /config/openvpn-credentials.txt
  fi
else
  # add OpenVPN user/pass
  if [[ "${OPENVPN_USERNAME}" == "**None**" ]] || [[ "${OPENVPN_PASSWORD}" == "**None**" ]]; then
    if [[ ! -f /config/openvpn-credentials.txt ]]; then
      echo "OpenVPN credentials not set. Exiting."
      exit 1
    fi
    echo "Found existing OPENVPN credentials at /config/openvpn-credentials.txt"
  else
    echo "Setting OpenVPN credentials..."
    echo -e "${OPENVPN_USERNAME}\n${OPENVPN_PASSWORD}" > /config/openvpn-credentials.txt
    chmod 600 /config/openvpn-credentials.txt
  fi
fi

if [[ -f /run/secrets/rpc_creds ]]; then
  export TRANSMISSION_RPC_USERNAME=$(head -1 /run/secrets/rpc_creds)
  export TRANSMISSION_RPC_PASSWORD=$(tail -1 /run/secrets/rpc_creds)
fi
echo "${TRANSMISSION_RPC_USERNAME}" > /config/transmission-credentials.txt
echo "${TRANSMISSION_RPC_PASSWORD}" >> /config/transmission-credentials.txt

# Persist transmission settings for use by transmission-daemon
export CONFIG="${CHOSEN_OPENVPN_CONFIG}"
python3 /etc/openvpn/persistEnvironment.py /etc/transmission/environment-variables.sh

TRANSMISSION_CONTROL_OPTS="--script-security 2 --route-up /etc/openvpn/tunnelUp.sh --route-pre-down /etc/openvpn/tunnelDown.sh"

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
  portNum=${1}
  if [[ "${ENABLE_UFW,,}" == "true" ]] && [[ -n "${portNum-}" ]]; then
    echo "allowing ${portNum} through the firewall"
    if [[ $portNum == *":"* ]];
    then
      ufw allow ${portNum}/tcp
      ufw allow ${portNum}/udp
    else
      ufw allow ${portNum}
    fi
  fi
}

## Open port to specific address.
function ufwAllowPortLong {
  portNum=${1}
  sourceAddress=${2}

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


# Ignore unset variables from here and out
# The UFW stuff should be revisited at some point...
set +u

  if [[ "${TRANSMISSION_PEER_PORT_RANDOM_ON_START,,}" == "true" ]]; then
    PEER_PORT="${TRANSMISSION_PEER_PORT_RANDOM_LOW}:${TRANSMISSION_PEER_PORT_RANDOM_HIGH}"
  else
    PEER_PORT="${TRANSMISSION_PEER_PORT}"
  fi

  ufwAllowPort ${PEER_PORT}

  if [[ "${WEBPROXY_ENABLED,,}" == "true" ]]; then
    ufwAllowPort ${WEBPROXY_PORT}
  fi
  if [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
    ufwAllowPortLong ${TRANSMISSION_RPC_PORT} ${GW_CIDR}
  else
    ufwAllowPortLong ${TRANSMISSION_RPC_PORT} ${GW}
  fi

  if [[ -n "${UFW_EXTRA_PORTS-}"  ]]; then
    for port in ${UFW_EXTRA_PORTS//,/ }; do
      if [[ "${UFW_ALLOW_GW_NET,,}" == "true" ]]; then
        ufwAllowPortLong ${port} ${GW_CIDR}
      else
        ufwAllowPortLong ${port} ${GW}
      fi
    done
  fi
fi

if [[ -n "${LOCAL_NETWORK-}" ]]; then
  if [[ -n "${GW-}" ]] && [[ -n "${INT-}" ]]; then
    for localNet in ${LOCAL_NETWORK//,/ }; do
      echo "adding route to local network ${localNet} via ${GW} dev ${INT}"
      # Using `ip route replace` so that the command does not fail with
      # `RTNETLINK answers: File exists` when the route already exists 
      /sbin/ip route replace "${localNet}" via "${GW}" dev "${INT}"
      if [[ "${ENABLE_UFW,,}" == "true" ]]; then
        ufwAllowPortLong ${TRANSMISSION_RPC_PORT} ${localNet}
        if [[ -n "${UFW_EXTRA_PORTS-}" ]]; then
          for port in ${UFW_EXTRA_PORTS//,/ }; do
            ufwAllowPortLong ${port} ${localNet}
          done
        fi
      fi
    done
  fi
fi

# If routes-post-start.sh exists, run it
if [[ -x /scripts/routes-post-start.sh ]]; then
  echo "Executing /scripts/routes-post-start.sh"
  /scripts/routes-post-start.sh "$@"
  echo "/scripts/routes-post-start.sh returned $?"
fi

if [[ ${SELFHEAL:-false} != "false" ]]; then
  /etc/scripts/selfheal.sh &
fi

# shellcheck disable=SC2086
exec openvpn ${TRANSMISSION_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${CHOSEN_OPENVPN_CONFIG}"
