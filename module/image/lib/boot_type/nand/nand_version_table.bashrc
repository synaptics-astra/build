# Bash script: boot_type: NAND: version table

# Generate version table
exec2run=${opt_bindir_host}/parse_pt
[ -x ${exec2run} ]

cmd_args=""
cmd_args="${cmd_args} 0 0"
cmd_args="${cmd_args} ${nand_param_block_size} ${nand_param_total_size}"
cmd_args="${cmd_args} ${workdir_product_config}/nand.pt"

cmd_args="${cmd_args} ${outdir_subimg_intermediate}/linux_params_mtdparts"
cmd_args="${cmd_args} ${outdir_subimg_intermediate}/version_table"
cmd_args="${cmd_args} ${outdir_subimg_intermediate}/subimglayout"

eval $exec2run "$cmd_args"

# Update CRC
exec2run=${opt_bindir_host}/crc

cmd_args=""
cmd_args="${cmd_args} -a"
cmd_args="${cmd_args} ${outdir_subimg_intermediate}/version_table"

eval $exec2run "$cmd_args"

# Clean up
unset -v cmd_args
unset -v exec2run
