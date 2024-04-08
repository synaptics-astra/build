#!/bin/bash

source build/header.rc
source build/chip.rc
source build/security.rc
source build/install.rc

########
# Build#
########

[ $clean -eq 1 ] && exit 0

source build/module/fw_enc/fw_list.rc
source build/module/fw_enc/common.rc

### Copy signed FW to rootfs ###
if [ ! "`ls -A ${enc_fw_path}`" = "" ]; then
  if [ "is$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT" = "isy" ]; then
    outdir_fw=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/fw
  else
    outdir_fw=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/fw
  fi
  mkdir -p ${outdir_fw}

  if [ "is${CONFIG_GENX_ENABLE}" != "isy" ]; then
     cp -adv ${enc_fw_path}/*.fw ${outdir_fw}/. || { echo "WARNING: failed on copying FW files"; }
  fi

fi
