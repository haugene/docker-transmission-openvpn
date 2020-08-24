#! /bin/bash

NORDVPN_PROTOCOL=${NORDVPN_PROTOCOL:-UDP}
export NORDVPN_PROTOCOL

NORDVPN_CATEGORY=${NORDVPN_CATEGORY:-P2P}
export NORDVPN_CATEGORY


if [[ -n $OPENVPN_CONFIG ]]; then
    tmp_Protocol="${OPENVPN_CONFIG##*.}"
    export NORDVPN_PROTOCOL=${tmp_Protocol^^}
    echo "Setting NORDVPN_PROTOCOL to: ${NORDVPN_PROTOCOL}"
    ${VPN_PROVIDER_HOME}/updateConfigs.sh --openvpn-config
elif [[ -n $NORDVPN_COUNTRY ]]; then
    export OPENVPN_CONFIG=$(${VPN_PROVIDER_HOME}/updateConfigs.sh)
else
    export OPENVPN_CONFIG=$(${VPN_PROVIDER_HOME}/updateConfigs.sh --get-recommended)
fi