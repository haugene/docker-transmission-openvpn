#!/bin/bash
EXTERNAL_VPN_IP=$(curl icanhazip.com)
echo "External IP after vpn setup: $(cat ~/non_vpn_ip) previous: ${EXTERNAL_NON_VPN_IP}"
/etc/transmission/start.sh "$@"
[[ ! -f /opt/tinyproxy/start.sh ]] || /opt/tinyproxy/start.sh
