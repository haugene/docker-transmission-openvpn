#!/bin/sh

# Source our persisted env variables from container startup
dockerize -template /etc/transmission-rss/environment-variables.tmpl:/etc/transmission-rss/environment-variables.sh
. /etc/transmission-rss/environment-variables.sh

if [ -z "${RSS_URL}" ] || [ "${RSS_URL}" = "**None**" ] ; then
 echo "NO RSS URL CONFIGURED, IGNORING"
else
  if [ -z "${RSS_REGEXP}" ] ; then
  	sed -i 's/regexp:*//g' /etc/transmission-rss/transmission-rss.tmpl
  fi
  dockerize -template /etc/transmission-rss/transmission-rss.tmpl:/etc/transmission-rss.conf
  echo "STARTING RSS PLUGIN"
  transmission-rss
fi
