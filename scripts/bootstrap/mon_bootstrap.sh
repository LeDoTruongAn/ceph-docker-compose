#!/bin/bash
set -e


#######
# MON #
#######
function bootstrap_mon {
  # shellcheck disable=SC1091
  source /opt/ceph-container/bin/start_mon.sh
  start_mon
  chown --verbose ceph. /etc/ceph/*
  systemctl start ceph-"${CEPH_FSID}"@mon."${MON_NAME}"
}

