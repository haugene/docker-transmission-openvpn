#!/bin/bash

set -x

bold=$(tput bold)
normal=$(tput sgr0)

# Wrapper script of adjustConfigs.sh
# Getting errors that I don't care to fix when running sed on my mac (different versions and syntax)
# Copying provider files into a temporary container, running the script and copying it out again


display_usage() { 
	echo "${bold}Hint: read the script before using it${normal}"
	echo "If you just forgot: ./adjustConfigs.sh <provider-folder>"
}

# if no arguments supplied, display usage 
if [  $# -lt 1 ] 
then 
	display_usage
	exit 1
fi

provider=$1

# Create a simple container that, when started, just tails a static file
CONTAINER=$(docker create ubuntu bash -c "tail -f /etc/os-release")

# Copy provider files and script into container
docker cp ${provider} ${CONTAINER}:/${provider}
docker cp adjustConfigs.sh ${CONTAINER}:/

# Start it and exec the script (need to install dos2unix first, might be improved later)
docker start ${CONTAINER}
docker exec -it ${CONTAINER} bash -c "apt update && apt install -y dos2unix"
docker exec -it -w / ${CONTAINER} bash -c "./adjustConfigs.sh ${provider}"
docker exec -it -w /${provider} ${CONTAINER} bash -c "find . -type f -name '*.ovpn' -print0 | xargs -0 dos2unix"

# Copy our result back out, and remove the container
docker cp ${CONTAINER}:/${provider} .
docker rm -f ${CONTAINER}