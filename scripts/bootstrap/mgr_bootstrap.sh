#!/bin/bash
set -e
#######
# MGR #
#######
# shellcheck disable=SC2153
MGR_PATH="/var/lib/ceph/mgr/${CLUSTER}-$MGR_NAME"

function bootstrap_mgr {
  mkdir -p "$MGR_PATH"
  ceph "${CLI_OPTS[@]}" auth get-or-create mgr."$MGR_NAME" mon 'allow profile mgr' mds 'allow *' osd 'allow *' -o "$MGR_PATH"/keyring
  chown --verbose -R ceph. "$MGR_PATH"

  # start ceph-mgr
  ceph-mgr "${DAEMON_OPTS[@]}" -i "$MGR_NAME"
}