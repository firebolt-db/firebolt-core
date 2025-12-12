#!/bin/bash
# Memlock setup sidecar script
# This script adjusts memlock limits for the Core container process.
# It is unnecessary if the Kubernetes nodes already have a properly configured
# memlock limit.
#

PID_FILE="/firebolt-core/volume/entrypoint-$POD_UID.pid"
CORE_PID=""

function wait_for_core_pid() {
  local DELAY="$1"
  echo "[Setup] waiting for Core entrypoint PID" 1>&2
  while sleep $DELAY; do
    if [ ! -f "$PID_FILE" ]; then
      # file not yet created by main container
      echo -n .
      continue
    fi
    # PID file can disappear any moment
    if ! PID_MT=$(stat -c %Y "$PID_FILE"); then
      echo "[Setup] file deleted by main container while attempting stat" 1>&2
      continue
    fi
    NOW=$(date +%s)
    AGE=$[NOW - PID_MT]
    if [ $AGE -gt 60 ]; then
      echo "[Setup] Core PID is $CORE_PID, but it it is older than 1 minute, ignoring until Core container rewrites it" 1>&2
      continue
    fi
    if ! CORE_PID="$(< $PID_FILE)"; then
      echo "[Setup] file deleted by main container while attempting read" 1>&2
      continue
    fi
    if [ -z "$CORE_PID" ]; then
      echo "[Setup] partial write results in reading of an empty file" 1>&2
      continue
    fi

    if [ -d /proc/$CORE_PID ]; then
      # process exists
      break
    fi

    echo "[Setup] Core PID is $CORE_PID, but it was not found under /proc; perhaps it was killed or there is a problem with shareProcessNamespace" 1>&2
    return 2
  done
  echo "[Setup] Core PID is $CORE_PID" 1>&2

  return 0
}

REQUIRED_MEMLOCK_BYTES=8589934592 # 8GB
function get_memlock_limit() {
  cat /proc/self/limits | grep -F 'Max locked memory' | awk '{print $4}'
}

function needs_memlock_setup() {
  # Expected: 'unlimited' or a number in bytes.
  local CURRENT_MEMLOCK_VALUE=$(get_memlock_limit)

  if [ "$CURRENT_MEMLOCK_VALUE" = "unlimited" ]; then
    return 1
  fi
  if [ "$CURRENT_MEMLOCK_VALUE" -ge "$REQUIRED_MEMLOCK_BYTES" ]; then
    return 1
  fi

  # memlock setup is necessary
  return 0
}

function adjust_memlock() {
  local CORE_PID="$1"
  # Expected: 'unlimited' or a number in bytes.
  local CURRENT_MEMLOCK_VALUE=$(get_memlock_limit)
  echo "[Setup] current soft memlock limit: $CURRENT_MEMLOCK_VALUE" 1>&2

  if [ "$CURRENT_MEMLOCK_VALUE" = "unlimited" ]; then
    echo "[Setup] current memlock limit is 'unlimited'. No change needed." 1>&2
    return 0
  fi

  if [ "$CURRENT_MEMLOCK_VALUE" -ge "$REQUIRED_MEMLOCK_BYTES" ]; then
    echo "[Setup] current memlock limit ($CURRENT_MEMLOCK_VALUE bytes) is already sufficient (>= 8GB). No change needed." 1>&2
    return 0
  fi

  echo "[Setup] current limit ($CURRENT_MEMLOCK_VALUE bytes) is below required 8GB, setting a higher limit" 1>&2

  if prlimit --pid $CORE_PID --memlock=$REQUIRED_MEMLOCK_BYTES:$REQUIRED_MEMLOCK_BYTES; then
    echo "[Setup] successfully set memlock limit for PID $CORE_PID" 1>&2
    return 0
  fi

  echo "[Setup] failed to set memlock prlimit. Check capabilities or node configuration." 1>&2
  return 1
}

# this check is valid because both containers will have the same limits
if ! needs_memlock_setup; then
  echo "[Setup] memlock setup not required, will be idle" 1>&2
  exec tail -f /dev/null
fi

# NOTE: this is an infinite loop because Core container can be restarted independently
DELAY=0.2
while true; do
  wait_for_core_pid $DELAY
  adjust_memlock $CORE_PID

  # wait for PID file to disappear; it is deleted by the Core container once Core starts running, or exits
  echo "[Setup] waiting for PID file to be deleted" 1>&2
  while [ -f "$PID_FILE" ]; do
    sleep 0.2
  done
  # wait a bit longer after initial setup
  DELAY=1
done
