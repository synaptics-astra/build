#!/bin/bash

source build/header.rc
source build/chip.rc
source build/security.rc
source build/install.rc

########
# Build#
########

[ $clean -eq 1 ] && exit 0

unset boot_seclvl
source build/module/ta_enc/ta_list.rc
source build/module/ta_enc/common.rc

if [ "is${CONFIG_OPTEE}" = "isy" ];then
  mkdir -p ${enc_ta_path}/optee_3rd/
  cp -advL ${product_common_path}/optee_3rd_rootcert/TA_Root_Cert.rcert ${enc_ta_path}/optee_3rd/
fi

### Copy signed TA to rootfs ###
if [ "x$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT$CONFIG_RUNTIME_RDK$CONFIG_RUNTIME_OE$CONFIG_RUNTIME_OE64" != "x" ]; then
  outdir_ta=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/ta
else
  outdir_ta=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/ta
fi
mkdir -p ${outdir_ta}

install_ta_for_kernel() {
  ### TAs install in kernel, use load_firmware
  ta_path_new=lib/firmware/ta
  kernel_ta_path=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/${ta_path_new}
  install_ta_list=('libvmeta.ta')
  install_ta_list+=('libptm.ta')
  if [ -d ${kernel_ta_path} ]; then
    for i in ${!install_ta_list[*]}; do
        ta=${install_ta_list[$i]}
        cp -adv ${enc_ta_path}/${ta}/${ta} ${kernel_ta_path}/. || { echo "WARNING: failed copying Kernel TAs"; }
    done
  fi
}

if [ "${CONFIG_PREBOOT_TEE_ENABLE}" = "y" ]; then
  cp -adv ${enc_ta_path}/*/*.ta ${outdir_ta}/. || { echo "WARNING: failed on copying TEE TA files"; }

  ## some ta load by kernel driver search different path
  install_ta_for_kernel
fi
