#!/bin/bash
source load-env.sh

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
$DOCKER_COMPOSE_CMD exec ceph-mon radosgw-admin user create --uid="${CEPH_DASH_UID}" --display-name="DashBoard User" --access-key="${CEPH_DASH_ACCESS_KEY}" --secret-key="${CEPH_DASH_SECRET_KEY}" --system

# Add capabilities to the S3 user
$DOCKER_COMPOSE_CMD exec ceph-mon radosgw-admin caps add --caps="buckets=*;users=*;usage=*;metadata=*" --uid="${CEPH_DASH_UID}"

# Disable certain Ceph configuration settings
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mon mon_warn_on_insecure_global_id_reclaim_allowed false
$DOCKER_COMPOSE_CMD exec ceph-mon ceph config set mon auth_expose_insecure_global_id_reclaim false

# Create an S3 bucket and sync data (assuming /etc/resources exists)
$DOCKER_COMPOSE_CMD exec ceph-mon s3cmd mb s3://resources
$DOCKER_COMPOSE_CMD exec ceph-mon s3cmd sync /etc/resources/ s3://resources/
