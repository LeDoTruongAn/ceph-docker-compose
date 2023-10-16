#!/bin/bash
source load-env.sh
docker compose down
# shellcheck disable=SC2046
docker volume prune -f
sudo rm -rf ceph_data/"${CEPH_FSID}"/*
sudo rm -rf ceph_conf/"${CEPH_FSID}"/*
sudo rm -rf ceph_log/"${CEPH_FSID}"/*
sudo rm -rf ceph_run/"${CEPH_FSID}"/*
