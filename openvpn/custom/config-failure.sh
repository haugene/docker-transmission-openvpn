#!/bin/bash

CONFIG=$1

echo "Config ${CONFIG} has failed, here might be a good place to check credentials"

# After config has been fixed, reset status to try again.
CONFIG_STATUS="unknown"
sed -i "/^; status.*$/d" "${CONFIG}"
sed -i "\$q" "${CONFIG}" # Ensure config ends with a line feed
echo "; status ${CONFIG_STATUS}" >> "${CONFIG}"
