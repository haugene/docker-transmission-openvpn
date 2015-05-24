#! /bin/sh

kill $(ps aux | grep transmission-daemon | grep -v grep | awk '{print $2}')
