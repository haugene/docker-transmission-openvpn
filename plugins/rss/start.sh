#!/bin/sh

#
# This script tries to figure out how the container is configured.
# The user has two options:
# 1. Mount a custom config file to be used
# 2. Use the built in template that supports one feed with regex filter
#

if [ -f /etc/transmission-rss.conf ] ; then
  echo "Found mounted /etc/transmission-rss.conf file"
elif [ -z "${RSS_URL}" ] || [ "${RSS_URL}" = "**None**" ] ; then
  echo "Error: No config is mounted and RSS_URL is not defined."
  echo "Have no config to start from. Exit with error code."
  exit 1
else
  # Configure plugin based on template. Use sed to insert 
    sed "s^url: placeholder^url: $RSS_URL^" < /etc/transmission-rss/transmission-rss.tmpl \
    | sed "s^download_path: placeholder^download_path: $TRANSMISSION_DOWNLOAD_DIR^" \
    > /etc/transmission-rss.conf

  if [ -z "${RSS_REGEXP}" ] ; then
    sed -i '/regexp/d' /etc/transmission-rss.conf
  else
    sed -i "s#regexp: placeholder#regexp: $RSS_REGEXP#" /etc/transmission-rss.conf
  fi
fi

echo "Starting RSS plugin"
cat /etc/transmission-rss.conf
transmission-rss
