#!/bin/bash
set -e
#######
# OSD #
#######

function parse_size {
  # Taken from https://stackoverflow.com/questions/17615881/simplest-method-to-convert-file-size-with-suffix-to-bytes
  local SUFFIXES=('' K M G T P E Z Y)
  local MULTIPLIER=1

  shopt -s nocasematch

  for SUFFIX in "${SUFFIXES[@]}"; do
    local REGEX="^([0-9]+)(${SUFFIX}i?B?)?\$"

    if [[ $1 =~ $REGEX ]]; then
      echo $((BASH_REMATCH[1] * MULTIPLIER))
      return 0
    fi

    ((MULTIPLIER *= 1024))
  done

  echo "$0: invalid size \`$1'" >&2
  return 1
}

function bootstrap_osd {
  if [[ ${OSD_BLUESTORE} -eq 1 ]]; then
    tune_memory "$(get_available_ram)"
  fi

  if [[ -n "$OSD_DEVICE" ]]; then
    if [[ -b "$OSD_DEVICE" ]]; then
      if [ -n "$BLUESTORE_BLOCK_SIZE" ]; then
        size=$(parse_size "$BLUESTORE_BLOCK_SIZE")
        if ! grep -qE "bluestore_block_size = $size" /etc/ceph/"${CLUSTER}".conf; then
          echo "bluestore_block_size = $size" >> /etc/ceph/"${CLUSTER}".conf
        fi
      fi
    else
      log "Invalid $OSD_DEVICE, only block device is supported"
      exit 1
    fi
  fi

  : "${OSD_COUNT:=1}"

  if [ -z "$OSD_ID" ]; then
    echo "OSD_ID environment variable is not set."
    exit 1
  fi

  OSD_PATH="/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}"
  OSD_PUBLIC_ADDR=${OSD_PUBLIC_ADDR:-$(hostname --ip-address)}
  OSD_CLUSTER_ADDR=${OSD_CLUSTER_ADDR:-$(hostname --ip-address)}

  OSD_HOST="${CLUSTER}-osd$((OSD_ID + 1))"
  if [ ! -e "$OSD_PATH"/keyring ]; then
    if ! grep -qE "osd objectstore = bluestore" /etc/ceph/"${CLUSTER}".conf; then
      echo "osd objectstore = bluestore" >> /etc/ceph/"${CLUSTER}".conf
    fi
    if ! grep -qE "osd data = $OSD_PATH" /etc/ceph/"${CLUSTER}".conf; then
      cat <<ENDHERE >>/etc/ceph/"${CLUSTER}".conf

[osd.${OSD_ID}]
host = ${OSD_HOST}
public_addr = ${OSD_PUBLIC_ADDR}
cluster_addr = ${OSD_CLUSTER_ADDR}
osd data = ${OSD_PATH}
osd journal = ${OSD_PATH}/journal
osd journal size = 1024

ENDHERE
    fi
    # bootstrap OSD
    mkdir -p "$OSD_PATH"
    chown --verbose -R ceph. "$OSD_PATH"

    # if $OSD_DEVICE exists we deploy with ceph-volume
    if [[ -n "$OSD_DEVICE" ]]; then
      ceph-volume lvm prepare --data "$OSD_DEVICE"
    else
      # we go for a 'manual' bootstrap
      ceph "${CLI_OPTS[@]}" auth get-or-create osd."$OSD_ID" mon 'allow profile osd' osd 'allow *' mgr 'allow profile osd' -o "$OSD_PATH"/keyring
      ceph-osd --conf /etc/ceph/"${CLUSTER}".conf --osd-data "$OSD_PATH" --mkfs -i "$OSD_ID"
    fi
  fi

  # activate OSD
  if [[ -n "$OSD_DEVICE" ]]; then
    OSD_FSID="$(ceph-volume lvm list --format json | $PYTHON -c "import sys, json; print(json.load(sys.stdin)[\"$OSD_ID\"][0][\"tags\"][\"ceph.osd_fsid\"])")"
    ceph-volume lvm activate --no-systemd --bluestore "${OSD_ID}" "${OSD_FSID}"
  fi

  # start OSD
  chown --verbose -R ceph. "$OSD_PATH"

  # Run exec /usr/bin/ceph-osd "${DAEMON_OPTS[@]}" -i "$OSD_ID"
  # to avoid ceph-osd to be stopped by SIGTERM
  if [[ ! -e /etc/systemd/system/ceph-osd.service ]]; then
    cat <<ENDHERE >/etc/systemd/system/ceph-osd.service
[Unit]
Description=Ceph cluster OSD daemon
After=network.target

[Service]
ExecStart=/usr/bin/ceph-osd ${DAEMON_OPTS[@]} -i ${OSD_ID}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

ENDHERE
    systemctl enable ceph-osd
  fi
  systemctl start ceph-osd
}
