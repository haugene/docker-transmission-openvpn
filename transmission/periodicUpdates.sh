#!/bin/sh

LOCAL_VPN_IP=$1

while [ 1 ]
do
    sleep 1m
    /etc/transmission/updatePort.sh $LOCAL_VPN_IP
    sleep 1h
done
