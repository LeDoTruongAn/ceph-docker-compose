#!/bin/bash
set -e
#########
# CRASH #
#########
function bootstrap_crash {
  CRASH_NAME="client.crash"
  mkdir -p /var/lib/ceph/crash/posted
  ceph "${CLI_OPTS[@]}" auth get-or-create "${CRASH_NAME}" mon 'profile crash' mgr 'profile crash' -o /etc/ceph/"${CLUSTER}"."${CRASH_NAME}".keyring
  chown --verbose -R ceph. /etc/ceph/"${CLUSTER}"."${CRASH_NAME}".keyring /var/lib/ceph/crash

  # start ceph-crash
  nohup ceph-crash -n "${CRASH_NAME}" &
}
