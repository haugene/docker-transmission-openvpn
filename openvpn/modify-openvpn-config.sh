#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi
CONFIG=$1

[[ "${DEBUG}" == "true" ]] && echo "Modifying $CONFIG for best behaviour in this container"

# Every config modification have its own environemnt variable that can configure the behaviour.
# Different users, providers or host systems might have specific preferences.
# But we should try to add sensible defaults, a way to disable it, and alternative implementations as needed.

CONFIG_MOD_USERPASS=${CONFIG_MOD_USERPASS:-"1"}


## Option 1 - Change the auth-user-pass line to point to credentials file
if [[ $CONFIG_MOD_USERPASS == "1" ]]; then
    [[ "${DEBUG}" == "true" ]] && echo "Point auth-user-pass option to the username/password file"
    sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" "$CONFIG"
fi
