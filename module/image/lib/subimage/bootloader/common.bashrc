# Bash script: subimage: bootloader: common

# Directories
if [ "is${CONFIG_UBOOT_SUBOOT}" = "isy" ]; then
  outdir_uboot_oemboot_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_UBOOT_REL_PATH}
else
  outdir_bootloader_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_BL_REL_PATH}
fi

# Output file
outfile_bootloader_subimg=${outdir_subimg_intermediate}/bootloader.subimg
