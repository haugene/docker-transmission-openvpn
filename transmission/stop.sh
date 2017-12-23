#! /bin/sh

# If custom-pre-stop.sh exists, run it
if [ -x /config/custom-pre-stop.sh ]
then
   echo "Executing /config/custom-pre-stop.sh"
   /config/custom-pre-stop.sh
fi

kill $(ps aux | grep transmission-daemon | grep -v grep | awk '{print $2}')

# If custom-post-stop.sh exists, run it
if [ -x /config/custom-post-stop.sh ]
then
   echo "Executing /config/custom-post-stop.sh"
   /config/custom-post-stop.sh
fi
