#! /bin/bash

set -e

if [ -z "$VPN_PROVIDER_HOME" ]; then
    echo "ERROR: Need to have VPN_PROVIDER_HOME set to call this script" && exit 1
fi

validate_options () {
		if [[ -n "$OVPN_CONNECTION" ]] && [[ $OVPN_CONNECTION =~ (multihop|standard) ]]; then
				return 1
		elif [[ -n "$OVPN_PROTOCOL" ]] && [[ $OVPN_PROTOCOL =~ (udp|tcp) ]]; then
				return 2
		fi

		return 0
}

# in case the script is executed from another directory
cd ${0%/*}

pattern=$OVPN_CONNECTION.$OVPN_COUNTRY.*.$OVPN_PROTOCOL.ovpn.com.ovpn
OPENVPN_CONFIG=$(ls $pattern | shuf | head -n1)

if [[ -n "$OPENVPN_CONFIG" ]]; then 
#		export OPENVPN_CONFIG="${OPENVPN_CONFIG#.ovpn}"
		ln -sf OPENVPN_CONFIG "$VPN_PROVIDER_HOME"/default.ovpn
else
		echo "There is no available config matching provided options!"
		exit 3
fi


