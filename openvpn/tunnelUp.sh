#!/bin/bash
/usr/share/openrc/support/openvpn/up.sh
/etc/openvpn/DNS-Leak-Test.sh
/etc/transmission/start.sh "$@"
[[ ! -f /opt/tinyproxy/start.sh ]] || /opt/tinyproxy/start.sh
