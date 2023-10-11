#!/bin/bash
set -e


#######
# MON #
#######
function bootstrap_mon {
  # shellcheck disable=SC1091
  source /opt/ceph-container/bin/start_mon.sh
  start_mon
   if [ -z "$MON_ID" ]; then
      echo "MON_ID environment variable is not set."
      exit 1
    fi

    MON_IP=${MON_IP:-$(hostname --ip-address)}
  #  MON_HOST="${CLUSTER}-mon$((MON_ID + 1))"
    MON_HOST="${CLUSTER}-mon" # this should be the same as the hostname of the container but we have only
    if ! grep -qE "mon addr = $MON_IP" /etc/ceph/"${CLUSTER}".conf; then
          cat <<ENDHERE >>/etc/ceph/"${CLUSTER}".conf
[mon.${MON_ID}]
host = ${MON_HOST}
mon addr = ${MON_IP}
ENDHERE
fi
  chown --verbose ceph. /etc/ceph/*
}

