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
  bootstrap_sree
  bootstrap_rgw
}

function bootstrap_rgw {
  log "Starting Ceph RGW..."
  if [[ "$RGW_FRONTEND_TYPE" == "civetweb" ]]; then
    # shellcheck disable=SC2153
    RGW_FRONTED_OPTIONS="$RGW_FRONTEND_OPTIONS port=$RGW_FRONTEND_IP:$RGW_FRONTEND_PORT"
  elif [[ "$RGW_FRONTEND_TYPE" == "beast" ]]; then
    RGW_FRONTED_OPTIONS="$RGW_FRONTEND_OPTIONS endpoint=$RGW_FRONTEND_IP:$RGW_FRONTEND_PORT"
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

function bootstrap_dashboard_user {
  log "Creating dashboard user..."
  CEPH_DASH_USER="/opt/ceph-container/tmp/ceph-${CEPH_DASH_UID}-user"
  if [ -f "$CEPH_DASH_USER" ]; then
    log "Dashboard user already exists with credentials:"
    cat "$CEPH_DASH_USER"
  else
    log "Setting up a dashboard user..."
    if [ -n "$CEPH_DASH_UID" ] && [ -n "$CEPH_DASH_ACCESS_KEY" ] && [ -n "$CEPH_DASH_SECRET_KEY" ]; then
      radosgw-admin "${CLI_OPTS[@]}" user create --uid="$CEPH_DASH_UID" --display-name="Dashboard User" --access-key="$CEPH_DASH_ACCESS_KEY" --secret-key="$CEPH_DASH_SECRET_KEY"
    else
      radosgw-admin "${CLI_OPTS[@]}" user create --uid="$CEPH_DASH_UID" --display-name="Dashboard User" > "/opt/ceph-container/tmp/${CEPH_DASH_UID}_user_details"
      # Until mimic is supported let's link the file to its original place not to break cn.
      # When mimic will be EOL, cn will only have containers having the fil in the /opt directory and so this symlink could be removed
      ln -sf /opt/ceph-container/tmp/"${CEPH_DASH_UID}_user_details" /
      CEPH_DASH_ACCESS_KEY=$(grep -Po '(?<="access_key": ")[^"]*' /opt/ceph-container/tmp/"${CEPH_DASH_UID}_user_details")
      CEPH_DASH_SECRET_KEY=$(grep -Po '(?<="secret_key": ")[^"]*' /opt/ceph-container/tmp/"${CEPH_DASH_UID}_user_details")
    fi
    sed -i s/AWS_ACCESS_KEY_PLACEHOLDER/"$CEPH_DASH_ACCESS_KEY"/ /root/.s3cfg
    sed -i s/AWS_SECRET_KEY_PLACEHOLDER/"$CEPH_DASH_SECRET_KEY"/ /root/.s3cfg
    echo "Access key: $CEPH_DASH_ACCESS_KEY" > "$CEPH_DASH_USER"
    echo "Secret key: $CEPH_DASH_SECRET_KEY" >> "$CEPH_DASH_USER"

    radosgw-admin "${CLI_OPTS[@]}" caps add --caps="buckets=*;users=*;usage=*;metadata=*" --uid="$CEPH_DASH_UID"

    # Use rgw port
    sed -i "s/host_base = localhost/host_base = ${RGW_NAME}:${RGW_FRONTEND_PORT}/" /root/.s3cfg
    sed -i "s/host_bucket = localhost/host_bucket = ${RGW_NAME}:${RGW_FRONTEND_PORT}/" /root/.s3cfg

    if [ -n "$CEPH_DASH_BUCKET" ]; then
      log "Creating bucket..."

      # Trying to create a s3cmd within 30 seconds
      timeout 30 bash -c "until s3cmd mb s3://$CEPH_DASH_BUCKET; do sleep .1; done"
    fi
  fi
  log "Dashboard user created."
}

########
# SREE #
########
function bootstrap_sree {
  SREE_DIR="/opt/ceph-container/sree"
  if [ ! -d "$SREE_DIR" ]; then
    mkdir -p "$SREE_DIR"
    tar xzvf /opt/ceph-container/tmp/sree.tar.gz -C "$SREE_DIR" --strip-components 1

    ACCESS_KEY=$(awk '/Access key/ {print $3}' /opt/ceph-container/tmp/ceph-demo-user)
    SECRET_KEY=$(awk '/Secret key/ {print $3}' /opt/ceph-container/tmp/ceph-demo-user)

    pushd "$SREE_DIR"
    sed -i "s|ENDPOINT|http://${EXPOSED_IP}:${RGW_FRONTEND_PORT}|" static/js/base.js
    sed -i "s/ACCESS_KEY/$ACCESS_KEY/" static/js/base.js
    sed -i "s/SECRET_KEY/$SECRET_KEY/" static/js/base.js
    mv sree.cfg.sample sree.cfg
    sed -i "s/RGW_CIVETWEB_PORT_VALUE/$RGW_FRONTEND_PORT/" sree.cfg
    sed -i "s/SREE_PORT_VALUE/$SREE_PORT/" sree.cfg
    popd
  fi

  # start Sree
  pushd "$SREE_DIR"
  $PYTHON app.py &
  popd
}

################
# IMPORT IN S3 #
################
function import_in_s3 {
  log "Importing $DATA_TO_SYNC in S3!"
  if [[ -d "$DATA_TO_SYNC" ]]; then
    log "Syncing $DATA_TO_SYNC in S3!"
    s3cmd mb s3://"$DATA_TO_SYNC_BUCKET"
    s3cmd sync "$DATA_TO_SYNC" s3://"$DATA_TO_SYNC_BUCKET"
  else
    log "$DATA_TO_SYNC is not a directory, nothing to do!"
  fi
}