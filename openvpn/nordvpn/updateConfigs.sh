#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Get updated configuration zip
curl -kL https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip -o openvpn.zip \
  && unzip -j openvpn.zip && rm openvpn.zip

# Ensure linux line endings
#dos2unix *

# Update configs with correct options
sed -i 's=auth-user-pass=auth-user-pass /config/openvpn-credentials.txt=g' *.ovpn
sed -i 's/ping 15/inactive 3600\
ping 10/g' *.ovpn

sed -i 's/ping-restart 0/ping-exit 60/g' *.ovpn
sed -i 's/ping-timer-rem//g' *.ovpn

# Create symlink for default.ovpn
ln -s nl8.nordvpn.com.tcp.ovpn default.ovpn
