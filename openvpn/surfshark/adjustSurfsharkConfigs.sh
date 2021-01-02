#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip from TorGuard
curl -L https://api.surfshark.com/v1/server/configurations -o OpenVPN.zip \
  && unzip -j OpenVPN.zip && rm OpenVPN.zip

# Remove all '*.ovpn' files which don't contain the '*.prod.surfshark.*' pattern.
# I'm not sure what is the purpose of these files.
find . -type f -name '*.ovpn' ! -name '*.prod.surfshark.*' -delete

#Mass Rename All the Latest Config File Downloaded from https://account.surfshark.com/api/v1/server/configurations
rename 's/.prod.surfshark.com//' ./*.prod.surfshark.com*

for configFile in *.ovpn;
	do
	  #Remove The Following Three Lines Related to Ping from All Configs
		gsed -i '/ping\ 15/d' "$configFile"
		gsed -i '/ping-restart\ 0/d' "$configFile"
		gsed -i '/ping-timer-rem/d' "$configFile"

		gsed -i 's/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/' "$configFile"
	done

# Create symlink for default.ovpn
ln -s no-osl_udp.ovpn default.ovpn
