#!/usr/bin/env bash

set -e
set -x

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export PATH=/var/vcap/packages/elastalert2/bin:$PATH
export CONFIG_DIR=/var/vcap/jobs/elastalert2/config
export PYTHONPATH=/var/vcap/packages/elastalert2/lib/python3.7/site-packages/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/var/vcap/packages/python3/lib

elastalert2 --config $CONFIG_DIR/config.yaml
