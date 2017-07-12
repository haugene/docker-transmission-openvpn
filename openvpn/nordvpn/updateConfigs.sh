#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip
curl -kL https://nordvpn.com/api/files/zip -o openvpn.zip \
  && unzip -j openvpn.zip && rm openvpn.zip

# Ensure linux line endings
dos2unix *

# Update configs with correct paths
sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn

# Create symlink for default.ovpn
ln -s uk50.nordvpn.com.udp1194.ovpn default.ovpn
