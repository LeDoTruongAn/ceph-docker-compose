# My Ceph Deployment

This repository contains a series of scripts to set up a Ceph cluster using Docker Compose. The deployment is divided into three main steps:

> ⚠️ **Warning: This setup is intended for development purposes and is not suitable for cephadm deployments in a production environment. Please use with caution and adapt it according to your specific use case.**

## Step 1: Set up Monitors and Managers

```shell
./step-01.sh

# Start Ceph Monitors and Managers
docker compose up -d ceph-mon ceph-mgr

# Bootstrap Monitors and Managers
docker compose exec ceph-mon /opt/ceph-container/bin/entrypoint.sh mon_bootstrap
docker compose exec ceph-mgr /opt/ceph-container/bin/entrypoint.sh mgr_bootstrap
```

## Step 2: Create OSDs, RGW, MDS, RBD, and NFS (Optional)

```shell
./step-02.sh

# Create OSDs for RBD mirroring
docker compose up -d ceph-osd1 ceph-osd2 ceph-osd3

# Bootstrap OSDs
docker compose exec ceph-osd1 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap
docker compose exec ceph-osd2 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap
docker compose exec ceph-osd3 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap

# Create RGW, MDS, RBD
docker compose up -d ceph-rgw ceph-mds ceph-rbd

# Bootstrap RGW, MDS, and RBD
docker compose exec ceph-rgw /opt/ceph-container/bin/entrypoint.sh rgw_bootstrap
docker compose exec ceph-mds /opt/ceph-container/bin/entrypoint.sh mds_bootstrap
docker compose exec ceph-rbd /opt/ceph-container/bin/entrypoint.sh rbd_mirror_bootstrap
```

## Step 3: Additional Configuration (if needed)

```shell
./step-03.sh
```
