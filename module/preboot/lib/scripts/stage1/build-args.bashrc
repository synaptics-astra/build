# Bash script: stage 1: handle arguments

opt_chip_name="${syna_chip_name}"
opt_chip_rev="${syna_chip_rev}"

opt_profile="${CONFIG_PREBOOT_PROFILE}"
opt_platform="${CONFIG_PREBOOT_PLATFORM}"

opt_cross_compile="${CONFIG_TOOLCHAIN_BSP}"

opt_production_build="${CONFIG_PRODUCTION_BUILD}"

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    opt_genx_enable=${CONFIG_GENX_ENABLE}
fi

if [ "is${CONFIG_RDK_SYS}" = "isy" ]; then
    opt_rdk_sys=${CONFIG_RDK_SYS}
fi

if [ "is${CONFIG_UBOOT}" = "isy" ]; then
    opt_uboot=${CONFIG_UBOOT}
fi

if [ "is${CONFIG_UBOOT_SPIUBOOT}" = "isy" ]; then
    opt_spi_uboot=${CONFIG_UBOOT_SPIUBOOT}
fi

if [ "is${CONFIG_LINUX_OS}" = "isy" ]; then
  opt_bootflow="LINUX"
fi

if [ "is${CONFIG_ANDROID_OS}" = "isy" ]; then
  opt_bootflow="VERIFIEDBOOT"
fi

if [ "is${CONFIG_PREBOOT_BOOTFLOW_AB}" = "isy" ]; then
    opt_bootflow_version="AB"
fi

if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  opt_flash_type="EMMC"
fi
if [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  opt_flash_type="NAND"
  opt_boot_part_size="${CONFIG_NAND_BOOT_PART_SIZE}"
  opt_nand_randomizer="${CONFIG_NAND_RANDOMIZER}"
fi

if [ "is${CONFIG_IMAGE_USBBOOT}" = "isy" ]; then
  opt_flash_type="USBBOOT"
fi

if [ "is${CONFIG_FASTBOOT_FLOW}" = "isy" ]; then
  opt_config_fastboot="${CONFIG_FASTBOOT_FLOW}"
else
  opt_config_fastboot=n
fi

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  opt_config_ddrphyfw=y
else
  opt_config_ddrphyfw=n
fi

opt_market_id="${CONFIG_PREBOOT_MARKET_ID}"

opt_basedir_security_images="${CONFIG_SYNA_SDK_PATH}/${CONFIG_PREBOOT_SECURITY_IMAGE_PATH}"
opt_basedir_security_tools="${opt_basedir_security_tools}"
opt_workdir_security_keys="${opt_basedir_security_keys}"
opt_workfile_security_version_config="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/release/SECURITY/version/codetype_1/config"

opt_ddr_type="${CONFIG_PREBOOT_DDR_TYPE}"
opt_board_memory_speed="${CONFIG_PREBOOT_MEMORY_SPEED}"
opt_board_memory_size="${CONFIG_PREBOOT_MEMORY_SIZE}"
if [ "x{CONFIG_PREBOOT_MEMORY_VARIANT}" != "x" ]; then
  opt_board_memory_variant="${CONFIG_PREBOOT_MEMORY_VARIANT}"
fi

if [ "is${CONFIG_JTAG_ENABLE}" = "isy" ]; then
  opt_jtag_enable=y
fi

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
