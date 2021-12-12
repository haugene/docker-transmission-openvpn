#!/bin/bash
#
# get config name based on api recommendation + ENV Vars (NORDVPN_COUNTRY, NORDVPN_PROTOCOL, NORDVPN_CATEGORY)
#
# 2021/09
#
#
# NORDVPN_COUNTRY: code or name
# curl -s "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.code, .name] | @tsv'
# NORDVPN_PROTOCOL: tcp or upd, tcp if none or unknown. Many technologies are not used as only openvpn_udp and openvpn_tcp are tested.
# Will request api with openvpn_<NORDVPN_PROTOCOL>.
# curl -s "https://api.nordvpn.com/v1/technologies" | jq --raw-output '.[] | [.identifier, .name ] | @tsv' | grep openvpn
# NORDVPN_CATEGORY: default p2p. not all countries have all combination of NORDVPN_PROTOCOL(technologies) and NORDVPN_CATEGORY(groups),
# hence many queries to the api may return no recommended servers.
# curl -s https://api.nordvpn.com/v1/servers/groups | jq .[].identifier
#
#Changes
# 2021/09/15: check ENV values if still supported
# 2021/09/22: store json results, merged configure-openvpn + updateConfigs.sh: OPENVPN_CONFIG is confusing for users. (#1958)

set -e
[[ -f /etc/openvpn/utils.sh ]] && source /etc/openvpn/utils.sh || true

#Variables
TIME_FORMAT=$(date "+%Y-%m-%d %H:%M:%S")
nordvpn_api="https://api.nordvpn.com"
nordvpn_dl=downloads.nordcdn.com
nordvpn_cdn="https://${nordvpn_dl}/configs/files"
nordvpn_doc="https://haugene.github.io/docker-transmission-openvpn/provider-specific/#nordvpn"
possible_protocol="tcp, udp"
VPN_PROVIDER_HOME=${VPN_PROVIDER_HOME:-/etc/openvpn/nordvpn}

#Nordvpn has a fetch limit, storing json to prevent hitting the limit.
json_countries=$(curl -s ${nordvpn_api}/v1/servers/countries)
#groups used for NORDVPN_CATEGORY
json_groups=$(curl -s ${nordvpn_api}/v1/servers/groups)
#technologies (NORDVPN_PROTOCOL) not used as only openvpn_udp and openvpn_tcp are tested.
json_technologies=$(curl -s ${nordvpn_api}/v1/technologies)

possible_categories="$(echo ${json_groups} | jq -r .[].identifier | tr '\n' ', ')"
possible_country_codes="$(echo ${json_countries} | jq -r .[].code | tr '\n' ', ')"
possible_country_names="$(echo ${json_countries} | jq -r .[].name | tr '\n' ', ')"
possible_protocol="$(echo ${json_technologies} | jq -r '.[] | [.identifier, .name ]' | tr '\n' ', ' | grep openvpn)"

# Functions
# TESTS: set values to test API response.
test1NoValues() {
  export NORDVPN_COUNTRY=''
  export NORDVPN_PROTOCOL=''
  export NORDVPN_CATEGORY=''
  log "expected <your country code><NN>.nordvpn.com.ovpn with openvpn_udp"
}

test2NoCategory() {
  export NORDVPN_COUNTRY='EE'
  export NORDVPN_PROTOCOL='tcp'
  export NORDVPN_CATEGORY=''
  log "expected ee<NN>.nordvpn.com.ovpn with openvpn_tcp"
}

test3Incompatible_combinations() {
  export NORDVPN_COUNTRY='EE'
  export NORDVPN_PROTOCOL='openvpn_tcp_tls_crypt'
  export NORDVPN_CATEGORY='legacy_obfuscated_servers'
  log "expected a config file not respecting country filter. + message: Unable to find a server with the specified parameters, using any recommended server"
}

# Normal run functions
log() {
  printf "${TIME_FORMAT} %b\n" "$*" >/dev/stderr
}

