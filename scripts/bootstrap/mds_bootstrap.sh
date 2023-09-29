#!/bin/bash
set -e
#######
# MDS #
#######
# the following ceph version can start with a numerical value where the new ones need a proper name
MDS_NAME=laggybear
MDS_PATH="/var/lib/ceph/mds/${CLUSTER}-$MDS_NAME"

function bootstrap_mds {
  if [ ! -e "$MDS_PATH"/keyring ]; then
    # create ceph filesystem
    ceph "${CLI_OPTS[@]}" osd pool create cephfs_data 8
    ceph "${CLI_OPTS[@]}" osd pool create cephfs_metadata 8
    ceph "${CLI_OPTS[@]}" fs new cephfs cephfs_metadata cephfs_data

    # bootstrap MDS
    mkdir -p "$MDS_PATH"
    ceph "${CLI_OPTS[@]}" auth get-or-create mds."$MDS_NAME" mds 'allow *' osd 'allow *' mon 'profile mds' mgr 'profile mds' -o "$MDS_PATH"/keyring
    chown --verbose -R ceph. "$MDS_PATH"
  fi

  # start MDS
  ceph-mds "${DAEMON_OPTS[@]}" -i "$MDS_NAME"
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
