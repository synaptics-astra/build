# Bash script: boot_type: NAND

#############
# Functions #
#############

nand_gen_subimg_info() {
  local subimg_file
  local subimg_name

  subimg_file=$1; shift
  subimg_name=$1; shift

  [ -f ${outdir_subimg_intermediate}/${subimg_file}.subimg ]

  # Retrieve layout of the subimage
  local subimg_layout
  subimg_layout=$(cat ${outdir_subimg_intermediate}/subimglayout | grep "^${subimg_name}")
  [ "x${subimg_layout}" != "x" ]
  subimg_layout=(${subimg_layout})

  local v_start_block_index
  local v_num_blocks
  local v_data_type
  local v_partition_type

  v_start_block_index=${subimg_layout[1]}
  v_num_blocks=${subimg_layout[2]}
  v_data_type=${subimg_layout[3]}
  v_partition_type=${subimg_layout[4]}

  [ "x${v_start_block_index}" != "x" ]
  [ "x${v_num_blocks}" != "x" ]
  [ "x${v_data_type}" != "x" ]
  [ "x${v_partition_type}" != "x" ]

  # Copy subimg file to release directory
  cp -ad ${outdir_subimg_intermediate}/${subimg_file}.subimg ${outdir_product_release_unand}/subimgs/${subimg_name}.subimg

  # Generate info file
  local exec2run
  local cmd_args

  exec2run="${opt_bindir_host}/gen_subimg_info"

  cmd_args=
  cmd_args="${cmd_args} --name ${subimg_name}"
  cmd_args="${cmd_args} --major \"0\" --minor \"0\""
  cmd_args="${cmd_args} --reserved_blocks 0"
  cmd_args="${cmd_args} --start_blkind ${v_start_block_index}"
  cmd_args="${cmd_args} --num_blocks ${v_num_blocks}"
  cmd_args="${cmd_args} --data_type ${v_data_type}"
  cmd_args="${cmd_args} --partition_type ${v_partition_type}"
  cmd_args="${cmd_args} --output ${outdir_product_release_unand}/subimgs/${subimg_name}.subimg.info"
  cmd_args="${cmd_args} ${outdir_product_release_unand}/subimgs/${subimg_name}.subimg"

  eval $exec2run "$cmd_args"
}

unand_gen_images() {
  local unandimg_name
  local list_parts

  unandimg_name=$1; shift
  list_parts=$1; shift

  local workdir_subimgs
  local workdir_release

  local workdir_subimgs=${outdir_product_release_unand}/subimgs
  local workdir_release=${outdir_product_release_unand}

  local exec2run
  local cmd_args

  [ "x${unandimg_name}" != "x" ]

  exec2run="${opt_bindir_host}/gen_uniimg"

  cmd_args="${cmd_args} -d ${workdir_subimgs}"
  cmd_args="${cmd_args} -p ${nand_param_page_size}"
  cmd_args="${cmd_args} -b ${nand_param_block_size}"
  cmd_args="${cmd_args} -c ${nand_param_total_size}"
  cmd_args="${cmd_args} -j $(date +%Y%m%d)"
  cmd_args="${cmd_args} -n $(date +%H%M)"
  cmd_args="${cmd_args} --cpu_type A0"
  cmd_args="${cmd_args} --ddr_type DDR3"
  cmd_args="${cmd_args} --ddr_channel DDR_DUAL_CHANNEL"
  cmd_args="${cmd_args} -o ${workdir_release}/${unandimg_name}.img"

  for p in ${list_parts}; do
    cmd_args="${cmd_args} $p"
  done

  eval $exec2run "$cmd_args"
}

########
# Main #
########

#
# Preparation
#

#
# Preparation
#
opt_basedir_tools=${CONFIG_SYNA_SDK_PATH}/${CONFIG_TOOLS_BIN_PATH}
basedir_tools=${CONFIG_SYNA_SDK_PATH}/${CONFIG_TOOLS_BIN_PATH}
opt_bindir_host=${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}
outdir_subimg_intermediate=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/obj/PACKAGING/subimg_intermediate
workdir_product_config=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
mkdir -p ${outdir_subimg_intermediate}


