#! /bin/bash

# If transmission-pre-stop.sh exists, run it
if [[ -x /scripts/transmission-pre-stop.sh ]]
then
   echo "Executing /scripts/transmission-pre-stop.sh"
   /scripts/transmission-pre-stop.sh "$@"
   echo "/scripts/transmission-pre-stop.sh returned $?"
fi

echo "Sending kill signal to transmission-daemon"
PID=$(pidof transmission-daemon)
kill $PID
# Give transmission-daemon time to shut down
for i in {1..10}; do
    [[ -z "$(pidof transmission-daemon)" ]] && break
    sleep .2
done

# If transmission-post-stop.sh exists, run it
if [[ -x /scripts/transmission-post-stop.sh ]]
then
   echo "Executing /scripts/transmission-post-stop.sh"
   /scripts/transmission-post-stop.sh "$@"
   echo "/scripts/transmission-post-stop.sh returned $?"
fi
