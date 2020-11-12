#! /bin/bash

set -e

baseURL="https://www.ipvanish.com/software/configs"
CONFIG_BUNDLE="configs.zip"

if [ -z "$VPN_PROVIDER_HOME" ]; then
    echo "ERROR: Need to have VPN_PROVIDER_HOME set to call this script" && exit 1
fi

# Delete all files for this provider, except scripts
find "$VPN_PROVIDER_HOME" -type f ! -name "*.sh" -delete

# Download and extract wanted bundle into temporary file
tmp_file=$(mktemp)
echo "Downloading OpenVPN config bundle $CONFIG_BUNDLE into temporary file $tmp_file"
curl -sSL "${baseURL}/${CONFIG_BUNDLE}" -o "$tmp_file"

echo "Extract OpenVPN config bundle into $VPN_PROVIDER_HOME"
unzip -qjo "$tmp_file" -d "$VPN_PROVIDER_HOME"

echo "Modify configs for this container"
find "$VPN_PROVIDER_HOME" -type f -name "*.ovpn" -print0 | xargs -n 1 -r0 /etc/openvpn/modify-openvpn-config.sh

# Select a random server as default.ovpn
ln -sf "$(find "$VPN_PROVIDER_HOME" -name "*.ovpn" | shuf -n 1)" "$VPN_PROVIDER_HOME"/default.ovpn
