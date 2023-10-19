#!/bin/bash
source load-env.sh
if [[ ! -e initial-ceph.conf ]]; then
           cat <<ENDHERE > initial-ceph.conf
[global]
max open files = 655350
cephx cluster require signatures = false
cephx service require signatures = false
mon_osd_allow_reclaim = false
mon_max_pg_per_osd = 800

osd journal size = 5120
osd_memory_target = 512MB
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 333
osd_crush_chooseleaf_type = 0
osd objectstore = bluestore

rgw enable usage log = true
rgw usage log tick interval = 1
rgw usage log flush threshold = 1
rgw usage max shards = 32
rgw usage max user shards = 1

ENDHERE
fi

if [[ ! -e  /etc/ceph/ceph_password.txt ]]; then
           cat <<ENDHERE >/etc/ceph/ceph_password.txt
administrator_password
ENDHERE
fi

# -- Set up Ceph Storage Cluster
cephadm bootstrap --config initial-ceph.conf  --fsid "${CEPH_FSID}" --mon-ip "${MON_IP}" --cluster-network "${CEPH_CLUSTER_NETWORK}"
# Before running this script, you must have the following files in the current directory:
sudo /usr/sbin/cephadm shell --fsid "${CEPH_FSID}" -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

# -- Set up OSDs for Ceph Storage Cluster
ceph orch device zap ceph-storage-cluster /dev/sdb --force
#ceph orch daemon add osd ceph-storage-cluster:/dev/sdb
ceph orch device zap ceph-storage-cluster /dev/sdc --force
#ceph orch daemon add osd ceph-storage-cluster:/dev/sdc
ceph orch device zap ceph-storage-cluster /dev/sdd --force
#ceph orch daemon add osd ceph-storage-cluster:/dev/sdd

ceph orch apply osd --all-available-devices

ceph osd pool create default.rgw.buckets.data 512 512
ceph osd pool application enable default.rgw.buckets.data rgw
# -- Set up RGW
ceph orch apply rgw rgw 'ceph-storage-cluster' --placement="label:_admin" --port 7480



# -- Set up MDS for CephFS
ceph fs volume create cephfs --placement="label:_admin"
ceph osd pool create cephfs_data 8
ceph osd pool create cephfs_metadata 8
ceph fs new cephfs cephfs_metadata cephfs_data
ceph orch apply mds cephfs 'ceph-storage-cluster'

# -- Set up RBD Mirroring
ceph orch apply rbd-mirror rbd-mirror --placement="label:_admin"

## Create a Ceph Dashboard user for cephadm
ceph dashboard ac-user-create cephadm -i /etc/ceph/ceph_password.txt administrator
# Create an S3 user
radosgw-admin user create --uid="${CEPH_DASH_UID}" --display-name="DashBoard User" --access-key="${CEPH_DASH_ACCESS_KEY}" --secret-key="${CEPH_DASH_SECRET_KEY}" --system
# Add capabilities to the S3 user
radosgw-admin caps add --caps="buckets=*;users=*;usage=*;metadata=*" --uid="${CEPH_DASH_UID}"

# Create an S3 bucket and sync data (assuming /etc/resources exists) - you must have the s3cmd package installed and .s3cfg file configured
 s3cmd mb s3://resources
 s3cmd sync ./resources/ s3://resources/


# Delete cluster and all data
# cephadm rm-cluster --fsid 25dfd746-6cf3-11ee-88d9-259a5997bf7b --force