fatal_error() {
  printf "${TIME_FORMAT} \e[41mERROR:\033[0m %b\n" "$*" >&2
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

country_filter() {
  local nordvpn_api=$1 country=(${NORDVPN_COUNTRY//[;,]/ })
  if [[ ${#country[@]} -ge 1 ]]; then
    country=${country[0]//_/ }
    local country_id=$(echo ${json_countries} | jq --raw-output ".[] |
                          select( (.name|test(\"^${country}$\";\"i\")) or
                                  (.code|test(\"^${country}$\";\"i\")) ) |
                          .id" | head -n 1)
  fi
  if [[ -n ${country_id} ]]; then
    log "Searching for country : ${country} (${country_id})"
    echo "filters\[country_id\]=${country_id}&"
  else
    log "Warning, empty or invalid NORDVPN_COUNTRY (value=${NORDVPN_COUNTRY}). Ignoring this parameter. Possible values are:${possible_country_codes[*]} or ${possible_country_names[*]}. Please check ${nordvpn_doc}"
  fi
}

group_filter() {
  local nordvpn_api=$1 category=(${NORDVPN_CATEGORY//[;,]/ })
  if [[ ${#category[@]} -ge 1 ]]; then
    #category=${category[0]//_/ }
    local identifier=$(echo $json_groups | jq --raw-output ".[] |
                          select( ( .identifier|test(\"${category}\";\"i\")) or
                                  ( .title| test(\"${category}\";\"i\")) ) |
                          .identifier" | head -n 1)
  fi
  if [[ -n ${identifier} ]]; then
    log "Searching for group: ${identifier}"
    echo "filters\[servers_groups\]\[identifier\]=${identifier}&"
  else
    log "Warning, empty or invalid NORDVPN_CATEGORY (value=${NORDVPN_CATEGORY}). ignoring this parameter. Possible values are: ${possible_categories[*]}. Please check ${nordvpn_doc}"
  fi
}

technology_filter() {
  local identifier
  if [[ ${NORDVPN_PROTOCOL,,} =~ .*udp.* ]]; then
    identifier="openvpn_udp"
  elif [[ ${NORDVPN_PROTOCOL,,} =~ .*tcp.* ]]; then
    identifier="openvpn_tcp"
  fi

  if [[ -n ${identifier} ]]; then
    log "Searching for technology: ${identifier}"
    echo "filters\[servers_technologies\]\[identifier\]=${identifier}&"
  else
    log "Empty or invalid NORDVPN_PROTOCOL (value=${NORDVPN_PROTOCOL}), expecting tcp or udp. setting to udp. Please read ${nordvpn_doc}"
    echo "filters\[servers_technologies\]\[identifier\]=openvpn_udp&"
    export NORDVPN_PROTOCOL=udp
  fi
}

select_hostname() { #TODO return multiples
  local filters hostname

  log "Selecting the best server..."
  filters+="$(country_filter ${nordvpn_api})"
  filters+="$(group_filter ${nordvpn_api})"
  filters+="$(technology_filter)"

  hostname=$(curl -s "${nordvpn_api}/v1/servers/recommendations?${filters}limit=1" | jq --raw-output ".[].hostname")
  if [[ -z ${hostname} ]]; then
    log "Warning, unable to find a server with the specified parameters, please review your parameters, NORDVPN_COUNTRY=${NORDVPN_COUNTRY}, NORDVPN_CATEGORY=${NORDVPN_CATEGORY}, NORDVPN_PROTOCOL=${NORDVPN_PROTOCOL}"
    #hostname=$(curl -s "${nordvpn_api}/v1/servers/recommendations?limit=1" | jq --raw-output ".[].hostname")
    echo ''
  else
    load=$(curl --silent ${nordvpn_api}/server/stats/${hostname} | jq .percent)
    log "Best server : ${hostname}, load: ${load}"
    echo ${hostname}
  fi
}
download_hostname() {
  #udp ==> https://downloads.nordcdn.com/configs/files/ovpn_udp/servers/nl601.nordvpn.com.udp.ovpn
  #tcp ==> https://downloads.nordcdn.com/configs/files/ovpn_tcp/servers/nl542.nordvpn.com.tcp.ovpn
  [[ -z ${1} ]] && return || true
  local nordvpn_cdn=${nordvpn_cdn}
  #which protocol tcp or udp
  if [[ ${NORDVPN_PROTOCOL,,} == tcp ]]; then
    nordvpn_cdn="${nordvpn_cdn}/ovpn_tcp/servers/"
  else
    nordvpn_cdn="${nordvpn_cdn}/ovpn_udp/servers/"
  fi

  # default or defined server name
  nordvpn_cdn=${nordvpn_cdn}${1}
  ovpnName=${1}.ovpn

  # remote filename
  if [[ ${NORDVPN_PROTOCOL,,} == tcp ]]; then
    nordvpn_cdn="${nordvpn_cdn}.tcp.ovpn"
  else
    nordvpn_cdn="${nordvpn_cdn}.udp.ovpn"
  fi

  log "Downloading config: ${ovpnName}"
  log "Downloading from: ${nordvpn_cdn}"
  # VPN_PROVIDER_HOME defined is openvpn/start.sh
  outfile="-o "${VPN_PROVIDER_HOME}/${ovpnName}
  #when testing script outside of container, display config instead of writing it.
  if [ ! -w ${VPN_PROVIDER_HOME} ]; then
    log "${VPN_PROVIDER_HOME} is not writable, outputing to stdout"
    unset outfile
  fi
  curl -sSL ${nordvpn_cdn} ${outfile}
}

checkDNS() {
  res=$(dig +short ${nordvpn_dl})
  if [ -z "${res:-\"\"}" ]; then
    log "DNS: ERROR, no dns resolution, dns server unavailable or network problem"
  else
    log "DNS: resolution ok"
  fi
  ping -c2 ${nordvpn_dl} 2>&1 >/dev/null
  ret=$?
  if [ $ret -eq 0 ]; then
    log "PING: ok, configurations download site reachable"
  else
    log "PING: ERROR: cannot ping ${nordvpn_cdn}, network or internet unavailable. Cannot download NORDVPN configuration files"
  fi
  return $ret
}

# Main
# If the script is called from elsewhere
cd "${0%/*}"
script_init
checkDNS

log "Removing existing configs in ${VPN_PROVIDER_HOME}"
#find ${VPN_PROVIDER_HOME} -type f ! -name '*.sh' -delete

#Tests NORDVPN_<COUNTRY, PROTOCOL, CATEGORY> values
if [[ -n ${NORDVPN_TESTS:-""} ]]; then

  case ${NORDVPN_TESTS} in
  1)
    #get recommended config when no values are given, use defaults one, display a warning with possible values
    test1NoValues
    ;;
  2)
    #When no category, get recommended config, display warning with possible values
    test2NoCategory
    ;;
  3)
    #When incompatibles combinations, no recommended config is given, exit with error log.
    test3Incompatible_combinations
    ;;
  *)
    log "Warning, tests requested but not found: NORDVPN_TESTS=${NORDVPN_TESTS}"
    ;;
  esac
fi

#get server name from api (best recommended for NORDVPN_<> if defined)
selected="$(select_hostname)"

download_hostname ${selected}
export OPENVPN_CONFIG=${selected}

cd "${0%/*}"
