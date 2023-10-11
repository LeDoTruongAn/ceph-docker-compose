#!/bin/bash
set -e

#######
# RGW #
#######
RGW_PATH="/var/lib/ceph/radosgw/${CLUSTER}-rgw.${RGW_NAME}"
: "${RGW_ENABLE_USAGE_LOG:=true}"
: "${RGW_USAGE_MAX_USER_SHARDS:=1}"
: "${RGW_USAGE_MAX_SHARDS:=32}"
: "${RGW_USAGE_LOG_FLUSH_THRESHOLD:=1}"
: "${RGW_USAGE_LOG_TICK_INTERVAL:=1}"

# rgw options
: "${RGW_FRONTEND_IP:=0.0.0.0}}"
: "${RGW_FRONTEND_PORT:=8080}"
: "${RGW_FRONTEND_TYPE:="beast"}"

# rgw frontend options
function build_rgw_bootstrap {
  bootstrap_rgw
}

function bootstrap_rgw {
  log "Starting Ceph RGW..."
  if [[ "$RGW_FRONTEND_TYPE" == "civetweb" ]]; then
    # shellcheck disable=SC2153
    RGW_FRONTED_OPTIONS="$RGW_FRONTEND_OPTIONS port=$RGW_FRONTEND_IP:$RGW_FRONTEND_PORT"
  elif [[ "$RGW_FRONTEND_TYPE" == "beast" ]]; then
    RGW_FRONTED_OPTIONS="$RGW_FRONTEND_OPTIONS endpoint=$RGW_FRONTEND_IP:$RGW_FRONTEND_PORT port=$RGW_FRONTEND_PORT"
  else
    log "ERROR: unsupported rgw backend type $RGW_FRONTEND_TYPE"
    exit 1
  fi

  : "${RGW_FRONTEND:="$RGW_FRONTEND_TYPE $RGW_FRONTED_OPTIONS"}"

  if [ ! -e "$RGW_PATH"/keyring ]; then
    # bootstrap RGW
    mkdir -p "$RGW_PATH" /var/log/ceph
    ceph "${CLI_OPTS[@]}" auth get-or-create client.rgw."${RGW_NAME}" osd 'allow rwx' mon 'allow rw' -o "$RGW_KEYRING"
    chown --verbose -R ceph. "$RGW_PATH"

    #configure rgw dns name
    cat <<ENDHERE >>/etc/ceph/"${CLUSTER}".conf

[client.rgw.${RGW_NAME}]
rgw dns name = ${RGW_NAME}
rgw enable usage log = ${RGW_ENABLE_USAGE_LOG}
rgw usage log tick interval = ${RGW_USAGE_LOG_TICK_INTERVAL}
rgw usage log flush threshold = ${RGW_USAGE_LOG_FLUSH_THRESHOLD}
rgw usage max shards = ${RGW_USAGE_MAX_SHARDS}
rgw usage max user shards = ${RGW_USAGE_MAX_USER_SHARDS}
log file = /var/log/ceph/client.rgw.${RGW_NAME}.log
rgw frontends = ${RGW_FRONTEND}

ENDHERE
  fi

  # shellcheck disable=SC2145
  # shellcheck disable=SC2027
  log "Creating RGW user... radosgw ${DAEMON_OPTS[@]} -n client.rgw."${RGW_NAME}" -k $RGW_KEYRING"
  # start RGW
  radosgw "${DAEMON_OPTS[@]}" -n client.rgw."${RGW_NAME}" -k "$RGW_KEYRING"
  log "Ceph RGW started."
}
