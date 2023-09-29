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