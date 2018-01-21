#! /bin/sh

# If transmission-pre-stop.sh exists, run it
if [ -x /scripts/transmission-pre-stop.sh ]
then
   echo "Executing /scripts/transmission-pre-stop.sh"
   /scripts/transmission-pre-stop.sh
   echo "/scripts/transmission-pre-stop.sh returned $?"
fi

kill $(ps aux | grep transmission-daemon | grep -v grep | awk '{print $2}')

# If transmission-post-stop.sh exists, run it
if [ -x /scripts/transmission-post-stop.sh ]
then
   echo "Executing /scripts/transmission-post-stop.sh"
   /scripts/transmission-post-stop.sh
   echo "/scripts/transmission-post-stop.sh returned $?"
fi
