#!/bin/bash
source load-env.sh


set -x
# Create a config directory for your cluster.
mkdir -p ceph_conf/"${CEPH_FSID}"
# Create a data directory for your cluster.
mkdir -p ceph_data/"${CEPH_FSID}"/crash
# Create a logs directory for your cluster.
mkdir -p ceph_log/"${CEPH_FSID}"
# Create a run directory for your cluster.
mkdir -p ceph_run/"${CEPH_FSID}"

# Create a bootstrap-osd directory for your cluster.
mkdir -p osds
mkdir -p osds/osd1
mkdir -p osds/osd2
mkdir -p osds/osd3

# Create config files for your cluster.
 if [[ ! -e ceph_conf/"${CEPH_FSID}"/ceph.conf ]]; then
           cat <<ENDHERE >ceph_conf/"${CEPH_FSID}"/ceph.conf
[global]
fsid = ${CEPH_FSID}
mon initial members = ${MON_NAME}
mon host = ${MON_IP}
public network = ${CEPH_PUBLIC_NETWORK}
cluster network = ${CEPH_CLUSTER_NETWORK}
osd journal size = ${OSD_JOURNAL_SIZE}
ENDHERE
fi

set +x


