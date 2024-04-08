# Bash script: subimage: preloadta: common

# Output file for preloadta with bootloader
outdir_preload_ta=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preload_ta
preload_ta_subimg=${outdir_preload_ta}/preload_ta.subimg
outfile_bootloader_subimg=${outdir_subimg_intermediate}/bootloader.subimg
input_ta_path=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_TA_IMAGE_PATH}/${syna_chip_name}/${syna_chip_rev}

