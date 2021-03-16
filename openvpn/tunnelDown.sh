#!/bin/bash

/etc/transmission/stop.sh
[[ ! -f /opt/privoxy/stop.sh ]] || /opt/privoxy/stop.sh
