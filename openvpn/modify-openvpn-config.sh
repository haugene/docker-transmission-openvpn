#!/bin/bash

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


## Option 1 - Change the auth-user-pass line to point to credentials file
if [[ $CONFIG_MOD_USERPASS == "1" ]]; then
    [[ "${DEBUG}" == "true" ]] && echo "Point auth-user-pass option to the username/password file"
    sed -i "s#auth-user-pass.*#auth-user-pass /config/openvpn-credentials.txt#g" "$CONFIG"
fi

## Option 2 - Change the ca certificate path to point relative to the provider home
if [[ $CONFIG_MOD_CA_CERTS == "1" ]]; then
    [[ "${DEBUG}" == "true" ]] && echo "Change ca certificate path"
    config_directory=$(dirname "$CONFIG")
    sed -i "s#^ca #ca $config_directory/#g" "$CONFIG"
fi

## Option 3 - Update ping options to exit the container, so Docker will restart it
if [[ $CONFIG_MOD_PING == "1" ]]; then
    # Remove any old options
    sed -i "s/^ping.*//g" "$CONFIG"

    # Add new ones
    echo "inactive 3600" >> "$CONFIG"
    echo "ping 10" >> "$CONFIG"
    echo "ping-exit 60" >> "$CONFIG"
fi
