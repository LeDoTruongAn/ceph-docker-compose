#!/bin/bash

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

# Enable Ceph Dashboard
$DOCKER_COMPOSE_CMD exec ceph-mon ceph mgr module enable dashboard

# Create a self-signed certificate for the dashboard
$DOCKER_COMPOSE_CMD exec ceph-mon ceph dashboard create-self-signed-cert

# Set Ceph Dashboard server address and port
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mgr mgr/dashboard/server_addr ceph-mgr
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mgr mgr/dashboard/server_port 8443

# Enable Ceph Manager services
$DOCKER_COMPOSE_CMD exec ceph-mon ceph mgr services

# Create an admin user for the Ceph Dashboard
$DOCKER_COMPOSE_CMD exec ceph-mon ceph dashboard ac-user-create admin -i /etc/ceph/ceph_password.txt administrator

# Create an S3 user
$DOCKER_COMPOSE_CMD exec ceph-mon radosgw-admin user create --uid=dashusr --display-name="DashBoard User" --access-key="70VkRWd3IHDxEafKZFX9" --secret-key="v0GerzwTw0cD2Dcq4m0aGeNzQVnpyzc0zW4Mc05A" --system

# Add capabilities to the S3 user
$DOCKER_COMPOSE_CMD exec ceph-mon radosgw-admin caps add --caps="buckets=*;users=*;usage=*;metadata=*" --uid=dashusr

# Disable certain Ceph configuration settings
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mon mon_warn_on_insecure_global_id_reclaim_allowed false
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mon auth_expose_insecure_global_id_reclaim false

# Create an S3 bucket and sync data (assuming /etc/resources exists)
$DOCKER_COMPOSE_CMD exec ceph-mon s3cmd mb s3://resources
$DOCKER_COMPOSE_CMD exec ceph-mon s3cmd sync /etc/resources/ s3://resources/

## Enable Ceph Manager cephadm module
$DOCKER_COMPOSE_CMD exec ceph-mon ceph mgr module enable cephadm
## Enable Ceph Manager prometheus module
$DOCKER_COMPOSE_CMD exec ceph-mon ceph mgr module enable prometheus
## Create a Ceph Dashboard user for cephadm
$DOCKER_COMPOSE_CMD exec ceph-mon ceph dashboard ac-user-create cephadm -i /etc/ceph/ceph_password.txt administrator
#
## Set the Ceph orchestrator backend to cephadm
$DOCKER_COMPOSE_CMD exec ceph-mon ceph orch set backend cephadm

#
## Generate SSH keys for cephadm
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config-key set mgr/cephadm/ssh_identity_key -i /etc/ssh/ssh_host_rsa_key
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config-key set mgr/cephadm/ssh_identity_pub -i /etc/ssh/ssh_host_rsa_key.pub
$DOCKER_COMPOSE_CMD exec ceph-mon ceph mgr fail