### NAND Flash Type ###
source ${script_dir}/nand_flash_type.bashrc

### Handle version table ###
source ${script_dir}/nand_version_table.bashrc

#
# Generate single subimage (for eng only)
#
if [ $# -eq 2 ]; then
  flag=${1}
  singleimage=${2}
  if [ "is${flag}" = "issingle" ]; then
    if [ "is${singleimage}" != "is" ]; then
      echo "pack ${singleimage} start"
      source ${basedir_script_subimg}/${singleimage}/common.bashrc
      source ${basedir_script_subimg}/${singleimage}/nand.bashrc
      echo "pack ${singleimage} done"
      exit 0
    fi
  fi
fi
#
# Generate subimages
#

### Block0 ###
source ${basedir_script_subimg}/block0/common.bashrc
source ${basedir_script_subimg}/block0/nand.bashrc

### Preboot ###
source ${basedir_script_subimg}/preboot/common.bashrc
source ${basedir_script_subimg}/preboot/nand.bashrc

### TEE ###
source ${basedir_script_subimg}/tee/common.bashrc
source ${basedir_script_subimg}/tee/nand.bashrc

### Bootloader ###
source ${basedir_script_subimg}/bootloader/common.bashrc
source ${basedir_script_subimg}/bootloader/nand.bashrc

### Kernel/RAMDISK ###
source ${basedir_script_subimg}/linux_bootimgs/common.bashrc
source ${basedir_script_subimg}/linux_bootimgs/nand.bashrc

### Filesystems ###
source ${basedir_script_subimg}/fsimgs/common.bashrc
source ${basedir_script_subimg}/fsimgs/nand.bashrc

### Key ###
source ${basedir_script_subimg}/key/common.bashrc
source ${basedir_script_subimg}/key/nand.bashrc

#
# Generate uNAND image
#

product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
outdir_product_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/release
outdir_product_release_unand=${outdir_product_release}/u2nandimg
mkdir -p ${outdir_product_release_unand}/subimgs

cp -ad ${outdir_subimg_intermediate}/subimglayout ${outdir_product_release_unand}/subimgs/.

part_list_full=`cat ${outdir_subimg_intermediate}/subimglayout | awk '{print $1}'`
# Prepare subimg info
for part in $part_list_full; do
	echo $part
	case $part in
		"pre-bootloader")
			module="preboot"
			;;
		"tzk_normal"|"tzk_normalB")
			module="tee"
			;;
		"bl_normal"|"bl_normalB")
			module="bootloader"
			;;
		"key_1st"|"key_2nd")
			module="key"
			;;
		"boot"|"recovery")
			module="linux_bootimgs"
			;;
		*)
			module=$part
			;;
	esac
	nand_gen_subimg_info $module $part
done

#nand_gen_subimg_info "block0" "block0"
#nand_gen_subimg_info "preboot" "pre-bootloader"
#nand_gen_subimg_info "tee" "tzk_normal"
#nand_gen_subimg_info "tee" "tzk_normalB"
#nand_gen_subimg_info "bootloader" "bl_normal"
#nand_gen_subimg_info "bootloader" "bl_normalB"
#nand_gen_subimg_info "linux_bootimgs" "boot"
#nand_gen_subimg_info "linux_bootimgs" "recovery"
#nand_gen_subimg_info "key" "key_1st"
#nand_gen_subimg_info "key" "key_2nd"
#nand_gen_subimg_info "rootfs" "rootfs"
#nand_gen_subimg_info "app" "app"

# Create uNAND images
#part_list_bootonly="block0 pre-bootloader post-bootloader postbootloaderB tz_en tz_en-B bootimgs"
#part_list_bootonly="block0 pre-bootloader bl_normal bl_normalB tzk_normal tzk_normalB boot recovery key_1st key_2nd"
#part_list_full="${part_list_bootonly} rootfs app"
#part_list_full="${part_list_bootonly} rootfs"

#unand_gen_images "uNAND_boot" "${part_list_bootonly}"
unand_gen_images "uNAND_full" "${part_list_full}"
