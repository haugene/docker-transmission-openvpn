#!/bin/sh

if [ ! -z "$OPEN_VPN_CONFIG" ]
then
	if [ -f /etc/openvpn/"${OPEN_VPN_CONFIG}".ovpn ]
  	then
		echo "Starting OpenVPN using config ${OPEN_VPN_CONFIG}.ovpn"
		exec openvpn --config /etc/openvpn/"${OPEN_VPN_CONFIG}".ovpn
	else
		echo "Supplied config ${OPEN_VPN_CONFIG}.ovpn could not be found."
		echo "Using default OpenVPN gateway: Netherlands"
		exec openvpn --config /etc/openvpn/Netherlands.ovpn
	fi
else
	echo "No VPN configuration provided. Using default: Netherlands"
	exec openvpn --config /etc/openvpn/Netherlands.ovpn
fi

