#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip from TorGuard
curl -L https://torguard.net/downloads/OpenVPN-UDP.zip -o OpenVPN-UDP.zip \
  && unzip -j OpenVPN-UDP.zip && rm OpenVPN-UDP.zip

# Remove TorGuard prefix of config files and ensure linux line endings
rename 's/^TorGuard\.//' *.ovpn

# Convert CRLF to Linux
sed -i "s/\r$//" *.ovpn

# Update configs with correct paths
sed -i "s/ca ca.crt/ca \/etc\/openvpn\/torguard\/ca.crt/" *.ovpn
sed -i "s/tls-auth ta.key/tls-auth \/etc\/openvpn\/torguard\/ta.key/" *.ovpn
sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn

# Remove incompatible directives
sed -i "s/^block-outside-dns/# block-outside-dns/" *.ovpn
sed -i "s/^keepalive/# keepalive/" *.ovpn

# Create symlink for default.ovpn
ln -s Netherlands.ovpn default.ovpn
