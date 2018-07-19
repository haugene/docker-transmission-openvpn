#!/bin/sh

/etc/transmission/stop.sh
[ ! -f /opt/tinyproxy/stop.sh ] || /opt/tinyproxy/stop.sh
