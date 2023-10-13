#!/bin/bash

# Set Ceph configuration parameters in ceph.conf
set -x
# Create an administrator password file
echo "administrator_password" > ceph_conf/ceph_password.txt

# Get the operating system type
OS=$(uname -s)

# Define the Docker Compose command based on the OS
if [ "$OS" = "Darwin" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif [ "$OS" = "Linux" ]; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

# Restart Ceph components to apply changes without health warnings
$DOCKER_COMPOSE_CMD restart ceph-mon ceph-mgr
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool create default.rgw.buckets.data 512 512
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool application enable default.rgw.buckets.data rgw
