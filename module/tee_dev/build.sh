#!/bin/bash

echo "tee_dev build called"

source build/header.rc
source build/install.rc
source build/module/tee_dev/common.rc

copy_tee_dev
copy_tee_dev_teei ${CONFIG_TEE_DEV_TEEI}
