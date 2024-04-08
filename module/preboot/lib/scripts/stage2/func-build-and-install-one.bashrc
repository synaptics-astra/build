# Bash script: stage 2: build hwinit features

#############
# Functions #
#############

build_and_install_bootflow_feature() {
  feature_name=$1; shift

  opt_bootflow_version=$1; shift
  opt_chip_name=$syna_chip_name
  opt_chip_rev=$syna_chip_rev
  opt_market_id=$syna_chip_mid
  opt_flash_type=$syna_flash_type
  opt_platform=none;
  opt_board_memory_size=none;
  opt_board_memory_speed=none;
  opt_board_memory_variant=none;
  opt_workdir_security_keys="${security_keys_path}"
  opt_workfile_security_version_config="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_VERSION_PATH}/codetype_1/config"

  preboot_feature_variant="${opt_chip_name}/${opt_chip_rev}"
  if [ "is${syna_sec_lvl}" == "isgenx" ]; then
    preboot_feature_variant="${preboot_feature_variant}/${genx_types}"
  else
    preboot_feature_variant="${preboot_feature_variant}/${opt_market_id}"
  fi
  preboot_feature_variant="${preboot_feature_variant}/${feature_name}/${opt_bootflow_version}/${opt_flash_type}"
  ## FIXME: if nand, enable/disable randomization
  if [ "is${opt_flash_type}" = "isNAND" ]; then
    preboot_feature_variant="${preboot_feature_variant}/randomizer_${opt_nand_randomizer}"
  fi
  preboot_feature_variant="${preboot_feature_variant}/fastboot_${opt_config_fastboot}"
  preboot_build_sysinit=n
  preboot_build_miniloader=y

  preboot_outdir_build_release="${preboot_build_basedir}/intermediate/${preboot_feature_variant}/release"
  preboot_outdir_build_intermediate="${preboot_build_basedir}/intermediate/${preboot_feature_variant}/obj"

  opt_production_build=n
  source "${preboot_module_dir}/lib/scripts/stage2/build-one.bashrc" &
  wait $!

  ### Install prebuilt binaries ###
  mkdir -p  ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  if [ -f ${preboot_outdir_build_release}/tsm.bin ]; then
    INSTALL_F ${preboot_outdir_build_release}/tsm.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  fi
  if [ -f ${preboot_outdir_build_release}/erom.factory ]; then
    INSTALL_F ${preboot_outdir_build_release}/erom.factory ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  fi
  if [ -f ${preboot_outdir_build_release}/tsm.factory ]; then
    INSTALL_F ${preboot_outdir_build_release}/tsm.factory ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  fi
  INSTALL_F ${preboot_outdir_build_release}/miniloader_en.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  if [ "is${syna_sec_lvl}" = "isgenx" ]; then
    preboot_basedir_security_genx=${opt_basedir_security_images}/chip/${opt_chip_name}/${opt_chip_rev}/${genx_types}
    INSTALL_D ${preboot_basedir_security_genx}/key_stores/ ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/key_stores
    INSTALL_F_L ${preboot_basedir_security_genx}/bcm_kernel.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
    INSTALL_F_L ${preboot_basedir_security_genx}/boot_monitor.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
    INSTALL_F_L ${preboot_basedir_security_genx}/erom.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
    INSTALL_F ${preboot_basedir_security_genx}/uboot/bcm_kernel.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/uboot/
    INSTALL_F ${preboot_basedir_security_genx}/uboot/boot_monitor.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/uboot/
    INSTALL_F ${preboot_basedir_security_genx}/uboot/erom.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/uboot/
  else
    INSTALL_F ${preboot_outdir_build_release}/erom.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  fi

  ### Build production build without uart prints and copy the binary as miniloader_en_mp.bin
  opt_production_build=y
  source "${preboot_module_dir}/lib/scripts/stage2/build-one.bashrc" &
  wait $!
  cp ${preboot_outdir_build_release}/miniloader_en.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/miniloader_en_mp.bin
}

build_and_install_hwinit_feature() {
  feature_name=$1; shift

  opt_ddr_type=$1; shift
  opt_board_memory_size=$1; shift
  opt_board_memory_speed=$1; shift
  opt_config_ddrphyfw=$1; shift
  opt_board_memory_variant=$1; shift
  opt_chip_name=$syna_chip_name
  opt_chip_rev=$syna_chip_rev
  opt_market_id=$syna_chip_mid
  opt_flash_type=$syna_flash_type
  opt_platform=none;
  opt_bootflow_version=none;

  opt_workdir_security_keys="${security_keys_path}"
  opt_workfile_security_version_config="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_VERSION_PATH}/codetype_1/config"

  preboot_feature_variant="${opt_chip_name}/${opt_chip_rev}"
  if [ "is${syna_sec_lvl}" = "isgenx" ]; then
    preboot_feature_variant="${preboot_feature_variant}/${genx_types}"
  else
    preboot_feature_variant="${preboot_feature_variant}/${opt_market_id}"
  fi
  preboot_feature_variant="${preboot_feature_variant}/${feature_name}/${opt_ddr_type}/${opt_board_memory_size}/${opt_board_memory_speed}/${opt_board_memory_variant}/${opt_flash_type}"
  preboot_build_sysinit=y
  preboot_build_miniloader=n

  preboot_outdir_build_release="${preboot_build_basedir}/intermediate/${preboot_feature_variant}/release"
  preboot_outdir_build_intermediate="${preboot_build_basedir}/intermediate/${preboot_feature_variant}/obj"

  opt_production_build=n
  source "${preboot_module_dir}/lib/scripts/stage2/build-one.bashrc" &
  wait $!

  ### Install prebuilt binaries ###
  mkdir -p  ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  INSTALL_F ${preboot_outdir_build_release}/sysinit_en.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  if [ "is${syna_sec_lvl}" = "isgenx" ]; then
    INSTALL_F ${preboot_outdir_build_release}/scs_data_param.sign ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
  fi
  if [ "is${opt_config_ddrphyfw}" = "isy" ]; then
    INSTALL_F ${preboot_outdir_build_release}/ddrphy.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
    if [ "is${opt_chip_name}" = "isdolphin" ] && [ "is${syna_sec_lvl}" = "isgenx" ]; then
      INSTALL_F ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
      INSTALL_F ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/
    fi
  fi

  ### Build production build without uart prints and copy the binary as sysinit_en_mp.bin
  opt_production_build=y
  source "${preboot_module_dir}/lib/scripts/stage2/build-one.bashrc" &
  wait $!
  cp ${preboot_outdir_build_release}/sysinit_en.bin ${preboot_release_topdir}/prebuilts/${preboot_feature_variant}/sysinit_en_mp.bin

}

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
