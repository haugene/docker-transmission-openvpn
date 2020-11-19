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

# Give transmission-daemon some time to shut down
TRANSMISSION_TIMEOUT_SEC=${TRANSMISION_TIMEOUT_SEC:-10}
for i in $(seq $TRANSMISSION_TIMEOUT_SEC)
do
    sleep 1
    [[ -z "$(pidof transmission-daemon)" ]] && break
    [[ $i == 1 ]] && echo "Waiting ${TRANSMISSION_TIMEOUT_SEC}s for transmission-daemon to die"
done

# Check whether transmission-daemon is still running
if [[ -z "$(pidof transmission-daemon)" ]]
then
    echo "Successfuly closed transmission-daemon"
else
    echo "Sending kill signal (SIGKILL) to transmission-daemon"
    kill -9 $PID
fi

# If transmission-post-stop.sh exists, run it
if [[ -x /scripts/transmission-post-stop.sh ]]
then
   echo "Executing /scripts/transmission-post-stop.sh"
   /scripts/transmission-post-stop.sh "$@"
   echo "/scripts/transmission-post-stop.sh returned $?"
fi
