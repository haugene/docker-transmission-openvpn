#!/bin/bash

source /root/.bashrc && /etc/transmission/start.kts "$@"
[[ ! -f /opt/tinyproxy/start.sh ]] || /opt/tinyproxy/start.sh
