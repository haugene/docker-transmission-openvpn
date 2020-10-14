#! /bin/bash

set -e

# These are the possible bundles from PIA
# https://www.privateinternetaccess.com/openvpn/openvpn-nextgen.zip
# https://www.privateinternetaccess.com/openvpn/openvpn-strong-nextgen.zip
# https://www.privateinternetaccess.com/openvpn/openvpn-ip-nextgen.zip
# https://www.privateinternetaccess.com/openvpn/openvpn-tcp-nextgen.zip
# https://www.privateinternetaccess.com/openvpn/openvpn-strong-tcp-nextgen.zip

baseURL="https://www.privateinternetaccess.com/openvpn"
PIA_OPENVPN_CONFIG_BUNDLE=${PIA_OPENVPN_CONFIG_BUNDLE:-"openvpn-nextgen"}

if [ -z "$VPN_PROVIDER_HOME" ]; then
    echo "ERROR: Need to have VPN_PROVIDER_HOME set to call this script" && exit 1
fi

# Delete all files for PIA provider, except scripts
find "$VPN_PROVIDER_HOME" -type f ! -name "*.sh" -delete

# Download and extract wanted bundle into temporary file
tmp_file=$(mktemp)
echo "Downloading OpenVPN config bundle $PIA_OPENVPN_CONFIG_BUNDLE into temporary file $tmp_file"
curl -sSL "${baseURL}/${PIA_OPENVPN_CONFIG_BUNDLE}.zip" -o "$tmp_file"

echo "Extract OpenVPN config bundle into PIA directory $VPN_PROVIDER_HOME"
unzip -qjo "$tmp_file" -d "$VPN_PROVIDER_HOME"

echo "Modify configs for this container"
find "$VPN_PROVIDER_HOME" -type f -name "*.ovpn" -exec /etc/openvpn/modify-openvpn-config.sh {} \;

# Select a random server as default.ovpn
ln -sf "$(find "$VPN_PROVIDER_HOME" -name "*.ovpn" | shuf -n 1)" "$VPN_PROVIDER_HOME"/default.ovpn
