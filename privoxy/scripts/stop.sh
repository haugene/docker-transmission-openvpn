#!/bin/bash

if [[ "${WEBPROXY_ENABLED}" = "true" ]]; then

  pkill privoxy

fi
