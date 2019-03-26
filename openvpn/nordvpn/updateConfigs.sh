#!/bin/bash
set -e
TIME_FORMAT=`date "+%Y-%m-%d %H:%M:%S"`

log()  {
    printf "${TIME_FORMAT} %b\n" "$*";
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

    # log "Checking dos2unix installation"
    # script_needs dos2unix

    log "Checking unzip installation"
    script_needs unzip
}

script_init

# If the script is called from elsewhere
cd "${VPN_PROVIDER_CONFIGS}"

# Delete everything (not this script though)
log "Removing existing configs"
find . ! -name '*.sh' -type f -delete

# Get updated configuration zip
log "Downloading latest configs"
curl -skL https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip -o openvpn.zip \
  && unzip -j openvpn.zip $1 >/dev/null 2>&1 && rm openvpn.zip

# Ensure linux line endings
log "Checking line endings"
# dos2unix * $1 >/dev/null 2>&1
# find . -name '*.ovpn' -type f -print 0 | xargs -0 sed -i 's/^M$//'

find ${VPN_PROVIDER_CONFIGS} -name '*nordvpn*.ovpn' -type f -exec sed -i 's/^M$//' {} \;

# Update configs with correct options
log "Updating configs for docker-transmission-openvpn"
sed -i 's=auth-user-pass=auth-user-pass /config/openvpn-credentials.txt=g' *nordvpn*.ovpn
sed -i 's/ping 15/inactive 3600\
ping 10/g' *nordvpn*.ovpn
sed -i 's/ping-restart 0/ping-exit 60/g' *nordvpn*.ovpn
sed -i 's/ping-timer-rem//g' *nordvpn*.ovpn

# Pick a random file config for default.ovpn
random_config=$(ls uk*udp* | sort -R | head -n1)
log "Setting default.ovpn to $random_config"

ln -sf $random_config default.ovpn

cd "${0%/*}"
