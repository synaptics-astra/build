# Bash script: subimage: bootloader: nand

if [ "is${CONFIG_GENX_MCU}" = "isy" ]; then
  process_cmd="cp"
else
  process_cmd="${basedir_tools}/prepend_image_info.sh"
fi

# Generate subimg
if [ "is${CONFIG_UBOOT_SUBOOT}" = "isy" ]; then
  eval ${process_cmd} ${outdir_uboot_suboot_release}/uboot_en.bin ${outfile_bootloader_subimg}
else
  eval ${process_cmd} ${outdir_bootloader_release}/bootloader_en.bin ${outfile_bootloader_subimg}
fi