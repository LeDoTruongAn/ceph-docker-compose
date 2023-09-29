#!/bin/bash
set -e
##############
# RBD MIRROR #
##############
function bootstrap_rbd_mirror {
  # start rbd-mirror
  rbd-mirror "${DAEMON_OPTS[@]}"
}
