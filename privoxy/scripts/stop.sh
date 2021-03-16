#!/bin/bash

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  killall privoxy

fi
