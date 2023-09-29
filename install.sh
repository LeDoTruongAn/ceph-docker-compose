./step_one.sh

docker-compose up -d ceph-mon ceph-mgr

./step_two.sh

# Create OSDs for RBD mirroring
docker-compose up -d ceph-osd1
docker-compose up -d ceph-osd2
docker-compose up -d ceph-osd3

# Create RGW, MDS, RBD, NFS
docker-compose up -d ceph-rgw
docker-compose up -d ceph-mds
docker-compose up -d ceph-rbd
# Create NFS
docker-compose up -d ceph-nfs

./step_three.sh
