#!/bin/bash
/usr/share/openrc/support/openvpn/down.sh
/etc/transmission/stop.sh
[[ ! -f /opt/tinyproxy/stop.sh ]] || /opt/tinyproxy/stop.sh
