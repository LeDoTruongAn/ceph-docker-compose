set -x
_accesskey=$(docker-compose exec ceph-mon radosgw-admin user info --uid dashusr | egrep -i access_key | cut -d ":" -f 2 | tr -d '", ')
_secretkey=$(docker-compose exec ceph-mon radosgw-admin user info --uid dashusr | egrep -i secret_key | cut -d ":" -f 2 | tr -d '", ')

# access key file and secret key file for dashboard user
rm -f ceph_conf/ceph_access_key.txt ceph_conf/ceph_secret_key.txt
echo $_accesskey | sudo tee -a ceph_conf/ceph_access_key.txt
echo $_secretkey | sudo tee -a ceph_conf/ceph_secret_key.txt
docker-compose exec ceph-mon ceph dashboard set-rgw-api-access-key -i /etc/ceph/ceph_access_key.txt
docker-compose exec ceph-mon ceph dashboard set-rgw-api-secret-key -i /etc/ceph/ceph_secret_key.txt
set +x