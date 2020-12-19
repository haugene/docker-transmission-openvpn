#!/bin/bash
/etc/transmission/stop.sh
/usr/share/openrc/support/openvpn/down.sh
[[ ! -f /opt/tinyproxy/stop.sh ]] || /opt/tinyproxy/stop.sh
