# Bash script: subimage: linux_bootimgs: nand

########
# Main #
########

### ### Compress kernel image ###
### f_kernel_xz=${outdir_linux_release}/vmlinux.xz
### cat ${outdir_linux_release}/vmlinux \
###   | xz --check=crc32 --lzma2=dict=512KiB -6 \
###   > ${f_kernel_xz}
###

f_bootimgs_raw=${outdir_subimg_intermediate}/linux_bootimgs_raw.bin

### Pack with 'mkbootimg" ###
pack_boot_imgs $f_bootimgs_raw "lz4"

### Generate Secure Image ###
if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  /bin/cp -ad ${f_bootimgs_raw} ${outdir_subimg_intermediate}/linux_bootimgs_en.bin
else
  gen2_secure_image "kernel" ${f_bootimgs_raw} ${outdir_subimg_intermediate}/linux_bootimgs_en.bin
fi

### Generate subimg ###
${basedir_tools}/prepend_image_info.sh ${outdir_subimg_intermediate}/linux_bootimgs_en.bin ${outdir_subimg_intermediate}/linux_bootimgs.subimg
