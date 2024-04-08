# Bash script: subimage: fastboot: emmc

#############
# Functions #
#############

get_image_aligned() {
  f_input=$1; shift
  align_size=$1; shift

  ### Check input file ###
  [ -f $f_input ]

  f_size=`stat -c %s ${f_input}`
  append_size=`expr ${align_size} - ${f_size} % ${align_size}`

  if [ ${append_size} -lt ${align_size} ]; then
    dd if=/dev/zero of=${f_input} bs=1 seek=${f_size} count=${append_size} conv=notrunc
  fi
}


# Constants and variables
emmc_preboot_block_size=$(( 512*1024 ))
emmc_bootarea_max_size=$(( 2048*1024 ))

# Generate subimg with prepend header
${basedir_tools}/prepend_image_info.sh ${outdir_fastboot_release}/fastboot_en.bin ${outfile_fastboot_subimg}

# Packaging fastboot image for bg4ct
if [ "${syna_chip_name}" = "bg4ct" ]; then

  [ -f ${outfile_preboot_subimg} ]
  [ -f ${outfile_fastboot_subimg} ]

  ### Check the size ###
  f_len=$(stat -c %s ${outfile_preboot_subimg})
  [ ! ${f_len} -gt ${emmc_preboot_block_size} ]

  f_len=$(stat -c %s ${outfile_fastboot_subimg})
  [ ! $(( ${f_len} + ${emmc_preboot_block_size} )) -gt ${emmc_bootarea_max_size} ]

  ### Apend fastboot subimg into preboot subimg ###
  cp -ad ${outfile_preboot_subimg} ${outfile_preboot_fastboot_subimg}
  get_image_aligned ${outfile_preboot_fastboot_subimg} ${emmc_preboot_block_size}
  cat ${outfile_fastboot_subimg} >> ${outfile_preboot_fastboot_subimg}
fi
