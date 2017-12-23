#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Ensure linux line endings
dos2unix *

# Update auth config line with correct path
gsed -i "s/^auth-user-pass.*/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn

# Remove comments and empty lines
gsed -i -e "/^#.*/d" -e "/^$/d" *.ovpn

# Create symlink for default.ovpn
ln -s "U.S. Texas Hub - TCP.ovpn" default.ovpn
