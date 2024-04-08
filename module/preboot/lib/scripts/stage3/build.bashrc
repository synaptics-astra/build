# Bash script: stage 3 build

opt_cross_compile=${CONFIG_TOOLCHAIN_BSP}
opt_chip_name=${syna_chip_name}

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  opt_genx_enable=${CONFIG_GENX_ENABLE}
fi

if [ "is${CONFIG_RDK_SYS}" = "isy" ]; then
  opt_rdk_sys=${CONFIG_RDK_SYS}
fi

if [ "is${CONFIG_UBOOT_SPIUBOOT}" = "isy" ]; then
    opt_spi_uboot=${CONFIG_UBOOT_SPIUBOOT}
fi

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  opt_config_ddrphyfw=y
else
  opt_config_ddrphyfw=n
fi

opt_production_build="${CONFIG_PRODUCTION_BUILD}"

### Variables  ###
preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}
preboot_outdir_build_release="${preboot_outdir_release}/intermediate/release"

preboot_topdir=${topdir}/boot/preboot

# Feature: bootflow
preboot_prebuilts_dir_bootflow="${preboot_topdir}/prebuilts"
preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${syna_chip_name}"
preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${syna_chip_rev}"
if [ "is${opt_genx_enable}" = "is" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${CONFIG_PREBOOT_MARKET_ID}"
else
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${CONFIG_PREBOOT_PROFILE}"
fi
preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/bootflow"
if [ "is${CONFIG_PREBOOT_BOOTFLOW_NR}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/NR"
elif [ "is${CONFIG_PREBOOT_BOOTFLOW_AB}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/AB"
else
  /bin/false
fi
if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/EMMC"
elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/NAND"
  if [ "is${CONFIG_NAND_RANDOMIZER}" = "isy" ]; then
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/randomizer_y"
  else
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/randomizer_n"
  fi
else
  /bin/false
fi
if [ "is${CONFIG_FASTBOOT_FLOW}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/fastboot_y"
else
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/fastboot_n"
fi
## FIXME: if nand, enable/disable randomization

# Feature: hwinit
preboot_prebuilts_dir_hwinit="${preboot_topdir}/prebuilts"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${syna_chip_name}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${syna_chip_rev}"
if [ "is${opt_genx_enable}" = "is" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MARKET_ID}"
else
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_PROFILE}"
fi
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/hwinit"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_DDR_TYPE}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_SIZE}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_SPEED}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_VARIANT}"
if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/EMMC"
elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/NAND"
else
  /bin/false
fi
## FIXME: if nand, enable/disable randomization

### Copy prebuilt binaries  ###
mkdir -p ${preboot_outdir_release}
mkdir -p ${preboot_outdir_build_release}

if [ "is${opt_genx_enable}" != "is" ]; then
  ### gen x compose preboot esmt image ###
  f_K0_BOOT_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_BOOT_store.bin
  f_K0_TEE_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_TEE_store.bin
  f_K1_BOOT_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_BOOT_A_store.bin
  f_K1_BOOT_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_BOOT_B_store.bin
  f_K1_TEE_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_A_store.bin
  f_K0_REE_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_REE_store.bin
  f_K1_TEE_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_B_store.bin
  f_K1_TEE_C_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_C_store.bin
  f_K1_TEE_D_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_D_store.bin
  f_K1_REE_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_A_store.bin
  f_K1_REE_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_B_store.bin
  f_K1_REE_C_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_C_store.bin
  f_K1_REE_D_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_D_store.bin

  if [ "is${opt_spi_uboot}" != "is" ]; then
    f_EROM=${preboot_prebuilts_dir_bootflow}/uboot/erom.bin
    f_BCM_Kernel=${preboot_prebuilts_dir_bootflow}/uboot/bcm_kernel.bin
    f_boot_monitor=${preboot_prebuilts_dir_bootflow}/uboot/boot_monitor.bin
  else
    f_EROM=${preboot_prebuilts_dir_bootflow}/erom.bin
    f_BCM_Kernel=${preboot_prebuilts_dir_bootflow}/bcm_kernel.bin
    f_boot_monitor=${preboot_prebuilts_dir_bootflow}/boot_monitor.bin
  fi

  f_scs_data_param=${preboot_prebuilts_dir_hwinit}/scs_data_param.sign
  if [ "is${opt_production_build}" = "isy" ]; then
    f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en_mp.bin
    f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en_mp.bin
  else
    f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en.bin
    f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en.bin
  fi
  if [ "is${syna_chip_name}" = "isplatypus" ] || [ "is${syna_chip_name}" = "ismyna2" ]; then
    dd if=/dev/zero of=${preboot_outdir_build_release}/ddrphy.bin bs=1 count=98424
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    ##FIXME: will add dolphin ddrphy image handle here.
    f_gen3_ddr_phy_fw_0=${preboot_prebuilts_dir_hwinit}/gen3_ddr_phy_fw_0.bin
    f_gen3_ddr_phy_fw_1=${preboot_prebuilts_dir_hwinit}/gen3_ddr_phy_fw_1.bin
    /bin/cp $f_gen3_ddr_phy_fw_0 ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin
    /bin/cp $f_gen3_ddr_phy_fw_1 ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin
  fi

  [[ -f $f_K0_BOOT_store && -f $f_K0_TEE_store && -f $f_K1_BOOT_A_store && -f $f_K1_BOOT_B_store && -f $f_K1_TEE_A_store && -f $f_EROM && -f $f_K0_REE_store && -f $f_BCM_Kernel && -f $f_K1_TEE_B_store && -f $f_K1_TEE_C_store && -f $f_K1_TEE_D_store && -f $f_K1_REE_A_store && -f $f_K1_REE_B_store && -f $f_K1_REE_C_store && -f $f_K1_REE_D_store && -f $f_boot_monitor ]]

  /bin/cp $f_K0_BOOT_store ${preboot_outdir_build_release}/K0_BOOT_store.bin
  /bin/cp $f_K0_TEE_store ${preboot_outdir_build_release}/K0_TEE_store.bin
  /bin/cp $f_K1_BOOT_A_store ${preboot_outdir_build_release}/K1_BOOT_A_store.bin
  /bin/cp $f_K1_BOOT_B_store ${preboot_outdir_build_release}/K1_BOOT_B_store.bin
  /bin/cp $f_K1_TEE_A_store ${preboot_outdir_build_release}/K1_TEE_A_store.bin
  /bin/cp $f_EROM ${preboot_outdir_build_release}/erom.bin
  /bin/cp $f_K0_REE_store ${preboot_outdir_build_release}/K0_REE_store.bin
  /bin/cp $f_BCM_Kernel ${preboot_outdir_build_release}/bcm_kernel.bin
  /bin/cp $f_K1_TEE_B_store ${preboot_outdir_build_release}/K1_TEE_B_store.bin
  /bin/cp $f_K1_TEE_C_store ${preboot_outdir_build_release}/K1_TEE_C_store.bin
  /bin/cp $f_K1_TEE_D_store ${preboot_outdir_build_release}/K1_TEE_D_store.bin
  /bin/cp $f_K1_REE_A_store ${preboot_outdir_build_release}/K1_REE_A_store.bin
  /bin/cp $f_K1_REE_B_store ${preboot_outdir_build_release}/K1_REE_B_store.bin
  /bin/cp $f_K1_REE_C_store ${preboot_outdir_build_release}/K1_REE_C_store.bin
  /bin/cp $f_K1_REE_D_store ${preboot_outdir_build_release}/K1_REE_D_store.bin
  /bin/cp $f_boot_monitor ${preboot_outdir_build_release}/boot_monitor.bin
  /bin/cp $f_sysinit ${preboot_outdir_build_release}/sysinit_en.bin
  /bin/cp $f_scs_data_param ${preboot_outdir_build_release}/scs_data_param.sign
  /bin/cp $f_miniloader ${preboot_outdir_build_release}/miniloader_en.bin

  ### generate SCS_Unchecked_Area ###
  dd if=/dev/zero of=${preboot_outdir_build_release}/scs_data_unchecked.bin  bs=1  count=4096

  # Pack binaries
  cat ${preboot_outdir_build_release}/K0_BOOT_store.bin > ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K0_TEE_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_BOOT_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_BOOT_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K0_REE_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/bcm_kernel.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/scs_data_param.sign >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/scs_data_unchecked.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/boot_monitor.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  if [ "is${opt_chip_name}" = "isplatypus" ] || [ "is${opt_chip_name}" = "ismyna2" ]; then
    cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    cat ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin >> ${preboot_outdir_release}/preboot_esmt.bin
    cat ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  fi
  cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin

  # Generate information of packed binaries
  echo -n "K0_BOOT_store," > ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_BOOT_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K0_TEE_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_TEE_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_BOOT_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_BOOT_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_BOOT_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_BOOT_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "erom," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K0_REE_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_REE_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "bcm_kernel," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/bcm_kernel.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_C_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_D_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_C_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_D_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "SCS_DATA_PARAM," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/scs_data_param.sign >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "SCS_DATA_unchecked," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/scs_data_unchecked.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "boot_monitor," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/boot_monitor.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "sysinit," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.info
  if [ "is${opt_chip_name}" = "isplatypus" ] || [ "is${opt_chip_name}" = "ismyna2" ]; then
    echo -n "ddrphy," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.info
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    echo -n "gen3_ddr_phy_fw_0," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin >> ${preboot_outdir_release}/preboot_esmt.info
    echo -n "gen3_ddr_phy_fw_1," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin >> ${preboot_outdir_release}/preboot_esmt.info
  fi
  echo -n "miniloader," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.info
else
# EROM, TSM, Copy SYSINIT and MINILOADER
f_erom=${preboot_prebuilts_dir_bootflow}/erom.bin
f_tsm=${preboot_prebuilts_dir_bootflow}/tsm.bin
f_ddrphy=${preboot_prebuilts_dir_hwinit}/ddrphy.bin
if [ "is${opt_production_build}" = "isy" ]; then
  f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en_mp.bin
  f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en_mp.bin
else
  f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en.bin
  f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en.bin
fi

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  if [ -f ${f_ddrphy} ]; then
    INSTALL_F $f_ddrphy ${preboot_outdir_build_release}/
  fi
fi

INSTALL_F $f_erom ${preboot_outdir_build_release}/
INSTALL_F $f_tsm ${preboot_outdir_build_release}/
cp -ad $f_sysinit ${preboot_outdir_build_release}/sysinit_en.bin
cp -ad $f_miniloader ${preboot_outdir_build_release}/miniloader_en.bin

if [ -f ${preboot_prebuilts_dir_bootflow}/erom.factory ]; then
  INSTALL_F ${preboot_prebuilts_dir_bootflow}/erom.factory ${preboot_outdir_build_release}/
fi
if [ -f ${preboot_prebuilts_dir_bootflow}/tsm.factory ]; then
  INSTALL_F ${preboot_prebuilts_dir_bootflow}/tsm.factory ${preboot_outdir_build_release}/
fi

### Pack EROM, SYSINIT, MINILOADER and TSM together

# Pack binaries
cat ${preboot_outdir_build_release}/erom.bin > ${preboot_outdir_release}/preboot_esmt.bin
cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin
if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.bin
fi
cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin

cat ${preboot_outdir_build_release}/tsm.bin >> ${preboot_outdir_release}/preboot_esmt.bin

if [ -f ${preboot_outdir_build_release}/erom.factory ] && [ -f ${preboot_outdir_build_release}/tsm.factory ]; then
  cat ${preboot_outdir_build_release}/erom.factory > ${preboot_outdir_release}/preboot_esmt_factory.bin
  cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
    cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  fi
  cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  cat ${preboot_outdir_build_release}/tsm.factory >> ${preboot_outdir_release}/preboot_esmt_factory.bin
fi

# Generate information of packed binaries
echo -n "erom," > ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.info

echo -n "sysinit," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.info

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  echo -n "ddrphy," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.info
fi

echo -n "miniloader," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.info

echo -n "tsm," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/tsm.bin >> ${preboot_outdir_release}/preboot_esmt.info

fi
