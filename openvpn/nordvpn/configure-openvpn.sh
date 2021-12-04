#!/bin/bash

source /etc/openvpn/utils.sh

NORDVPN_PROTOCOL=${NORDVPN_PROTOCOL:-UDP}
export NORDVPN_PROTOCOL

NORDVPN_CATEGORY=${NORDVPN_CATEGORY:-P2P}
export NORDVPN_CATEGORY


if [[ -n $OPENVPN_CONFIG ]]; then
    echo "Downloading user specified config. NORDVPN_PROTOCOL is set to: ${NORDVPN_PROTOCOL}"
    ${VPN_PROVIDER_HOME}/updateConfigs.sh --openvpn-config
elif [[ -n $NORDVPN_COUNTRY ]]; then
    export OPENVPN_CONFIG=$(${VPN_PROVIDER_HOME}/updateConfigs.sh)
else
    export OPENVPN_CONFIG=$(${VPN_PROVIDER_HOME}/updateConfigs.sh --get-recommended)
fi