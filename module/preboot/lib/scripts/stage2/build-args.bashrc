# Bash script: stage 2: handle common arguments
opt_cross_compile=${CONFIG_TOOLCHAIN_BSP}
opt_basedir_security_images="${CONFIG_SYNA_SDK_PATH}/${CONFIG_PREBOOT_SECURITY_IMAGE_PATH}"
opt_basedir_security_tools="${opt_basedir_security_tools}"
opt_workdir_security_keys="${opt_basedir_security_keys}"

opt_config_fastboot="${syna_fastboot}"

opt_nand_randomizer="${syna_nand_randomizer}"

if [ "is${syna_sec_lvl}" == "isgenx" ]; then
    opt_genx_enable=y
fi
