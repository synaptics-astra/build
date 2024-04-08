# Bash script: subimage: preboot: nand

gen_preboot_subimg() {
  f_input=$1; shift

  ### Fill the gap ###
  f_len=$(stat -c %s ${f_input})
  [ ! $(( $f_len + 2048 )) -gt ${nand_param_boot_part_size} ]

  fill_length=$(( ${nand_param_boot_part_size} - 2048 - ${f_len} ))
  dd if=/dev/zero bs=$fill_length count=1 >> ${f_input}

  ### Append version table ###
  cat ${outdir_subimg_intermediate}/version_table >> ${f_input}

  ### Append to block size ###
  f_len=$(stat -c %s ${f_input})
  [ ! $f_len -gt ${nand_param_boot_part_size} ]

  fill_length=$(( ${nand_param_boot_part_size} - ${f_len} ))
  dd if=/dev/zero bs=$fill_length count=1 >> ${f_input}
}

### Copy pre-built binary of preboot ###
if [ "is${CONFIG_NAND_FACTORY}" = "isy" ]; then
  cp -ad ${outdir_preboot_release}/preboot_esmt_factory.bin ${outfile_preboot_subimg}
  cp -ad ${outdir_preboot_release}/preboot_esmt.bin ${outdir_preboot_release}/preboot_esmt.bin.ext
  gen_preboot_subimg ${outdir_preboot_release}/preboot_esmt.bin.ext
else
  cp -ad ${outdir_preboot_release}/preboot_esmt.bin ${outfile_preboot_subimg}
fi

gen_preboot_subimg ${outfile_preboot_subimg}

