#!/bin/bash

echo "tee build script called"
source build/header.rc
source build/chip.rc
source build/security.rc
source build/install.rc

if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
  source build/module/toolchain/${CONFIG_TOOLCHAIN_APPLICATION}.rc
  opt_build_sysroot="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_SYSYROOT}"
  out_dir_rootfs="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}"
  opt_bindir_host="${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/"
fi

module_topdir=${topdir}/tee/tee
module_build_topdir=${topdir}/build/module/tee

opt_tzk_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_TEE_KERNEL_REL_PATH}
opt_outdir_intermediate=${opt_tzk_outdir_release}/intermediate
opt_client_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_TEE_CLIENT_REL_PATH}
opt_client_outdir_intermediate=${opt_client_outdir_release}/intermediate

product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}

tz_memlayout=${CONFIG_TZK_MEM_LAYOUT}
syna_chip_mid=${CONFIG_PREBOOT_MARKET_ID}
opt_genx_enable=${CONFIG_GENX_ENABLE}

### 1. v1: tz team release clear binary. tz.bin
### 2. v2: tz team release encrypted binaries. tz1_en.bin, tz2_en.bin
tz_rel_ver=1

if [ "is${CONFIG_OPTEE}" = "isy" ]; then
	TEE_CLIENT="optee_client"
	TEE_CLIENT_BUILD_DIR="${topdir}/tee/optee_dev/optee_client"
	TEE_DAEMON="${opt_build_sysroot}/usr/sbin/tee-supplicant"
else
	TEE_CLIENT="client"
	TEE_CLIENT_BUILD_DIR="${module_topdir}/tee/client_api/build"
	TEE_DAEMON="${module_topdir}/tee/bin/tee_daemon"
fi
### step 1: client lib ###
if [ x${CONFIG_RUNTIME_OE}${CONFIG_RUNTIME_OE64}${CONFIG_RUNTIME_RDK}${CONFIG_RDK_SYS} = x ]; then
  if [ $clean -eq 1 ]; then
    make -C ${TEE_CLIENT_BUILD_DIR} clean
    exit 0
  fi

  source ${module_build_topdir}/script/${TEE_CLIENT}.rc

  # install to rootfs
  mkdir -p ${out_dir_rootfs}/usr/lib
  cp -av ${opt_client_outdir_intermediate}/libteec.* ${out_dir_rootfs}/usr/lib/
  cp -av ${opt_client_outdir_intermediate}/libteec.* ${opt_build_sysroot}/usr/lib/
