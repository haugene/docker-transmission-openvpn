#!/bin/bash

country_filter() { # curl -s "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.code, .name] | @tsv'
    local nordvpn_api=$1 country=(${NORDVPN_COUNTRY//[;,]/ })
    if [[ ${#country[@]} -ge 1 ]]; then
        country=${country[0]//_/ }
        local country_id=`curl -s "${nordvpn_api}/v1/servers/countries" | jq --raw-output ".[] |
                          select( (.name|test(\"^${country}$\";\"i\")) or
                                  (.code|test(\"^${country}$\";\"i\")) ) |
                          .id" | head -n 1`
        if [[ -n ${country_id} ]]; then
            echo "Searching for country : ${country} (${country_id})" > /dev/stderr
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
            echo "Searching for group: ${identifier}" > /dev/stderr
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
        echo "Searching for technology: ${identifier}" > /dev/stderr
        echo "filters\[servers_technologies\]\[identifier\]=${identifier}&"
    fi
}
select_hostname() { #TODO return multiples
    local nordvpn_api="https://api.nordvpn.com" \
          filters hostname

    echo "Selecting the best server..." > /dev/stderr
    filters+="$(country_filter ${nordvpn_api})"
    filters+="$(group_filter ${nordvpn_api})"
    filters+="$(technology_filter )"

    hostname=`curl -s "${nordvpn_api}/v1/servers/recommendations?${filters}limit=1" | jq --raw-output ".[].hostname"`
    if [[ -z ${hostname} ]]; then
        echo "Unable to find a server with the specified parameters, using any recommended server" > /dev/stderr
        hostname=`curl -s "${nordvpn_api}/v1/servers/recommendations?limit=1" | jq --raw-output ".[].hostname"`
    fi

    echo "Best server : ${hostname}" > /dev/stderr
    echo ${hostname}
}

# Select recommended VPN
echo "$(select_hostname).${NORDVPN_PROTOCOL,,}"