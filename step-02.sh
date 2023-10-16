#!/bin/bash

# Set Ceph configuration parameters in ceph.conf
set -x
source load-env.sh
# Create an administrator password file
echo "administrator_password" > ceph_conf/"${CEPH_FSID}"/ceph_password.txt

# Restart Ceph components to apply changes without health warnings
$DOCKER_COMPOSE_CMD restart ceph-mon ceph-mgr
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool create default.rgw.buckets.data 512 512
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool application enable default.rgw.buckets.data rgw

set +x
