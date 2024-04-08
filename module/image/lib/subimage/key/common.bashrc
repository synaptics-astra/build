# Bash script: subimage: preboot: common

# Directories
outdir_key_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/MBOOT/key
workdir_security_keys=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_KEY_PATH}/${syna_chip_name}/${syna_chip_rev}

# Output file
outfile_key_subimg=${outdir_subimg_intermediate}/key.subimg
