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
}

country_filter() { # curl -s "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.code, .name] | @tsv'
    local nordvpn_api=$1 country=(${NORDVPN_COUNTRY//[;,]/ })
    if [[ ${#country[@]} -ge 1 ]]; then
        country=${country[0]//_/ }
        local country_id=`curl -s "${nordvpn_api}/v1/servers/countries" | jq --raw-output ".[] |
                          select( (.name|test(\"^${country}$\";\"i\")) or
                                  (.code|test(\"^${country}$\";\"i\")) ) |
                          .id" | head -n 1`
        if [[ -n ${country_id} ]]; then
            log "Searching for country : ${country} (${country_id})"
            echo "filters\[country_id\]=${country_id}&"
        fi
    fi
}
group_filter() { # curl -s "https://api.nordvpn.com/v1/servers/groups" | jq --raw-output '.[] | [.identifier, .title] | @tsv'
    local nordvpn_api=$1 category=(${NORDVPN_CATEGORY//[;,]/ })
    if [[ ${#category[@]} -ge 1 ]]; then
        category=${category[0]//_/ }
        local identifier=`curl -s "${nordvpn_api}/v1/servers/groups" | jq --raw-output ".[] |
                          select( .title | test(\"${category}\";\"i\") ) |
                          .identifier" | head -n 1`
        if [[ -n ${identifier} ]]; then
            log "Searching for group: ${identifier}"
            echo "filters\[servers_groups\]\[identifier\]=${identifier}&"
        fi
    fi
}

technology_filter() { # curl -s "https://api.nordvpn.com/v1/technologies" | jq --raw-output '.[] | [.identifier, .name ] | @tsv' | grep openvpn
    local identifier
    if [[ ${NORDVPN_PROTOCOL,,} =~ .*udp.* ]]; then
        identifier="openvpn_udp"
    elif [[ ${NORDVPN_PROTOCOL,,} =~ .*tcp.* ]];then
        identifier="openvpn_tcp"
    fi
    if [[ -n ${identifier} ]]; then
        log "Searching for technology: ${identifier}"
        echo "filters\[servers_technologies\]\[identifier\]=${identifier}&"
    fi
}
select_hostname() { #TODO return multiples
    local nordvpn_api="https://api.nordvpn.com" \
          filters hostname

    log "Selecting the best server..."
    if [[ "$1" != "-d" ]]; then
        filters+="$(country_filter ${nordvpn_api})"
    fi
    filters+="$(group_filter ${nordvpn_api})"
    filters+="$(technology_filter )"

    hostname=`curl -s "${nordvpn_api}/v1/servers/recommendations?${filters}limit=1" | jq --raw-output ".[].hostname"`
    if [[ -z ${hostname} ]]; then
        log "Unable to find a server with the specified parameters, using any recommended server"
        hostname=`curl -s "${nordvpn_api}/v1/servers/recommendations?limit=1" | jq --raw-output ".[].hostname"`
    fi

    log "Best server : ${hostname}"
    echo ${hostname}
}
download_hostname() {
    #udp ==> https://downloads.nordcdn.com/configs/files/ovpn_udp/servers/nl601.nordvpn.com.udp.ovpn
    #tcp ==> https://downloads.nordcdn.com/configs/files/ovpn_tcp/servers/nl542.nordvpn.com.tcp.ovpn

    local nordvpn_cdn="https://downloads.nordcdn.com/configs/files"     

    if [[ ${NORDVPN_PROTOCOL,,} == udp ]]; then
        nordvpn_cdn="${nordvpn_cdn}/ovpn_udp/servers/"
    elif [[ ${NORDVPN_PROTOCOL,,} == tcp ]];then
        nordvpn_cdn="${nordvpn_cdn}/ovpn_tcp/servers/"
    fi

    if [[ "$1" == "-d" ]]; then
        nordvpn_cdn=${nordvpn_cdn}${2}
        ovpnName=default.ovpn
    else
        nordvpn_cdn=${nordvpn_cdn}${1}
        ovpnName=${1}.ovpn
    fi

    if [[ ${NORDVPN_PROTOCOL,,} == udp ]]; then
        nordvpn_cdn="${nordvpn_cdn}.udp.ovpn"
    elif [[ ${NORDVPN_PROTOCOL,,} == tcp ]];then
        nordvpn_cdn="${nordvpn_cdn}.tcp.ovpn"
    fi

    log "Downloading config: ${ovpnName}"
    log "Downloading from: ${nordvpn_cdn}"
    curl ${nordvpn_cdn} -o "${ovpnName}"
}
update_hostname() {
    log "Checking line endings"
    sed -i 's/^M$//' *.ovpn
    # Update configs with correct options
    log "Updating configs for docker-transmission-openvpn"
    sed -i 's=auth-user-pass=auth-user-pass /config/openvpn-credentials.txt=g' *.ovpn
    sed -i 's/ping 15/inactive 3600\
    ping 10/g' *.ovpn
    sed -i 's/ping-restart 0/ping-exit 60/g' *.ovpn
    sed -i 's/ping-timer-rem//g' *.ovpn
}

# If the script is called from elsewhere
cd "${0%/*}"
script_init

log "Removing existing configs"
find . ! -name '*.sh' -type f -delete

if [[ ! -z $OPENVPN_CONFIG ]] && [[ ! -z $NORDVPN_COUNTRY ]]
then
    default="$(select_hostname)"
else
    default="$(select_hostname -d)"
fi
download_hostname -d ${default}

if [[ ${1} == "--get-recommended" ]] || [[ ${1} == "-r" ]]
then
    selected="default"    
elif [[ ${1} == "--openvpn-config" ]] || [[ ${1} == "-o" ]]
then
    log "Using OpenVPN CONFIG :: ${OPENVPN_CONFIG,,}"
    download_hostname ${OPENVPN_CONFIG,,}
elif [[ ! -z $NORDVPN_COUNTRY ]]
then
    selected="$(select_hostname)"
    download_hostname ${selected}
else
    selected="default"
fi

update_hostname

if [[ ! -z $selected ]]
then
    echo ${selected}
fi

cd "${0%/*}"
