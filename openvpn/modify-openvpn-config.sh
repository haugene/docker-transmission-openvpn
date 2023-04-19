#!/bin/bash

source /etc/openvpn/utils.sh

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi
CONFIG=$1

echo "Modifying $CONFIG for best behaviour in this container"

# Every config modification have its own environemnt variable that can configure the behaviour.
# Different users, providers or host systems might have specific preferences.
# But we should try to add sensible defaults, a way to disable it, and alternative implementations as needed.

CONFIG_MOD_USERPASS=${CONFIG_MOD_USERPASS:-"1"}
CONFIG_MOD_CA_CERTS=${CONFIG_MOD_CA_CERTS:-"1"}
CONFIG_MOD_PING=${CONFIG_MOD_PING:-"1"}
CONFIG_MOD_RESOLV_RETRY=${CONFIG_MOD_RESOLV_RETRY:-"1"}
CONFIG_MOD_TLS_CERTS=${CONFIG_MOD_TLS_CERTS:-"1"}
CONFIG_MOD_VERBOSITY=${CONFIG_MOD_VERBOSITY:-"3"}
CONFIG_MOD_REMAP_USR1=${CONFIG_MOD_REMAP_USR1:-"1"}
CONFIG_MOD_FAILURE_SCRIPT=${CONFIG_MOD_FAILURE_SCRIPT:-"1"}

## Option 1 - Change the auth-user-pass line to point to credentials file
if [[ $CONFIG_MOD_USERPASS == "1" ]]; then
    echo "Modification: Point auth-user-pass option to the username/password file"
    sed -i "s#auth-user-pass.*#auth-user-pass /config/openvpn-credentials.txt#g" "$CONFIG"
fi

## Option 2 - Change the ca certificate path to point relative to the provider home
if [[ $CONFIG_MOD_CA_CERTS == "1" ]]; then
    echo "Modification: Change ca certificate path"
    config_directory=$(dirname "$CONFIG")

    # Some configs are already adjusted, need to handle both relative and absolute paths, like:
    # ca /etc/openvpn/mullvad/ca.crt
    # ca ca.ipvanish.com.crt
    sed -i -E "s#ca\s+(.*/)*#ca $config_directory/#g" "$CONFIG"
fi

## Option 3 - Update ping options to exit the container, so Docker will restart it
if [[ $CONFIG_MOD_PING == "1" ]]; then
    echo "Modification: Change ping options"
    # Remove any old options
    sed -i "/^inactive.*$/d" "$CONFIG"
    sed -i "/^ping.*$/d" "$CONFIG"

    # Remove keep-alive option - it doesn't work in conjunction with ping option(s) which we're adding later
    sed -i '/^keepalive.*$/d' "$CONFIG"

    # Add new ones
    sed -i "\$q" "$CONFIG" # Ensure config ends with a line feed
    echo "inactive 3600" >> "$CONFIG"
    echo "ping 10" >> "$CONFIG"
    echo "ping-exit 60" >> "$CONFIG"
fi

## Option 4 - Set a sensible default for resolv-retry. The OpenVPN default value
##            is "infinite" and that will cause things to hang on DNS errors
if [[ $CONFIG_MOD_RESOLV_RETRY == "1" ]]; then
    echo "Modification: Update/set resolv-retry to 15 seconds"
    # Remove old setting
    sed -i "/^resolv-retry.*$/d" "$CONFIG"

    # Add new ones
    sed -i "\$q" "$CONFIG" # Ensure config ends with a line feed
    echo "resolv-retry 15" >> "$CONFIG"
fi

## Option 5 - Change the tls-crypt path to point relative to the provider home
if [[ $CONFIG_MOD_TLS_CERTS == "1" ]]; then
    echo "Modification: Change tls-crypt keyfile path"
    config_directory=$(dirname "$CONFIG")

    # Some configs are already adjusted, need to handle both relative and absolute paths, like:
    # tls-crypt /etc/openvpn/celo/uk1-TCP-443-tls.key
    # tls-crypt uk1-TCP-443-tls.key
    sed -i -E "s#tls-crypt\s+(.*/)*#tls-crypt $config_directory/#g" "$CONFIG"
fi

## Option 6 - Update or set verbosity of openvpn logging
if [[ $(( "$CONFIG_MOD_VERBOSITY" )) -gt 0 ]]; then
    if [[ $(( "$CONFIG_MOD_VERBOSITY" )) -gt 9 ]]; then
        CONFIG_MOD_VERBOSITY=9
    fi
    echo "Modification: Set output verbosity to ${CONFIG_MOD_VERBOSITY}"
    # Remove any old options
    sed -i "/^verb.*$/d" "$CONFIG"

    # Add new ones
    sed -i "\$q" "$CONFIG" # Ensure config ends with a line feed
    echo "verb ${CONFIG_MOD_VERBOSITY}" >> "$CONFIG"
fi

## Option 7 - Remap the SIGUSR1 signal to SIGTERM
## We don't want OpenVPN to restart within the container
if [[ $CONFIG_MOD_REMAP_USR1 == "1" ]]; then
    echo "Modification: Remap SIGUSR1 signal to SIGTERM, avoid OpenVPN restart loop"
    # Remove any old options
    sed -i "/^remap-usr1.*$/d" "$CONFIG"

    # Add new ones
    sed -i "\$q" "$CONFIG" # Ensure config ends with a line feed
    echo "remap-usr1 SIGTERM" >> "$CONFIG"
fi

## Option 8 - Save config status and execute failure script if needed
if [[ $CONFIG_MOD_FAILURE_SCRIPT == "1" ]]; then
  echo "Modification: Updating status for config failure detection"

  # Get existing status
  CONFIG_STATUS=$(sed -n "s/^; status \(.*\)/\1/p" "${CONFIG}")
  if [[ "${CONFIG_STATUS}" == "unknown" ]]; then
    CONFIG_STATUS="failure"
  elif [[ "${CONFIG_STATUS}" != "failure" ]]; then
    CONFIG_STATUS="unknown"
  fi

  # Remove any old options
  sed -i "/^; status.*$/d" "${CONFIG}"
  
  # Add new ones
  sed -i "\$q" "${CONFIG}" # Ensure config ends with a line feed
  echo "; status ${CONFIG_STATUS}" >> "${CONFIG}"
  
  # Execute config failure script
  if [[ "${CONFIG_STATUS}" == "failure" ]]; then
    CONFIG_DIRECTORY=$(dirname "${CONFIG}")
    CONFIG_FAILURE_SCRIPT="${CONFIG_DIRECTORY}/config-failure.sh"

    if [[ -x "${CONFIG_FAILURE_SCRIPT}" ]]; then
      echo "Executing ${CONFIG_FAILURE_SCRIPT}"
      ${CONFIG_FAILURE_SCRIPT} "${CONFIG}"
    fi
  fi
fi
