#!/bin/bash
set -e
#######
# API #
#######
function bootstrap_rest_api {
  ceph "${CLI_OPTS[@]}" mgr module enable restful
  ceph "${CLI_OPTS[@]}" restful create-self-signed-cert
  ceph "${CLI_OPTS[@]}" restful create-key dashusr
}
