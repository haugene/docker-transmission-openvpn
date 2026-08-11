#!/bin/bash

source /etc/openvpn/utils.sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# This script will be called with OpenVPN environment variables
# See https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/#scripting-and-environmental-variables
echo "Up script executed with device=$dev ifconfig_local=$ifconfig_local"
if [[ "$ifconfig_local" = "" ]]; then
  echo "ERROR, unable to obtain tunnel address"
  echo "killing $PPID"
  kill -9 $PPID
  exit 1
fi

# Re-create `--up` command arguments to maintain compatibility with old user scripts
USER_SCRIPT_ARGS=("$dev" "$tun_mtu" "$link_mtu" "$ifconfig_local" "$ifconfig_remote" "$script_context")

# If transmission-pre-start.sh exists, run it
if [[ -x /scripts/transmission-pre-start.sh ]]; then
  echo "Executing /scripts/transmission-pre-start.sh"
  /scripts/transmission-pre-start.sh "${USER_SCRIPT_ARGS[@]}"
  echo "/scripts/transmission-pre-start.sh returned $?"
fi

echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $dev : $ifconfig_local"
export TRANSMISSION_BIND_ADDRESS_IPV4=$ifconfig_local
# Also update the persisted settings in case it is already set. First remove any old value, then add new.
sed -i '/TRANSMISSION_BIND_ADDRESS_IPV4/d' /etc/transmission/environment-variables.sh
echo "export TRANSMISSION_BIND_ADDRESS_IPV4=$ifconfig_local" >>/etc/transmission/environment-variables.sh

if [[ "combustion" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Combustion UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/combustion-release
fi

if [[ "kettu" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Kettu UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/kettu
fi

if [[ "transmission-web-control" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Transmission Web Control UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/transmission-web-control
fi

if [[ "flood-for-transmission" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Flood for Transmission UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/flood-for-transmission
fi

if [[ "shift" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Shift UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/shift
fi

if [[ "transmissionic" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using Transmissionic UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/transmissionic
fi

if [[ "trguing" = "$TRANSMISSION_WEB_UI" ]]; then
  echo "Using TrguiNG UI, overriding TRANSMISSION_WEB_HOME"
  export TRANSMISSION_WEB_HOME=/opt/transmission-ui/trguing
fi

case ${TRANSMISSION_LOG_LEVEL,,} in
  "trace" | "debug" | "info" | "warn" | "error" | "critical")
    echo "Will exec Transmission with '--log-level=${TRANSMISSION_LOG_LEVEL,,}' argument"
    export TRANSMISSION_LOGGING="--log-level=${TRANSMISSION_LOG_LEVEL,,}"
    ;;
  *)
    export TRANSMISSION_LOGGING=""
    ;;
esac

. /etc/transmission/userSetup.sh

echo "Updating Transmission settings.json with values from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
python3 /etc/transmission/updateSettings.py /etc/transmission/default-settings.json ${TRANSMISSION_HOME}/settings.json || exit 1

echo "sed'ing True to true"
sed -i 's/True/true/g' ${TRANSMISSION_HOME}/settings.json

if [[ ! -e "/dev/random" ]]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

if [[ "true" = "$DROP_DEFAULT_ROUTE" ]]; then
    echo "DROPPING DEFAULT ROUTE"
    # Remove the original default route to avoid leaks.
    /sbin/ip route del default via "${route_net_gateway}" || exit 1
fi

if [[ "true" = "$LOG_TO_STDOUT" ]]; then
  LOGFILE=/dev/stdout
else
  LOGFILE=${TRANSMISSION_HOME}/transmission.log
fi

# Raise the open-files limit (RLIMIT_NOFILE) for transmission-daemon.
# transmission keeps one fd per peer (peer-limit-global, default 240) plus data,
# resume and log files; the default 1024 soft limit causes intermittent
# "Unable to save resume file: Too many open files" errors. The `su` below resets
# the soft limit back to 1024 even when the hard limit is large, so the limit MUST
# be raised inside the su shell.
# OPEN_FILES_LIMIT ends up interpolated into the `bash -c` string below, so refuse
# anything that isn't a plain number and fall back to the default instead.
if [[ -n "${OPEN_FILES_LIMIT}" && ! "${OPEN_FILES_LIMIT}" =~ ^[0-9]+$ ]]; then
  echo "WARNING: OPEN_FILES_LIMIT '${OPEN_FILES_LIMIT}' is not a number, ignoring it."
  OPEN_FILES_LIMIT=""
fi

if [[ -z "${OPEN_FILES_LIMIT}" ]]; then
  # Default to the hard limit, which the unprivileged RUN_AS user can reach without
  # extra privileges. It may be reported as "unlimited", but transmission can't use
  # an infinite nofile - the kernel caps it at fs.nr_open - so fall back to that.
  OPEN_FILES_LIMIT="$(ulimit -Hn)"
  if [[ "${OPEN_FILES_LIMIT}" == "unlimited" ]]; then
    OPEN_FILES_LIMIT="$(cat /proc/sys/fs/nr_open 2>/dev/null || echo 1048576)"
  fi
fi
echo "Setting transmission open-files (nofile) soft limit to ${OPEN_FILES_LIMIT}"

# Build the transmission-daemon command as an array. It is run as RUN_AS via su,
# which resets the nofile soft limit, so we raise it again inside the su shell.
# Only the soft limit (-S): that shell is already unprivileged, so it can never raise
# the hard limit anyway, while a bare `ulimit -n` would _lower_ the hard limit to match
# - irreversibly, and inherited by everything transmission spawns.
# ${transmission_cmd[*]@Q} safely quotes each argument for the `bash -c` string.
transmission_cmd=("/usr/bin/transmission-daemon")
[[ -n "${TRANSMISSION_LOGGING}" ]] && transmission_cmd+=("${TRANSMISSION_LOGGING}")
transmission_cmd+=("-g" "${TRANSMISSION_HOME}" "--logfile" "${LOGFILE}")

echo "STARTING TRANSMISSION" "command line:" "${transmission_cmd[*]@Q}"

exec su --preserve-environment "${RUN_AS}" -s /bin/bash \
  -c "ulimit -S -n ${OPEN_FILES_LIMIT}; exec ${transmission_cmd[*]@Q}" &

# Configure port forwarding if applicable
if [[ -f /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh && (-z $DISABLE_PORT_UPDATER || "false" = "$DISABLE_PORT_UPDATER") ]]; then
  echo "Provider ${OPENVPN_PROVIDER^^} has a script for automatic port forwarding. Will run it now."
  echo "If you want to disable this, set environment variable DISABLE_PORT_UPDATER=true"
  exec /etc/openvpn/${OPENVPN_PROVIDER,,}/update-port.sh &
fi

# If transmission-post-start.sh exists, run it
if [[ -x /scripts/transmission-post-start.sh ]]; then
  echo "Executing /scripts/transmission-post-start.sh"
  /scripts/transmission-post-start.sh "${USER_SCRIPT_ARGS[@]}"
  echo "/scripts/transmission-post-start.sh returned $?"
fi

echo "Transmission startup script complete."
