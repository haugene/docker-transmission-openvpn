#! /bin/bash

pwd_url=$(curl -s "https://www.vpnbook.com/freevpn" | grep -m2 "Password:" | tail -n1 | cut -d \" -f2)
curl -s -X POST --header "apikey: 5a64d478-9c89-43d8-88e3-c65de9999580" \
    -F "url=https://www.vpnbook.com/${pwd_url}" \
    -F 'language=eng' \
    -F 'isOverlayRequired=true' \
    -F 'FileType=.Auto' \
    -F 'IsCreateSearchablePDF=false' \
    -F 'isSearchablePdfHideTextLayer=true' \
    -F 'scale=true' \
    -F 'detectOrientation=false' \
    -F 'isTable=false' \
    "https://api.ocr.space/parse/image" -o /tmp/vpnbook_pwd
export OPENVPN_PASSWORD=$(awk -F',' '{ print $1 }' /tmp/vpnbook_pwd | awk -F':' '{print $NF}' | tr -d '"')
