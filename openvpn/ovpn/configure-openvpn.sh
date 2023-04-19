#! /bin/bash

set -e

OVPN_CONNECTION=$OVPN_CONNECTION
export OVPN_CONNECTION

OVPN_PROTOCOL=$OVPN_PROTOCOL
export OVPN_PROTOCOL

OVPN_COUNTRY=$OVPN_COUNTRY
export OVPN_COUNTRY

OVPN_CITY=$OVPN_CITY
export OVPN_CITY

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
#cd ${0%/*}

cd /etc/openvpn/ovpn

# Delete all files for this provider, except scripts
find /etc/openvpn/ovpn -type f ! -name "*.sh" -delete

# Download and extract wanted bundle into temporary file

echo "creating temp folder"
mkdir /tmp/ovpnxtract/
echo "entering temp folder"
cd /tmp/ovpnxtract/
git clone https://github.com/haugene/vpn-configs-contrib.git 
echo "moving content"
mv /tmp/ovpnxtract/vpn-configs-contrib/openvpn/ovpn/* /etc/openvpn/ovpn
echo "deleting temp folder"
rm -rf /tmp/ovpnxtract/



#pattern=$OVPN_CONNECTION.$OVPN_COUNTRY.$OVPN_CITY.$OVPN_PROTOCOL
#OPENVPN_CONFIG=$(ls $pattern | shuf | head -n1)

OPENVPN_CONFIG=$OVPN_CONNECTION.$OVPN_COUNTRY.$OVPN_CITY.$OVPN_PROTOCOL

#if [[ -n "$OPENVPN_CONFIG" ]]; then 
#		ln -sf OPENVPN_CONFIG "$VPN_PROVIDER_HOME"/default.ovpn
#else
#		echo "There is no available config matching provided options!"
#		exit 3
#fi
