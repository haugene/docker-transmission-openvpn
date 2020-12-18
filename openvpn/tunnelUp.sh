#!/bin/bash
/usr/share/openrc/support/openvpn/up.sh
/etc/transmission/start.sh "$@"
[[ ! -f /opt/tinyproxy/start.sh ]] || /opt/tinyproxy/start.sh
