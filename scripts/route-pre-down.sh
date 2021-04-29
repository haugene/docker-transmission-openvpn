#!/bin/bash
# redirect stdout/stderr to a file
#exec &>>route-pre-down.log

#Print Date
NOW=$(date +"%Y-%m-%d %T")

echo "${NOW}: route-pre-down script: Start "

echo "Sending exit signal to transmission."
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt
transmission_username=$(head -1 ${TRANSMISSION_PASSWD_FILE})
transmission_passwd=$(tail -1 ${TRANSMISSION_PASSWD_FILE})
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

# Check if transmission remote is set up with authentication
auth_enabled=$(grep 'rpc-authentication-required\"' "$transmission_settings_file" \
                   | grep -oE 'true|false')

if [[ "true" = "$auth_enabled" ]]
  then
  echo "transmission auth required"
  myauth="--auth $transmission_username:$transmission_passwd"
else
    echo "transmission auth not required"
    myauth=""
fi

transmission-remote $myauth --exit &

wait

echo "route-pre-down script: Done"



