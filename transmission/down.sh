#! /bin/bash

kill $(ps aux | grep transmission-daemon | grep -v grep | awk '{print $2}')
