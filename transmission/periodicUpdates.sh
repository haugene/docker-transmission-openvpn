#!/bin/sh

while [ 1 ]
do
    sleep 1m
    /etc/transmission-daemon/updatePort.sh
    sleep 1h
done
