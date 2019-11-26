#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip from TorGuard
curl -L https://www.usenetserver.com/vpn/software/configs/uns_configs.zip -o uns_configs.zip \
  && unzip -j uns_configs.zip && rm -f uns_configs.zip

mv vpn.crt ca.crt

# Update configs with correct paths
sed -i "s/ca vpn.crt/ca \/etc\/openvpn\/usenetserver\/ca.crt/" *.ovpn
sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn

# Create symlink for default.ovpn
ln -s ams-a01.ovpn default.ovpn
