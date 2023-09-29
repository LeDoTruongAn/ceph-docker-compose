#!/bin/bash

# We need the -m to track child process in docker_exec.sh
# It is expected to receive some SIGCHLD, so -m is mandatory
set -me
export LC_ALL=C

source /opt/ceph-container/bin/variables_entrypoint.sh
source /opt/ceph-container/bin/common_functions.sh
source /opt/ceph-container/bin/docker_exec.sh
source /opt/ceph-container/bin/debug.sh

###########################
# CONFIGURATION GENERATOR #
###########################

# Load in the bootstrapping routines
# based on the data store
case "$KV_TYPE" in
  etcd)
    # TAG: kv_type_etcd
    source /opt/ceph-container/bin/config.kv.etcd.sh
    ;;
  k8s|kubernetes)
    # TAG: kv_type_k8s
    source /opt/ceph-container/bin/config.k8s.sh
    ;;
  *)
    source /opt/ceph-container/bin/config.static.sh
    ;;
esac


###############
# CEPH_DAEMON #
###############

# Normalize DAEMON to lowercase
CEPH_DAEMON=$(to_lowercase "${CEPH_DAEMON}")

create_mandatory_directories

if [[ ! "x86_64 aarch64" =~ $CEPH_ARCH  ]] ; then
    echo "$CEPH_DAEMON is not supported on $CEPH_ARCH" >&2
    exit 1
fi

