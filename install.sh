./first_run.sh

docker-compose up -d ceph-mon ceph-mgr

#./run_cc.sh

# Create OSDs
#./create_osd.sh 3

# Create pools
#./osd_config.sh
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


#docker-compose up -d ceph-nfs ceph-mds ceph-rbd

# sudo ./run_cd.sh
