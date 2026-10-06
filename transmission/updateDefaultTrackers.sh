#!/bin/bash

# Downloads the tracker lists in DEFAULT_TRACKERS_LISTS (URLs separated by commas and/or
# whitespace) and sets them as Transmission's "default-trackers" setting.
#
# Lines that are empty, comments (#) or don't look like an announce URL are skipped,
# duplicates are dropped. Lists that fail to download are skipped with a warning.

settings="${TRANSMISSION_HOME}/settings.json"

trackers=()
declare -A seen=()

for list_url in ${DEFAULT_TRACKERS_LISTS//,/ }; do
  # On success this is the list, on failure the error message
  if ! list="$(curl --silent --show-error --fail --location --max-time 30 --retry 2 "${list_url}" 2>&1)"; then
    # On retries curl repeats the error, only show the last one
    echo "WARNING: Could not download tracker list ${list_url}, skipping it: ${list##*$'\n'}"
    continue
  fi

  count=0
  while IFS= read -r line; do
    # Strip carriage returns and surrounding whitespace
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ "${line}" =~ ^(udp|https?|wss?)://[^[:space:]]+$ ]] || continue
    [[ -n "${seen[${line}]}" ]] && continue
    seen[${line}]=1
    trackers+=("${line}")
    count=$((count + 1))
  done <<< "${list}"
  echo "Got ${count} new trackers from ${list_url}"
done

if [[ ${#trackers[@]} -eq 0 ]]; then
  echo "WARNING: No trackers could be downloaded, keeping the current default trackers"
  exit 1
fi

# Separate the trackers by a blank line, making each its own tier so all of them are used
default_trackers="$(printf '%s\n\n' "${trackers[@]}")"

# Set it through RPC, which changes only this setting; Transmission saves it to settings.json itself.
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt
rpc_auth=()
if [[ "$(jq -r '.["rpc-authentication-required"] // .rpc_authentication_required' "${settings}")" == "true" ]]; then
  rpc_auth=(--user "$(head -1 "${TRANSMISSION_PASSWD_FILE}"):$(tail -1 "${TRANSMISSION_PASSWD_FILE}")")
fi
if [[ -z "${TRANSMISSION_RPC_URL}" ]]; then
  TRANSMISSION_RPC_URL="$(jq -r '."rpc-url"' /etc/transmission/default-settings.json)"
fi
rpc_endpoint="http://localhost:${TRANSMISSION_RPC_PORT}${TRANSMISSION_RPC_URL%/}/rpc"

# Wait for transmission-daemon to be up and get the session id it requires on every request
for ((i = 0; i < 60; i++)); do
  session_id="$(curl --silent --output /dev/null --dump-header - "${rpc_auth[@]}" "${rpc_endpoint}" \
    | sed -n 's/^X-Transmission-Session-Id: *\([^[:space:]]*\).*/\1/ip')"
  [[ -n "${session_id}" ]] && break
  sleep 1
done
if [[ -z "${session_id}" ]]; then
  echo "WARNING: Could not connect to Transmission at ${rpc_endpoint}, could not update the default trackers"
  exit 1
fi

request="$(jq -n --arg trackers "${default_trackers}" '{method: "session-set", arguments: {"default-trackers": $trackers}}')"
response="$(curl --silent --show-error "${rpc_auth[@]}" --header "X-Transmission-Session-Id: ${session_id}" \
  --data "${request}" "${rpc_endpoint}" 2>&1)"
if [[ "$(jq -r '.result' <<< "${response}" 2>/dev/null)" == "success" ]]; then
  echo "Updated default trackers with ${#trackers[@]} trackers"
else
  echo "WARNING: Could not update the default trackers: ${response}"
  exit 1
fi
