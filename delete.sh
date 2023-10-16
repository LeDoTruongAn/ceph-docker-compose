#!/bin/bash
docker compose down
# shellcheck disable=SC2046
docker volume rm $(docker volume ls -q | grep -v portainer_portainer-docker-extension-desktop-extension_portainer_data)
sudo rm -rf ceph_data/*
sudo rm -rf ceph_conf/*
sudo rm -rf osds/osd1/*
sudo rm -rf osds/osd2/*
sudo rm -rf osds/osd3/*
sudo rm -rf ceph_log/*
sudo rm -rf ceph_run/*

# Delete the network if it exists already
docker network inspect ceph-host-net &> /dev/null && docker network rm ceph-host-net
