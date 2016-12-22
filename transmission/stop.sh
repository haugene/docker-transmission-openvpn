#! /bin/sh

. /etc/transmission/userSetup.sh
exec sudo -u ${RUN_AS} /etc/init.d/sabnzbdplus stop &
kill $(ps aux | grep transmission-daemon | grep -v grep | awk '{print $2}')
