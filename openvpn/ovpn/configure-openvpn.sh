#! /bin/bash

# using snippet from vpn-configs-contrib/openvpn/ipvanish/configure-openvpn.sh

#rework assuming I can make my own vars.  Example var usage:
#      - OVPN_COUNTRY='us'
#      - OVPN_PROTOCOL='udp'
#      - OVPN_CONNECTION= 'standard' 


set -e


validate_options () {
		if [[ -n "$OVPN_CONNECTION" ]] && [[ $OVPN_CONNECTION =~ (multihop|standard) ]]; then
				return 1
		elif [[ -n "$OVPN_PROTOCOL" ]] && [[ $OVPN_PROTOCOL =~ (udp|tcp) ]]; then
				return 2
		fi

		return 0
}


while getopts "hl:t:p:" option
do
		case $option in
				l) location=$OPTARG ;;
				t) connection=$OPTARG ;; 
				p) protocol=$OPTARG ;;
				h|?) help; exit ;;
		esac
done

validate_options || help_and_exit $?

# in case the script is executed from another directory
cd ${0%/*}

pattern=${OVPN_CONNECTION:-*}.${OVPN_COUNTRY:-*}.*.${OVPN_PROTOCOL:-*}.ovpn.com.ovpn
OPENVPN_CONFIG=$(ls $pattern | shuf | head -n1)

if [[ -n "$OPENVPN_CONFIG" ]]; then 
#		export OPENVPN_CONFIG="${OPENVPN_CONFIG#.ovpn}"
		ln -sf OPENVPN_CONFIG "$VPN_PROVIDER_HOME"/default.ovpn
else
		echo "There is no available config matching provided options!"
		exit 3
fi


