#!/bin/bash

set -e

if [ -z "$VPN_PROVIDER_HOME" ]; then
    echo "ERROR: Need to have VPN_PROVIDER_HOME set to call this script" && exit 1
fi

# Download and extract wanted bundle into temporary file
tmp_file=$(mktemp)
echo "Downloading OpenVPN config bundle into temporary file $tmp_file"
curl -L https://api.surfshark.com/v1/server/configurations -o "$tmp_file"


echo "Extract OpenVPN config bundle into $VPN_PROVIDER_HOME"
unzip -qjo "$tmp_file" -d "$VPN_PROVIDER_HOME"

# Remove all '*.ovpn' files which don't contain the '*.prod.surfshark.*' pattern.
# I'm not sure what is the purpose of these files.
find  "$VPN_PROVIDER_HOME" -type f -name '*.ovpn' ! -name '*.prod.surfshark.*' -delete

for configFile in "$VPN_PROVIDER_HOME"/*.ovpn;
	do
	  #Remove The Following Three Lines Related to Ping from All Configs
		sed -i '/ping\ 15/d' "$configFile"
		sed -i '/ping-restart\ 0/d' "$configFile"
		sed -i '/ping-timer-rem/d' "$configFile"

		sed -i 's/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/' "$configFile"

    # Remove ".prod.surfshark.com" from filenames, to keep it consistent with how it's been always done for this provider
		mv "$configFile" ${configFile//.prod.surfshark.com/}
	done

# Select a random server as default.ovpn
ln -sf "$(find "$VPN_PROVIDER_HOME" -name "*.ovpn" | shuf -n 1)" "$VPN_PROVIDER_HOME"/default.ovpn
