#!/bin/bash

source /etc/openvpn/utils.sh
SELFHEAL_INTERVAL=${SELFHEAL_INTERVAL:-1m}
SELFHEAL_TIMEOUT=${SELFHEAL_TIMEOUT:-30s}
SELFHEAL_START_PERIOD=${SELFHEAL_START_PERIOD:-0s}
SELFHEAL_RETRIES=${SELFHEAL_RETRIES:-3}

string_to_seconds() {
  local STRING=$1
  local LENGTH=${#STRING}
  case ${STRING} in
    *ms) echo "${STRING:0:$((LENGTH - 2))} / 1000" | bc -l ;;
     *s) echo "${STRING:0:$((LENGTH - 1))}" ;;
     *m) echo "$((${STRING:0:$((LENGTH - 1))} * 60))" ;;
     *h) echo "$((${STRING:0:$((LENGTH - 1))} * 3600))" ;;
  esac
}

INTERVAL=$(string_to_seconds 1m)
TIMEOUT=$(string_to_seconds 1m)
START_PERIOD=$(string_to_seconds ${SELFHEAL_START_PERIOD})
RETRIES_REMAINING=2
CONTAINER_STATUS="starting"
START_PERIOD_END=$(echo "$(date +%s) + ${START_PERIOD}" | bc -l)

echo "SELFHEAL: Container is starting, waiting for it to become healthy..."
while true; do
  sleep ${INTERVAL}
  MESSAGE=""
  timeout ${TIMEOUT} setsid /etc/scripts/healthcheck.sh > /dev/null
  STATUS=$?
  if [[ ${STATUS} -ne 0 ]]; then
    if [[ $(date +%s) -ge ${START_PERIOD_END} ]]; then
      MESSAGE="failure"
      let "RETRIES_REMAINING-=1"
    fi
  else
    if [[ ${CONTAINER_STATUS} == "starting" ]]; then
      INTERVAL=$(string_to_seconds ${SELFHEAL_INTERVAL})
      TIMEOUT=$(string_to_seconds ${SELFHEAL_TIMEOUT})
      START_PERIOD_END=$(date +%s)
    fi
    if [[ ${CONTAINER_STATUS} != "healthy" ]]; then
      MESSAGE="success"
    fi
    RETRIES_REMAINING=${SELFHEAL_RETRIES}
    CONTAINER_STATUS="healthy"
  fi
  if [[ ${RETRIES_REMAINING} -eq 0 ]]; then
    MESSAGE="restart"
    CONTAINER_STATUS="unhealthy"
  fi
  case ${MESSAGE} in
    success) echo "SELFHEAL: Container is ${CONTAINER_STATUS}, health check succeeded." ;;
    failure) echo "SELFHEAL: Container is ${CONTAINER_STATUS}, health check failed, ${RETRIES_REMAINING} retries remaining." ;;
    restart) echo "SELFHEAL: Container is ${CONTAINER_STATUS}, failed ${SELFHEAL_RETRIES} health checks, exiting..."; kill 1; exit 1 ;;
  esac
done
