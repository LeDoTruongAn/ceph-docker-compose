./step_one.sh

docker compose up -d ceph-mon ceph-mgr

./step_two.sh


docker compose exec ceph-mon /opt/ceph-container/bin/entrypoint.sh mon_bootstrap
docker compose exec ceph-mgr /opt/ceph-container/bin/entrypoint.sh mgr_bootstrap


#docker-compose exec ceph-mon-container /usr/bin/ceph-mon


# Create OSDs for RBD mirroring
docker compose up -d ceph-osd1 ceph-osd2 ceph-osd3

# Run bootstrap script for OSDs
docker compose exec ceph-osd1 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap
docker compose exec ceph-osd2 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap
docker compose exec ceph-osd3 /opt/ceph-container/bin/entrypoint.sh osd_bootstrap


# Create RGW, MDS, RBD, NFS
docker compose up -d ceph-rgw ceph-mds ceph-rbd

# Run bootstrap script for RGW, MDS, RBD
docker compose exec ceph-rgw /opt/ceph-container/bin/entrypoint.sh rgw_bootstrap

docker compose exec ceph-mds /opt/ceph-container/bin/entrypoint.sh mds_bootstrap

docker compose exec ceph-rbd /opt/ceph-container/bin/entrypoint.sh rbd_mirror_bootstrap

# Create NFS - Optional
# docker-compose up -d ceph-nfs

./step_three.sh


docker compose restart ceph-mon ceph-mgr ceph-osd1 ceph-osd2 ceph-osd3 ceph-rgw ceph-mds ceph-rbd

docker compose exec ceph-mon ceph orch host add ceph-mon 192.168.55.2
