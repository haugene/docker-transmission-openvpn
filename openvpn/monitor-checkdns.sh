#!/bin/bash
#Simple script that launch every x minutes the checksnd.sh script
#We use this because i don't succeed in initializing a cron job

while true
do
 #Waiting for sometime
 sleep 10m
 #echo "Executing /etc/openvpn/checkdns.sh"
 /etc/openvpn/checkdns.sh
 #echo "/etc/openvpn/checkdns.sh returned $?"
done
 
exit 0