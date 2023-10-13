#!/bin/bash
set -e
##############
# RBD MIRROR #
##############
function bootstrap_rbd_mirror {
  # Run exec /usr/bin/rbd-mirror "${DAEMON_OPTS[@]}" in background with PID 1
  if [[ ! -e /etc/systemd/system/ceph-rbd-mirror.service ]]; then
    cat <<ENDHERE >/etc/systemd/system/ceph-rbd-mirror.service
[Unit]
Description=Ceph rbd-mirror daemon
After=network.target

[Service]
ExecStart=/usr/bin/rbd-mirror ${DAEMON_OPTS[@]}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

ENDHERE
    systemctl enable ceph-rbd-mirror
  fi

  # start rbd-mirror
  systemctl start ceph-rbd-mirror
}
