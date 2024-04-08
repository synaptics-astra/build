# Bash script: build one feature

### Create subdirs ###
mkdir -p ${preboot_outdir_build_release}
mkdir -p ${preboot_outdir_build_intermediate}

### Command line arguments ###
cmd_args=""

cmd_args="${cmd_args} --chip-name=${opt_chip_name}"
cmd_args="${cmd_args} --chip-rev=${opt_chip_rev}"

cmd_args="${cmd_args} --profile=${opt_profile}"
cmd_args="${cmd_args} --platform=${opt_platform}"

cmd_args="${cmd_args} --cross_compile=${opt_cross_compile}"

if [ "x${opt_bootflow}" != "x" ]; then
  cmd_args="${cmd_args} --bootflow=${opt_bootflow}"
fi

if [ "x${opt_bootflow_version}" != "x" ]; then
    cmd_args="${cmd_args} --bootflow-version=${opt_bootflow_version}"
fi

if [ "x${opt_boot_part_size}" != "x" ]; then
  cmd_args="${cmd_args} --boot-part-size=${opt_boot_part_size}"
fi

if [ "x${opt_nand_randomizer}" != "x" ]; then
  cmd_args="${cmd_args} --nand-randomizer=${opt_nand_randomizer}"
fi

if [ "x${opt_flash_type}" != "x" ]; then
  cmd_args="${cmd_args} --flash-type=${opt_flash_type}"
else
  /bin/false
fi

if [ "x$opt_rebuild_nocs_preboot" != "x" ]; then
  cmd_args="${cmd_args} --rebuild-nocs-preboot=${opt_rebuild_nocs_preboot}"
fi

cmd_args="${cmd_args} --market-id=$(eval printf 0x%x ${opt_market_id})"

cmd_args="${cmd_args} --outdir-intermediate=${preboot_outdir_build_intermediate}"
cmd_args="${cmd_args} --outdir-release=${preboot_outdir_build_release}"
cmd_args="${cmd_args} --outdir-product=${preboot_build_basedir}/product"
cmd_args="${cmd_args} --basedir-mboot-common=${topdir}/boot/common"
cmd_args="${cmd_args} --basedir-security-images=${opt_basedir_security_images}"
cmd_args="${cmd_args} --basedir-security-tools=${security_tools_path}"
cmd_args="${cmd_args} --workdir-security-keys=${security_keys_path}"
cmd_args="${cmd_args} --workfile-security-version-config=${opt_workfile_security_version_config}"

if [ "x${opt_config_fastboot}" != "x" ]; then
  cmd_args="${cmd_args} --config-fastboot=${opt_config_fastboot}"
fi

if [ "x${opt_uboot}" != "x" ]; then
  cmd_args="${cmd_args} --config_uboot=${opt_uboot}"
fi

if [ "x${opt_spi_uboot}" != "x" ]; then
  cmd_args="${cmd_args} --config_spi_uboot=${opt_spi_uboot}"
fi

cmd_args="${cmd_args} --ddr-phy-fw=${opt_config_ddrphyfw}"
cmd_args="${cmd_args} --ddr-type=${opt_ddr_type}"
cmd_args="${cmd_args} --board-memory-speed=${opt_board_memory_speed}"
cmd_args="${cmd_args} --board-memory-size=${opt_board_memory_size}"
if [ "x${opt_board_memory_variant}" != "x" ]; then
  cmd_args="${cmd_args} --board-memory-variant=${opt_board_memory_variant}"
fi
cmd_args="${cmd_args} --build-sysinit=${preboot_build_sysinit} --build-scs-data-param=${preboot_build_sysinit}"
cmd_args="${cmd_args} --build-miniloader=${preboot_build_miniloader}"

if [ "is${opt_genx_enable}" != "is" ]; then
  cmd_args="${cmd_args} --config_genx_enable=${opt_genx_enable}"
fi

if [ "is${opt_rdk_sys}" != "is" ]; then
  cmd_args="${cmd_args} --config_rdk_sys=${opt_rdk_sys}"
fi

if [ "is${opt_production_build}" != "is" ]; then
  cmd_args="${cmd_args} --production-build=${opt_production_build}"
fi

if [ "is${opt_jtag_enable}" != "is" ]; then
  cmd_args="${cmd_args} --config_jtag_enable=${opt_jtag_enable}"
fi

### Build PREBOOT ###
pushd ${preboot_topdir}
  ./build ${cmd_args} no_product_name
popd

### Pack PREBOOT ###
pushd ${preboot_topdir}
  ./pack ${cmd_args} no_product_name
popd

# if nocs (only miniloader is built) or both sysinit and miniloader are built for normal
if [ "is${opt_profile}" = "isnocs" ] || [[ "is${preboot_build_sysinit}" = "isy" && "is${preboot_build_miniloader}" = "isy" ]]; then
  ### Copy PREBOOT ###
  [ -f ${preboot_outdir_build_release}/preboot_esmt.bin ]
  [ -f ${preboot_outdir_build_release}/preboot_esmt.info ]

  cp -ad ${preboot_outdir_build_release}/preboot_esmt.bin ${preboot_outdir_release}/.
  cp -ad ${preboot_outdir_build_release}/preboot_esmt.info  ${preboot_outdir_release}/.
  if [ -f ${preboot_outdir_build_release}/preboot_esmt_factory.bin ] && [ -f ${preboot_outdir_build_release}/preboot_esmt_factory.info ]; then
    cp -ad ${preboot_outdir_build_release}/preboot_esmt_factory.bin ${preboot_outdir_release}/.
    cp -ad ${preboot_outdir_build_release}/preboot_esmt_factory.info  ${preboot_outdir_release}/.
  fi
fi
# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
