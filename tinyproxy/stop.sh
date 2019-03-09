#!/bin/bash

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  /etc/init.d/tinyproxy stop

fi
