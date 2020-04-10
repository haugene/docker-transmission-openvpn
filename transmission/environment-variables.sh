#! /bin/bash

# Read values from settings.json if present
SETTINGS_FILE="${TRANSMISSION_HOME}/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    function get_setting { awk -F ": |," '/"'${1}'"/ { gsub("\"", "", $2); print $2 }' ${SETTINGS_FILE}; }
    SETTINGS_DOWNLOAD_DIR=$(get_setting "download-dir")
    SETTINGS_INCOMPLETE_DIR=$(get_setting "incomplete-dir")
    SETTINGS_PEER_PORT=$(get_setting "peer-port")
    SETTINGS_PEER_PORT_RANDOM_HIGH=$(get_setting "peer-port-random-high")
    SETTINGS_PEER_PORT_RANDOM_LOW=$(get_setting "peer-port-random-low")
    SETTINGS_PEER_PORT_RANDOM_ON_START=$(get_setting "peer-port-random-on-start")
    SETTINGS_RPC_PORT=$(get_setting "rpc-port")
    SETTINGS_WATCH_DIR=$(get_setting "watch-dir")
fi

# Ensure variables needed by openvpn are set
# Default values are set in Dockerfile if settings file wasn't read
[ -z "$TRANSMISSION_DOWNLOAD_DIR" ] &&
    export TRANSMISSION_DOWNLOAD_DIR="${SETTINGS_DOWNLOAD_DIR:-$DEFAULT_TR_DOWNLOAD_DIR}"
[ -z "$TRANSMISSION_PEER_PORT" ] &&
    export TRANSMISSION_INCOMPLETE_DIR="${SETTINGS_INCOMPLETE_DIR:-$DEFAULT_TR_INCOMPLETE_DIR}"
[ -z "$TRANSMISSION_PEER_PORT" ] &&
    export TRANSMISSION_PEER_PORT="${SETTINGS_PEER_PORT:-$DEFAULT_TR_PEER_PORT}"
[ -z "$TRANSMISSION_PEER_PORT_RANDOM_HIGH" ] &&
    export TRANSMISSION_PEER_PORT_RANDOM_HIGH="${SETTINGS_PEER_PORT_RANDOM_HIGH:-$DEFAULT_TR_PEER_PORT_RANDOM_HIGH}"
[ -z "$TRANSMISSION_PEER_PORT_RANDOM_LOW" ] &&
    export TRANSMISSION_PEER_PORT_RANDOM_LOW="${SETTINGS_PEER_PORT_RANDOM_LOW:-$DEFAULT_TR_PEER_PORT_RANDOM_LOW}"
[ -z "$TRANSMISSION_PEER_PORT_RANDOM_ON_START" ] &&
    export TRANSMISSION_PEER_PORT_RANDOM_ON_START="${SETTINGS_PEER_PORT_RANDOM_ON_START:-$DEFAULT_TR_PEER_PORT_RANDOM_ON_START}"
[ -z "$TRANSMISSION_RPC_PORT" ] &&
    export TRANSMISSION_RPC_PORT="${SETTINGS_RPC_PORT:-$DEFAULT_TR_RPC_PORT}"
[ -z "$TRANSMISSION_WATCH_DIR" ] &&
    export TRANSMISSION_WATCH_DIR="${SETTINGS_WATCH_DIR:-$DEFAULT_TR_WATCH_DIR}"
