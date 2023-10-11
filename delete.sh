#!/bin/bash
docker compose down
# shellcheck disable=SC2046
docker volume rm $(docker volume ls -q | grep -v portainer_portainer-docker-extension-desktop-extension_portainer_data)
sudo rm -rf ceph_data/*
sudo rm -rf ceph_conf/*
sudo rm -rf osds/osd1/*
sudo rm -rf osds/osd2/*
sudo rm -rf osds/osd3/*
