#!/bin/bash

echo "ampsdk build script"
source build/header.rc
source build/install.rc
source build/chip.rc
source build/module/toolchain/${CONFIG_TOOLCHAIN_APPLICATION}.rc
source build/module/toolchain/${CONFIG_TOOLCHAIN_TA}.rc

source build/module/ampsdk/common.rc

install_amp() {
  # Copy files
  cp -ad ${basedir_amp}/amp/inc/. ${outdir_amp}/include/.
  cp -ad ${outdir_amp}/idl_include/amp_client_rpc.h ${outdir_amp}/include/
  cp -ad ${basedir_amp}/amp/tools/flick/flick-2.1/runtime/headers/. ${outdir_amp}/include/
  cp -ad ${outdir_amp}/flick/runtime/headers/flick ${outdir_amp}/include/

  # Copy results to runtime filesystem
  if [ "is$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT" = "isy" ] || \
     [ "is$CONFIG_RUNTIME_LINUX_BASELINE_BUILDROOT64" = "isy" ]; then
    local outdir_dst_app=${opt_workdir_runtime_sysroot}/opt/syna
  else
    local outdir_dst_app=${opt_workdir_runtime_sysroot}/home/galois
  fi
  local outdir_dst_root=${opt_workdir_runtime_sysroot}
  local workdir_src=${outdir_amp}

  mkdir -p ${outdir_dst_app}/lib
  mkdir -p ${outdir_dst_app}/bin
  mkdir -p ${outdir_dst_root}/etc
  mkdir -p ${opt_workdir_build_sysroot}/usr/include/amp

  # Install to rootfs
  INSTALL_D ${workdir_src}/lib ${outdir_dst_app}/
  INSTALL_D ${workdir_src}/bin ${outdir_dst_app}/

  # Install to sysroot
  cp -adv ${workdir_src}/include/* ${opt_workdir_build_sysroot}/usr/include/amp
  INSTALL_D ${workdir_src}/lib ${opt_workdir_build_sysroot}/usr

  if [ "is${CONFIG_AMP_IP_AUDIO_MS12_ARM_V2_4}" = "isy" ]; then
    local ms12_dap_file=ms12v2_4/dap_complexity_4ch.dat
  fi

  cp -advL ${basedir_amp}/products/${opt_amp_profile}/berlin_config_sw.xml ${outdir_dst_root}/etc/.
  cp -advL ${basedir_amp}/products/${opt_amp_profile}/berlin_config_hw.xml ${outdir_dst_root}/etc/.
  if [ "is${CONFIG_AMP_IP_AUDIO_MS12_ARM_V2_4}" = "isy" ]; then
      if [ -f "${basedir_amp}/products/${opt_amp_profile}/${ms12_dap_file}" ]; then
          cp -advL ${basedir_amp}/products/${opt_amp_profile}/${ms12_dap_file} ${outdir_dst_root}/etc/.
      fi
  fi

  if [ "is${CONFIG_AMP_MIPI_ENABLE}" = "isy" ]; then
      cp -advL ${basedir_amp}/products/${opt_amp_profile}/mipi/${CONFIG_AMP_MIPI_PANEL}.xml ${outdir_dst_root}/etc/.
  fi

  if [ "is${CONFIG_AMP_COMPONENT_ISP_ENABLE}" = "isy" ]; then
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/IMX227.xml ${outdir_dst_root}/etc/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/IMX258.xml ${outdir_dst_root}/etc/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/OV2775.xml ${outdir_dst_root}/etc/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/IMX415.xml ${outdir_dst_root}/etc/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/3aconfig.json ${outdir_dst_root}/etc/.
  fi

  if [ -f ${basedir_amp}/products/${opt_amp_profile}/model_config.xml ]; then
    cp -adv --dereference ${basedir_amp}/products/${opt_amp_profile}/model_config.xml ${outdir_dst_root}/etc/.
  fi

  if [ -d ${basedir_amp}/products/${opt_amp_profile}/panel_config ]; then
    cp -adv --dereference ${basedir_amp}/products/${opt_amp_profile}/panel_config ${outdir_dst_root}/etc/.
  fi

  if [ "is${CONFIG_AMP_HDMI_HDCP_REPEATER}" = "isy" ];then
    mkdir -p ${outdir_dst_app}/fw
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/esm_firmware_base.fw ${outdir_dst_app}/fw/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/HDCP2X_Rptr_Config.fw ${outdir_dst_app}/fw/.
    cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/HDCP2X_TxRx_Config.fw ${outdir_dst_app}/fw/.
  elif [ "is${CONFIG_AMP_HDMI_HDCP_2X}" = "isy" ]; then
    if [ "is${CONFIG_BERLIN_PLATYPUS_A0}" = "isy" ]; then
      mkdir -p ${outdir_dst_app}/fw
      cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/esm_firmware.fw ${outdir_dst_app}/fw/.
    elif [[ ( "is${CONFIG_BERLIN_DOLPHIN_Z1}" = "isy" ) || ( "is${CONFIG_BERLIN_DOLPHIN_A0}" = "isy" )]]; then
      mkdir -p ${outdir_dst_app}/fw
      if [ "is${CONFIG_AMP_HDMI_HDCP2X_RX}" = "isy" ]; then
        cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/esm_firmware_standalone.fw ${outdir_dst_app}/fw/.
      else
        cp -advL ${basedir_amp}/products/${opt_amp_profile}/firmware/esm_firmware_tx.fw ${outdir_dst_app}/fw/.
      fi
    fi
  fi

  if [ "is${CONFIG_AMP_COMPONENT_DEWARP_ENABLE}" = "isy" ]; then
      mkdir -p ${outdir_dst_app}/firmware/camera
      cp -advL ${basedir_amp}/products/${opt_amp_profile}/camera/DEWARP_CFG.isp ${outdir_dst_app}/firmware/camera/.
      cp -advL ${basedir_amp}/products/${opt_amp_profile}/camera/DEWARP_LUT.isp ${outdir_dst_app}/firmware/camera/.
  fi
}

#############
# Main      #
#############
basedir_amp=${topdir}/ampsdk
opt_workdir_build_sysroot=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_SYSYROOT}
opt_workdir_runtime_sysroot=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}
opt_amp_profile=${CONFIG_AMP_PROFILE}

if [ "is${CONFIG_TZK}" = "isy"  ]; then
    outdir_ta_amp=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/ta/TA_MODULE_PATH/${syna_chip_name}/${syna_chip_rev}
else
    outdir_ta_amp=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/system/lib/optee_armtz
fi

outdir_fw_amp=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/fw/FW_MODULE_PATH/${syna_chip_name}/${syna_chip_rev}
outdir_amp=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_AMP_OUTPUT_PATH}

if [ $clean -eq 0 ]; then
echo "Build and install AMP"

if [ "is${CONFIG_ANDROID_OS}" = "isy" ]; then
    TARGET_OS=ANDROID
fi

if [ "is${CONFIG_LINUX_OS}" = "isy" ]; then
    TARGET_OS=LINUX
fi

if [ "is${CONFIG_TOOLCHAIN_64BITS_ONLY}" = "isy" ]; then
   export TARGET_TOOLCHAIN_64BITS_ONLY=true
else
   export TARGET_TOOLCHAIN_64BITS_ONLY=false
fi

if [ "${CONFIG_TZK_MEM_LAYOUT}" = "stb_4g_cma_iommu" ]; then
    export TARGET_BOARD_MEM=4GB
fi

create_autoconfig ${outdir_amp} ${config_file} n
pushd ${basedir_amp}
# create autoconf.h
compile_amp ${TARGET_OS} ${CONFIG_TOOLCHAIN_APPLICATION} &
wait $!
install_amp &
wait $!
popd

### Clean up ###
unset -f compile_amp
unset -f install_amp
unset -f create_autoconfig

else
pushd ${basedir_amp}
export GALOIS_TOOLS_PREFIX=${CONFIG_CONFIG_AMP_COMPILER_PREFIX}
compile_amp clean &
wait $!
popd
unset -f compile_amp
fi
