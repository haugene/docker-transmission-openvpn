#!/bin/bash

echo "Modify chosen OpenVPN config for best behaviour in this container"

# Parameter to control what modifications to be done to the config file. Default value is set here.
OPENVPN_CONFIG_MODIFICATION=${OPENVPN_CONFIG_MODIFICATION:-1}

# Each number in the OPENVPN_CONFIG_MODIFICATION parameter represents to a modification
# If the number is 0, it means the modification is disabled.
# All non-zero values are possible options for how the modification should be done.
CONFIG_MOD_USERPASS=${OPENVPN_CONFIG_MODIFICATION:0:1}


## Option 1 - Change the auth-user-pass line to point to credentials file
if [[ $CONFIG_MOD_USERPASS == "1" ]]; then
    sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" "$CHOSEN_OPENVPN_CONFIG"
fi