# If we are given a valid first argument, set the
# CEPH_DAEMON variable from it
case "$CEPH_DAEMON" in
  populate_kvstore)
    # TAG: populate_kvstore
    source /opt/ceph-container/bin/populate_kv.sh
    populate_kv
    ;;
  mon)
    # TAG: mon
    source /opt/ceph-container/bin/start_mon.sh
    start_mon
    chown --verbose ceph. /etc/ceph/*
    ;;
  mon_bootstrap)
    # TAG: mon_bootstrap
    source /opt/ceph-container/bin/bootstrap/mon_bootstrap.sh
    bootstrap_mon
    ;;
  osd_bootstrap)
    # TAG: osd_bootstrap
    source /opt/ceph-container/bin/bootstrap/osd_bootstrap.sh
    bootstrap_osd
    ;;
  rgw_bootstrap)
      # TAG: rgw_bootstrap
      source /opt/ceph-container/bin/bootstrap/rgw_bootstrap.sh
      build_rgw_bootstrap
      ;;
  mgr_bootstrap)
      # TAG: mgr_bootstrap
      source /opt/ceph-container/bin/bootstrap/mgr_bootstrap.sh
      bootstrap_mgr

      source /opt/ceph-container/bin/bootstrap/crash_bootstrap.sh
      bootstrap_crash
      ;;
  mds_bootstrap)
      # TAG: mds_bootstrap
      source /opt/ceph-container/bin/bootstrap/mds_bootstrap.sh
      # Run after rgw_bootstrap
      bootstrap_sree
      # Run after rgw_bootstrap
      bootstrap_mds
      ;;
  nfs_bootstrap)
      # TAG: nfs_bootstrap
      source /opt/ceph-container/bin/bootstrap/nfs_bootstrap.sh
      bootstrap_nfs
      ;;
  rbd_mirror_bootstrap)
      # TAG: rbd_mirror_bootstrap
      source /opt/ceph-container/bin/bootstrap/rbd_mirror_bootstrap.sh
      bootstrap_rbd_mirror
      ;;
  rest_api_bootstrap)
      # TAG: rest_api_bootstrap
      source /opt/ceph-container/bin/bootstrap/rest_api_bootstrap.sh
      bootstrap_rest_api
      ;;
  crash_bootstrap)
      # TAG: crash_bootstrap
      source /opt/ceph-container/bin/bootstrap/crash_bootstrap.sh
      bootstrap_crash
      ;;
  osd)
    # TAG: osd
    source /opt/ceph-container/bin/start_osd.sh
    start_osd
    ;;
  osd_directory_single)
    # TAG: osd_directory_single
    source /opt/ceph-container/bin/start_osd.sh
    OSD_TYPE="directory_single"
    start_osd
    ;;
  osd_ceph_disk)
    # TAG: osd_ceph_disk
    source /opt/ceph-container/bin/start_osd.sh
    OSD_TYPE="disk"
    start_osd
    ;;
  osd_ceph_disk_prepare)
    # TAG: osd_ceph_disk_prepare
    source /opt/ceph-container/bin/start_osd.sh
    OSD_TYPE="prepare"
    start_osd
    ;;
  osd_ceph_disk_activate)
    # TAG: osd_ceph_disk_activate
    source /opt/ceph-container/bin/start_osd.sh
    OSD_TYPE="activate"
    start_osd
    ;;
  osd_ceph_activate_journal)
    # TAG: osd_ceph_activate_journal
    source /opt/ceph-container/bin/start_osd.sh
    OSD_TYPE="activate_journal"
    start_osd
    ;;
  osd_ceph_volume_activate)
    ami_privileged
    # shellcheck disable=SC1091
    # TAG: osd_ceph_volume_activate
    source /opt/ceph-container/bin/osd_volume_activate.sh
    osd_volume_activate
    ;;
  mds)
    # TAG: mds
    source /opt/ceph-container/bin/start_mds.sh
    start_mds
    ;;
  rgw)
    # TAG: rgw
    source /opt/ceph-container/bin/start_rgw.sh
    start_rgw
    ;;
  rgw_user)
    # TAG: rgw_user
    source /opt/ceph-container/bin/start_rgw.sh
    create_rgw_user
    ;;
  rbd_mirror)
    # TAG: rbd_mirror
    source /opt/ceph-container/bin/start_rbd_mirror.sh
    start_rbd_mirror
    ;;
  nfs)
    # TAG: nfs
    source /opt/ceph-container/bin/start_nfs.sh
    start_nfs
    ;;
  zap_device)
    # TAG: zap_device
    source /opt/ceph-container/bin/zap_device.sh
    zap_device
    ;;
  mon_health)
    # TAG: mon_health
    source /opt/ceph-container/bin/watch_mon_health.sh
    watch_mon_health
    ;;
  mgr)
    # TAG: mgr
    source /opt/ceph-container/bin/start_mgr.sh
    start_mgr
    ;;
  disk_introspection)
    # TAG: disk_introspection
    if [[ "$KV_TYPE" =~ k8s|kubernetes ]]; then
      source /opt/ceph-container/bin/disk_introspection.sh
    else
      log "You can not use the disk introspection method outside a Kubernetes environment"
      log "Make sure KV_TYPE equals either k8s or kubernetes"
    fi
    ;;
  demo)
    # TAG: demo
    source /opt/ceph-container/bin/demo.sh
    ;;
  disk_list)
    # TAG: disk_list
    source /opt/ceph-container/bin/disk_list.sh
    start_disk_list
    ;;
  tcmu_runner)
    # TAG: tcmu_runner
    if is_redhat; then
      source /opt/ceph-container/bin/start_tcmu_runner.sh
      start_tcmu_runner
    else
      log "ERROR: tcmu_runner scenario is only available on Red Hat systems."
    fi
    ;;
  rbd_target_api)
    # TAG: rbd_target_api
    if is_redhat; then
      source /opt/ceph-container/bin/start_rbd_target_api.sh
      start_rbd_target_api
    else
      log "ERROR: rbd_target_api scenario is only available on Red Hat systems."
    fi
    ;;
  rbd_target_gw)
    # TAG: rbd_target_gw
    if is_redhat; then
      source /opt/ceph-container/bin/start_rbd_target_gw.sh
      start_rbd_target_gw
    else
      log "ERROR: rbd_target_gw scenario is only available on Red Hat systems."
    fi
    ;;
  *)
    invalid_ceph_daemon
    ;;
esac

exit 0
