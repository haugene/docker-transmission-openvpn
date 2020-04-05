#! /bin/bash

FREEVPN_DOMAIN=${OPENVPN_CONFIG%%-*}
export OPENVPN_PASSWORD=$(curl -s https://freevpn.${FREEVPN_DOMAIN:-"me"}/accounts/ | grep Password |  sed s/"^.*Password\:.... "/""/g | sed s/"<.*"/""/g)

# Update FreeVPN certs
${VPN_PROVIDER_CONFIGS}/updateFreeVPN.sh