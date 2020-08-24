#!/bin/bash

echo "Modify chosen OpenVPN config for best behaviour in this container"

# Every config modification have its own environemnt variable that can configure the behaviour.
# Different users, providers or host systems might have specific preferences.
# But we should try to add sensible defaults, a way to disable it, and alternative implementations as needed.

CONFIG_MOD_USERPASS=${CONFIG_MOD_USERPASS:-"1"}


## Option 1 - Change the auth-user-pass line to point to credentials file
if [[ $CONFIG_MOD_USERPASS == "1" ]]; then
    echo "Point auth-user-pass option to the username/password file"
    sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" "$CHOSEN_OPENVPN_CONFIG"
fi
