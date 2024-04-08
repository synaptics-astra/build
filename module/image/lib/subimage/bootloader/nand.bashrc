# Bash script: subimage: bootloader: nand

### Copy pre-built binary of tee ###
#cp -ad ${outdir_bootloader_release}/bootloader_en.bin ${outfile_bootloader_subimg}
# Generate subimg
${basedir_tools}/prepend_image_info.sh ${outdir_bootloader_release}/bootloader_en.bin ${outfile_bootloader_subimg}
