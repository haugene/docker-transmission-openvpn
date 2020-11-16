#! /bin/bash

# If transmission-pre-stop.sh exists, run it
if [[ -x /scripts/transmission-pre-stop.sh ]]
then
   echo "Executing /scripts/transmission-pre-stop.sh"
   /scripts/transmission-pre-stop.sh "$@"
   echo "/scripts/transmission-pre-stop.sh returned $?"
fi

echo "Sending kill signal (SIGTERM) to transmission-daemon"
PID=$(pidof transmission-daemon)
kill $PID

# Give transmission-daemon some time to shut down
TRANSMISSION_TIMEOUT_SEC=10
TIMEOUT_NITER=$((2 * $TRANSMISSION_TIMEOUT_SEC))
for i in $(seq $TIMEOUT_NITER); do
    ps -p "$PID" &> /dev/null || break
    [[ $i == 1 ]] && echo "Waiting ${TRANSMISSION_TIMEOUT_SEC}sec for transmission-daemon to die"
    sleep .5
done

# Check whether transmission-daemon is still running
if ! ps -p "$PID" &> /dev/null; then
    echo "Sending kill signal (SIGKILL) to transmission-daemon"
    kill -9 $PID
else
    echo "Successfuly closed transmission-daemon"
fi

# If transmission-post-stop.sh exists, run it
if [[ -x /scripts/transmission-post-stop.sh ]]
then
   echo "Executing /scripts/transmission-post-stop.sh"
   /scripts/transmission-post-stop.sh "$@"
   echo "/scripts/transmission-post-stop.sh returned $?"
fi
