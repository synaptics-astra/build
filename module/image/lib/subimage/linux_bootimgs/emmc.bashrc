# Bash script: subimage: linux_bootimgs: emmc

### !!! FIXME !!! should be consolidate into single script ###

########
# Main #
########

f_bootimgs_raw=${outdir_subimg_intermediate}/linux_bootimgs_raw.bin

### Pack with 'mkbootimg" ###
if [ "is${CONFIG_COMPRESS_XZ}" = "isy" ]; then
  pack_boot_imgs $f_bootimgs_raw "xz"
else
  pack_boot_imgs $f_bootimgs_raw "lz4"
fi

### Generate Secure Image ###
if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
   ${security_tools_path}in_extras.py "LINUX_KERNEL" ${outdir_subimg_intermediate}/in_linux_kernel.bin 0x00000001
   genx_secure_image "LINUX_KERNEL" ${outdir_subimg_intermediate}/in_linux_kernel.bin 0x0 ${f_bootimgs_raw} ${outdir_subimg_intermediate}/linux_bootimgs_en.bin
else
  gen2_secure_image "kernel" ${f_bootimgs_raw} ${outdir_subimg_intermediate}/linux_bootimgs_en.bin
fi

### Generate subimg ###
if [ "is${CONFIG_NO_PREPEND_IMG_INFO}" = "isy" ]; then
  cp ${outdir_subimg_intermediate}/linux_bootimgs_en.bin ${outdir_subimg_intermediate}/linux_bootimgs.subimg
else
  ${basedir_tools}/prepend_image_info.sh ${outdir_subimg_intermediate}/linux_bootimgs_en.bin ${outdir_subimg_intermediate}/linux_bootimgs.subimg
fi
