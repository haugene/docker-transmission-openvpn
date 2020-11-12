#!/bin/bash
# redirect stdout/stderr to a file
#exec &>>route-pre-down.log

#Print Date
NOW=$(date +"%Y-%m-%d %T")

echo "${NOW}: route-pre-down script: Start "

echo "Sending exit signal to transmission."

transmission-remote --exit &

wait

echo "route-pre-down script: Done"



