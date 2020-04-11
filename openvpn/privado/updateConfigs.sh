#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip from TorGuard
curl -L https://privado.io/apps/ovpn_configs.zip -o privado_configs.zip \
  && unzip -j privado_configs.zip && rm -f privado_configs.zip

# Update configs with correct paths
sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn

# Create symlink for default.ovpn
ln -s ams-005.ovpn default.ovpn
