#!/bin/bash
set -e
#######
# NFS #
#######
function bootstrap_nfs {
  # dbus
  mkdir -p /run/dbus
  dbus-daemon --system || return 0

  # Init RPC
  rpcbind || return 0
  rpc.statd -L || return 0

  cat <<ENDHERE >/etc/ganesha/ganesha.conf
EXPORT
{
        Export_id=20134;
        Path = "/";
        Pseudo = /cephobject;
        Access_Type = RW;
        Protocols = 3,4;
        Transports = TCP;
        SecType = sys;
        Squash = Root_Squash;
        FSAL {
                Name = RGW;
                User_Id = "${CEPH_DASH_UID}";
                Access_Key_Id ="${CEPH_DASH_ACCESS_KEY}";
                Secret_Access_Key = "${CEPH_DASH_SECRET_KEY}";
        }
}

RGW {
        ceph_conf = "/etc/ceph/${CLUSTER}.conf";
        cluster = "${CLUSTER}";
        name = "client.rgw.${RGW_NAME}";
}
ENDHERE

  # start ganesha
  mkdir -p /var/run/ganesha
  ganesha.nfsd "${GANESHA_OPTIONS[@]}" -L STDOUT "${GANESHA_EPOCH}"
}