# Bash script: subimage: preboot: emmc

### Constants and variables ###
emmc_preboot_block_size=$(( 512*1024 ))

### Copy pre-built binary of preboot ###
cp -ad ${outdir_preboot_release}/preboot_esmt.bin ${outfile_preboot_subimg}

### Check the size ###
f_len=$(stat -c %s ${outfile_preboot_subimg})
[ ! ${f_len} -gt ${emmc_preboot_block_size} ]
