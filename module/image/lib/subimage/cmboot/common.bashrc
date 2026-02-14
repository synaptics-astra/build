# Bash script: subimage: cmboot: common

# Output file for combined boot image
outdir_cmboot=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/cmboot
cmboot_packimg=${outdir_cmboot}/cmbootpack.subimg
outfile_cmboot_subimg=${outdir_subimg_intermediate}/cmboot.subimg
outfile_bootloader_subimg=${outdir_subimg_intermediate}/bootloader.subimg
outfile_tee_subimg=${outdir_subimg_intermediate}/tee.subimg
outfile_sysmgr_subimg=${outdir_subimg_intermediate}/sysmgr.subimg

