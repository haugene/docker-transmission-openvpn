#!/bin/bash

set -e
source /etc/openvpn/utils.sh

# Parent script for updating OpenVPN configs
# If the script is called from elsewhere
cd "${0%/*}"

# Finds all provider specific update scripts and calls them
find . -mindepth 2 -maxdepth 2 -name 'updateConfigs.sh' -exec /bin/bash {} \;