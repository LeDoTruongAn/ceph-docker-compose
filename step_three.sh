set -x

docker-compose exec ceph-mon ceph mgr module enable dashboard
docker-compose exec ceph-mon ceph dashboard create-self-signed-cert
docker-compose exec ceph-mon ceph config set mgr mgr/dashboard/server_addr ceph-mgr
docker-compose exec ceph-mon ceph config set mgr mgr/dashboard/server_port 8443
docker-compose exec ceph-mon ceph mgr services

#password file
rm -f ceph_conf/ceph_password.txt
echo "administrator" | sudo tee -a  ceph_conf/ceph_password.txt
docker-compose exec ceph-mon ceph dashboard ac-user-create admin -i /etc/ceph/ceph_password.txt administrator

docker-compose exec ceph-mon radosgw-admin user create --uid=dashusr --display-name="DashBoard User" --access-key="70VkRWd3IHDxEafKZFX9" --secret-key="v0GerzwTw0cD2Dcq4m0aGeNzQVnpyzc0zW4Mc05A" --system
docker-compose exec ceph-mon radosgw-admin caps add --caps="buckets=*;users=*;usage=*;metadata=*" --uid=dashusr


# disable
docker-compose exec ceph-mon ceph config set mon mon_warn_on_insecure_global_id_reclaim_allowed false
docker-compose exec ceph-mon ceph config set mon auth_expose_insecure_global_id_reclaim false

docker-compose exec ceph-mon s3cmd mb s3://tvs-media
docker-compose exec ceph-mon s3cmd sync /etc/tvs-media/ s3://tvs-media/

set +x
