#!/bin/bash

set -e
TIME_FORMAT=`date "+%Y-%m-%d %H:%M:%S"`

log()  {
    printf "${TIME_FORMAT} %b\n" "$*" > /dev/stderr;
}

fatal_error() {
    printf  "${TIME_FORMAT} \e[41mERROR:\033[0m %b\n" "$*" >&2;
    exit 1
}

# check for utils
script_needs() {
    command -v $1 >/dev/null 2>&1 || fatal_error "This script requires $1 but it's not installed. Please install it and run again."
}

script_init() {
    log "Checking curl installation"
    script_needs curl
    log "Checking unzip installation"
    script_needs unzip
}

adjust_configs() {
    # Change extension to .ovpn
    for i in *.conf; do
        mv -- "$i" "${i%.conf}.ovpn"
    done

    log "Checking line endings"
    sed -i 's/^M$//' *.ovpn
    # Update configs with correct options
    log "Updating configs for docker-transmission-openvpn"
    sed -i 's=auth-user-pass=auth-user-pass /config/openvpn-credentials.txt=g' *.ovpn
    sed -i 's/ping 15/inactive 3600\
    ping 10/g' *.ovpn
    sed -i 's/ping-restart 0/ping-exit 60/g' *.ovpn
    sed -i 's/ping-timer-rem//g' *.ovpn

    # Remove a few lines that break things for us
    sed -i '/update-resolv-conf/d' *.ovpn
}

# If the script is called from elsewhere
cd "${0%/*}"
script_init

log "Removing existing configs"
find . ! -name '*.sh' -type f -delete

# Instructions and download link was found here:
# https://www.perfect-privacy.com/en/manuals/linux_openvpn_terminal
ovpn_zip="https://www.perfect-privacy.com/downloads/openvpn/get?system=linux"
zip_file="ovpn.zip"
log "Downloading openvpn configs"
curl $ovpn_zip -o $zip_file

log "Extracting openvpn configs"
unzip -j $zip_file
rm $zip_file

adjust_configs

if [[ ! -z $selected ]]
then
    echo ${selected}
fi

cd "${0%/*}"
