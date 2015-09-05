#!/bin/sh

bold=$(tput bold)
normal=$(tput sgr0)

#
# This is a script to ease the process of updating and adding .ovpn files to the project.
# As some customizations have to be done with the .ovpn files from the providers
# this script was created to make it easy and also to highlight which changes we actually do and why.
#
# Intended usage is to download .zip (or other) package with .ovpn files from your provider.
# Then delete the content in the provider-folder, replace with the new ones, run the script and it should be quite good.
# Just need to double check that the default.ovpn is still there and that the diff to origin looks reasonable.
#

display_usage() { 
	echo "${bold}Hint: read the script before using it${normal}"
	echo "If you just forgot: ./adjustConfigs.sh <provider-folder>"
}

# if no arguments supplied, display usage 
if [  $# -lt 1 ] 
then 
	display_usage
	exit 1
fi

provider=$1

for configFile in $provider/*.ovpn;
	do
		# Set fixed tun device number
		sed -i "s/dev tun.*/dev tun0/g" "$configFile"

		# Absolute reference to ca cert
		sed -i "s/ca .*\.crt/ca \/etc\/openvpn\/$provider\/ca.crt/g" "$configFile"

		# Absolute reference to crl
		sed -i "s/crl-verify.*\.pem/crl-verify \/etc\/openvpn\/$provider\/crl.pem/g" "$configFile"

		# Set user-pass file location
		sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn-credentials.txt/g" "$configFile"

		# Insert transmission control script triggers
		cat <<EOT >> $configFile


# OpenVPN controls startup and shut down of transmission
script-security 2
up /etc/transmission/start.sh
down /etc/transmission/stop.sh
EOT

	done

echo "Updated all .ovpn files in folder $provider"
