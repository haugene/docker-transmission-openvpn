#!/bin/sh

SELFHEAL_INTERVAL=${SELFHEAL_INTERVAL:-30s}
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

INTERVAL=$(string_to_seconds ${SELFHEAL_INTERVAL})
TIMEOUT=$(string_to_seconds ${SELFHEAL_TIMEOUT})
START_PERIOD=$(string_to_seconds ${SELFHEAL_START_PERIOD})

RETRIES_REMAINING=${SELFHEAL_RETRIES}
CONTAINER_STATUS="starting"
START_PERIOD_END=$(echo "$(date +%s) + ${START_PERIOD}" | bc -l)
while true; do
  echo "SELFHEAL: Running health check..."
  setsid timeout ${TIMEOUT} /etc/scripts/healthcheck.sh
  STATUS=$?
  if [[ ${STATUS} -ne 0 ]]; then
    if [[ ${CONTAINER_STATUS} != "starting" ]] || [[ $(date +%s) -ge ${START_PERIOD_END} ]]; then
      let "RETRIES_REMAINING-=1"
      echo "SELFHEAL: Health check failed, ${RETRIES_REMAINING} retries remaining"
    else
      echo "SELFHEAL: Health check failed"
    fi
  else
    RETRIES_REMAINING=${SELFHEAL_RETRIES}
    CONTAINER_STATUS="healthy"
    echo "SELFHEAL: Health check succeeded"
  fi
  if [[ ${RETRIES_REMAINING} -eq 0 ]]; then
    CONTAINER_STATUS="unhealthy"
  fi
  echo "SELFHEAL: Container is ${CONTAINER_STATUS}"
  if [[ ${CONTAINER_STATUS} == "unhealthy" ]]; then
    echo "SELFHEAL: Failed ${SELFHEAL_RETRIES} health checks, exiting..."
    #kill 1
    exit 1
  fi
  echo "SELFHEAL: Waiting for ${SELFHEAL_INTERVAL}..."
  sleep ${INTERVAL}
done
