#!/bin/bash

# Usage:
# docker exec -it -w / **CONTAINER** bash -c "./etc/openvn/updateFreeVPN.sh"

DIR="/tmp/freevpn"
TARGET="/etc/openvpn/freevpn"
ZIP_FILE="/tmp/freevpn.zip"

URL=`curl -s https://freevpn.me/accounts/`
REGEX='<a +.*href="(https:.*\.zip)"'

# Download FreeVPN Zip file
[[ $URL =~ $REGEX ]] && curl -s ${BASH_REMATCH[1]} -o ${ZIP_FILE}

# Unzip file
unzip -qo ${ZIP_FILE} -d $DIR

# Create directory if not exits
if [[ ! -d "$DIR" ]]
then
	mkdir $DIR
fi

# Process content file
IFS=$'\n'
for i in $(find ${DIR} -name "*.ovpn")
do
	sed -i 's/route 0.0.0.0 0.0.0.0/redirect-gateway/' $i
	if [[ $i == *TCP* ]];
       	then
		sed -i 's/explicit-exit-notify//' $i
       	fi

	file=${i##*/}
	file=${file/FreeVPN./}
	mv $i ${TARGET}/${file} > /dev/null 2>&1
done

# Delete temporary directory
rm -rf ${DIR}