elif [ x${CONFIG_RDK_SYS} = x ];then
  if [ $clean -eq 1 ]; then
    [ -d ${module_topdir}/builddir ] && rm -rf ${module_topdir}/builddir
    exit 0
  fi
  environment_setup=${topdir}/toolchain/oe/linux-x64/gcc-6.4.0-rdk/environment-setup-cortexa55t2hf-neon-fp-armv8-rdkmllib32-linux-gnueabi
  if [[ x${CONFIG_RUNTIME_OE} != x ]]; then
    environment_setup=${topdir}/toolchain/oe/linux-x64/gcc-11.3.0-poky/environment-setup-armv7at2hf-neon-vfpv4-pokymllib32-linux-gnueabi
  elif [[ x${CONFIG_RUNTIME_OE64} != x ]]; then
    environment_setup=${topdir}/toolchain/oe/linux-x64/gcc-11.3.0-poky/environment-setup-armv8a-poky-linux
  fi
  (
  . ${environment_setup}
  meson -Dprefix=/usr ${module_topdir} ${module_topdir}/builddir
  DESTDIR=${opt_build_sysroot} ninja -C ${module_topdir}/builddir install
  )
  # We don't actually need to wait it here
  wait

 if [ "x${CONFIG_OPTEE}" = "x" ]; then
    # There are too many projects prefering seeking header files there
    opt_lib_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_TEE_CLIENT_REL_PATH}
    mkdir -p ${opt_lib_outdir_release}
    INSTALL_D ${module_topdir}/include ${opt_lib_outdir_release}
    INSTALL_D ${module_topdir}/tee/common ${opt_lib_outdir_release}/include
    install -d ${opt_lib_outdir_release}/include/client_api
    cp -v ${module_topdir}/tee/client_api/*.h ${opt_lib_outdir_release}/include/client_api/
    INSTALL_D ${module_topdir}/tee/internal_api ${opt_lib_outdir_release}/include
 fi
fi

### step 2: bootparameter + tz kernel ###
unset boot_seclvl
if [ "is${syna_chip_name}" = "isdolphin" ]; then
  if [ "is${opt_genx_enable}" = "isy" ]; then
    boot_seclvl=genx
  else
    boot_seclvl=gen2
  fi
fi

if [ -f  ${module_topdir}/release.sh ]; then # engineer build
  if [ -f ${module_topdir}/build/image/prebuilts/gen2/${syna_chip_name}/${syna_chip_rev}/${syna_chip_mid}/tz1_en.bin ] || \
     [ -f ${module_topdir}/build/image/prebuilts/genx/${syna_chip_name}/${syna_chip_rev}/tz1_en.bin ] || \
     [ -f ${module_topdir}/build/image/prebuilts/${syna_chip_name}/${syna_chip_mid}/tz1_en.bin ]; then
    if [ "is${opt_genx_enable}" = "isy" ]; then
      tz_rel_ver=genx
    else
      tz_rel_ver=2
    fi
  fi

  # Copy TZ Kernel
  source ${module_build_topdir}/script/install_binary.rc install_eng

  # Generate TZ Boot Parameters
  source ${module_build_topdir}/script/bootparam.rc

  ### Check results ###
  [ -d ${product_dir}/ ]
  [ -d ${opt_tzk_outdir_release}/ ]

  source ${module_build_topdir}/script/tee_pack.rc pack_stage1
else # VSSDK release build
  if [ -f ${module_topdir}/products/${syna_chip_name}/${boot_seclvl}/${tz_memlayout}/${syna_chip_rev}/${syna_chip_mid}/tz1_en.bin ] || \
     [ -f ${module_topdir}/products/${syna_chip_name}/${boot_seclvl}/${tz_memlayout}/${syna_chip_rev}/tz1_en.bin ]; then
    if [ "is${opt_genx_enable}" = "isy" ]; then
      tz_rel_ver=genx
    else
      tz_rel_ver=2
    fi
  fi

  source ${module_build_topdir}/script/install_binary.rc install_rel
fi

### step 3: oem + tzk_en.bin ###
oem_setting_dir=${module_topdir}/products/${syna_chip_name}/${boot_seclvl}/${tz_memlayout}

# Combine TEE with OEM Parameter Setting
  [ -f ${oem_setting_dir}/oem_setting.cfg ]
  [ -d ${opt_outdir_intermediate}/ ]

  source ${module_build_topdir}/script/oem_setting.rc
  echo ${oem_setting_dir}/oem_setting.cfg
  echo ${opt_outdir_intermediate}/oem_setting.bin
  gen_oem_setting ${oem_setting_dir}/oem_setting.cfg ${opt_board_memory_size} ${opt_outdir_intermediate}/oem_setting.bin

  source ${module_build_topdir}/script/tee_pack.rc pack_stage2


#TODO(Song) Avoid using PATH like /home/galois/bin
if [ -f ${TEE_DAEMON} ]; then
  if [ "is$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT" = "isy" ]; then
    mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/bin
    cp -adv  ${TEE_DAEMON} ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/bin
  else
    mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/bin
    cp -adv ${TEE_DAEMON} ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/bin
  fi
fi

if [ -f ${module_topdir}/tee/bin/rpmbpair ]; then
  if [ "is$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT" = "isy" ]; then
    mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/bin
    cp -adv ${module_topdir}/tee/bin/rpmbpair ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/opt/syna/bin
  else
    mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/bin
    cp -adv ${module_topdir}/tee/bin/rpmbpair ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/home/galois/bin
  fi
fi
