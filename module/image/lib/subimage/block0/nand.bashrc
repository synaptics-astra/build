# Bash script: subimage: block0: nand

# Command and arguments
if [ "is${syna_chip_name}" = "isklamath" ]; then
  cmd2run="${opt_basedir_tools}/${syna_chip_name}/mk_nandblock0_image"
  cmd2run="${cmd2run} --page-size=2048"
  cmd2run="${cmd2run} --block-size=131072"
  cmd2run="${cmd2run} --nand-blk-num=$[${nand_param_boot_part_size}/131072]"
else
  cmd2run="${opt_basedir_tools}/mk_nandblock0_image"
  cmd2run="${cmd2run} --page-size=${nand_param_page_size}"
  cmd2run="${cmd2run} --block-size=${nand_param_block_size}"
  cmd2run="${cmd2run} --ecc-strength=${nand_param_ecc_strength}"
  cmd2run="${cmd2run} --nand-blk-num=$[${nand_param_boot_part_size}/${nand_param_block_size}]"
fi

cmd2run="${cmd2run} ${outfile_block0_subimg}"

# Run command
eval "$cmd2run"
