#for one copy, size 1
set -x
echo "max open files = 655350" | sudo tee -a  ceph_conf/ceph.conf
echo "cephx cluster require signatures = false" | sudo tee -a ceph_conf/ceph.conf
echo "cephx service require signatures = false" | sudo tee -a ceph_conf/ceph.conf
echo "mon_osd_allow_reclaim = false" | sudo tee -a  ceph_conf/ceph.conf

# for one copy, size 1`
#must be for osd run
echo "osd_pool_default_size = 3" | sudo tee -a  ceph_conf/ceph.conf
echo "osd_pool_default_min_size = 2" | sudo tee -a  ceph_conf/ceph.conf
echo "osd_pool_default_pg_num = 333" | sudo tee -a  ceph_conf/ceph.conf
echo "osd_crush_chooseleaf_type = 1" | sudo tee -a  ceph_conf/ceph.conf

echo "[osd]" | sudo tee -a ceph_conf/ceph.conf
echo "osd_journal_size = 5120" | sudo tee -a ceph_conf/ceph.conf

set +x

#must be for non health warning
docker-compose exec ceph-mon ceph osd pool create default.rgw.buckets.data 512 512
