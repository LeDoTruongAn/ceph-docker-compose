#!/bin/bash
set -e
#######
# MGR #
#######
# shellcheck disable=SC2153
MGR_PATH="/var/lib/ceph/mgr/${CLUSTER}-$MGR_NAME"

function bootstrap_mgr {
  mkdir -p "$MGR_PATH"
  ceph "${CLI_OPTS[@]}" auth get-or-create mgr."$MGR_NAME" mon 'allow profile mgr' mds 'allow *' osd 'allow *' -o "$MGR_PATH"/keyring
  chown --verbose -R ceph. "$MGR_PATH"

  # start ceph-mgr
# Run ceph-mgr with the same name as the container by using the systemd unit template
   if [[ ! -e /etc/systemd/system/ceph-mgr.service ]]; then
            cat <<ENDHERE >/etc/systemd/system/ceph-mgr.service
[Unit]
Description=Ceph cluster manager daemon
After=network.target

[Service]
ExecStart=/usr/bin/ceph-mgr ${DAEMON_OPTS[@]} -i ${MGR_NAME} --mgr-data $MGR_PATH
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

ENDHERE
    systemctl enable ceph-mgr
    fi
  systemctl start ceph-mgr
}
