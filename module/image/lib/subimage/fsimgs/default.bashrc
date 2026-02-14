# Bash script: subimage: linux_bootimgs: nand

export PATH="/sbin:$PATH"

declare -a a_fsname
declare -a a_fstype

load_nand_flash_config() {
  local f_flash_cfg=${workdir_product_config}/flash_type.cfg
  [ -f $f_flash_cfg ] || { echo "Error: flash_type.cfg not found"; return 1; }

  local list_cfgs=$(cat $f_flash_cfg)

  for c in $list_cfgs; do
    local v=$(expr $c : "^nand_\(.*=.*\)")

    if [ "x$v" != "x" ]; then
      local param_name=$(echo $v | cut -d = -f 1)
      local param_val=$(echo $v | cut -d = -f 2)

      case "$param_name" in
        "page_size") nand_param_page_size=${param_val} ;;
        "block_size") nand_param_block_size=${param_val} ;;
        "boot_part_size") nand_param_boot_part_size=${param_val} ;;
        "total_size") nand_param_total_size=${param_val} ;;
        "ecc_strength") nand_param_ecc_strength=${param_val} ;;
        *) /bin/false ;;
      esac
    fi
  done

  nand_param_total_blocks=$(( ${nand_param_total_size}/${nand_param_block_size} ))
  nand_param_pages_per_block=$(( ${nand_param_block_size}/${nand_param_page_size} ))

  [ $(( ${nand_param_block_size}*${nand_param_total_blocks} )) -eq ${nand_param_total_size} ] || { echo "Error: invalid NAND parameters"; return 1; }
  [ $(( ${nand_param_page_size}*${nand_param_pages_per_block} )) -eq ${nand_param_block_size} ] || { echo "Error: invalid NAND block parameters"; return 1; }
}

parse_nand_partition_table() {
  local f_nand_pt=${workdir_product_config}/nand.pt
  [ -f $f_nand_pt ] || { echo "Error: nand.pt not found"; return 1; }

  local fs_name=$1
  [ -n "$fs_name" ] || { echo "Error: filesystem name not provided"; return 1; }

  grep "^[0-9].*${fs_name}" $f_nand_pt | {
    read size name rest
    if [ -n "$size" ]; then
      size=${size%M}
      size=${size%B}
      echo "${size}"
    else
      echo "0"
    fi
  }
}

calculate_ubifs_parameters() {
  local vol_size_mib=$1
  [ -n "$vol_size_mib" ] || { echo "Error: volume size not provided"; return 1; }

  local page_size=${nand_param_page_size}
  local block_size=${nand_param_block_size}

  local leb_size=$(( ${block_size} - 2*${page_size} ))

  local vol_size_bytes=$(( ${vol_size_mib} * 1024 * 1024 ))

  local partition_peb_count=$(( ${vol_size_bytes} / ${block_size} ))

  local ubi_reserved_pebs=8

  local max_leb_count=$(( ${partition_peb_count} - ${ubi_reserved_pebs} ))

  local actual_vol_size=$(( ${max_leb_count} * ${leb_size} ))

  echo "leb_size=${leb_size},max_leb_count=${max_leb_count},actual_vol_size=${actual_vol_size}"
}

#############
# Functions #
#############

get_fsimg_list() {
  v=${CONFIG_RUNTIME_FILESYSTEMS}
  v=${v//,/ }
  [ "x${v}" != "x" ]

  local -i idx
  idx=0

  local fs
  local fsname
  local fstype
  for fs in ${v}; do
    #fs=${fs//\(/ }
    #fs=${fs//\)/}
    echo $idx
    echo $fs

    fsname=$(expr $fs : "^\(.*\)(.*)")
    fstype=$(expr $fs : "^.*(\(.*\))")

    [ "x${fsname}" != "x" ]
    [ "x${fstype}" != "x" ]

    if [ "$fsname" == "ramdisk" ]; then
      continue
    fi

    a_fsname[$idx]=$fsname
    a_fstype[$idx]=$fstype

    let idx=idx+1
  done
}

handle_fs_subdir() {
  echo "Total fsimgs: ${#a_fsname[*]}"
  if [ ${#a_fsname[*]} -eq 2 ] || [ ${#a_fsname[*]} -eq 3 ]; then
    if [ "${a_fsname[1]}" = "app" ]; then
      rm -frv ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/app
      if [ ! -d "${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/home/galois" ]; then
        mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/home/galois
      fi
      mv -v ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/home/galois ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/app
      mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/home/galois
    else
      echo "Create empty ${a_fsname[1]} folder"
      mkdir -pv ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${a_fsname[1]}
    fi
    if [ "is${CONFIG_NAND_FACTORY}" = "isy" ] && [ "${a_fsname[2]}" = "factory_setting" ]; then
      mkdir -pv ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/factory_setting
      cp -ad ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preboot/preboot_esmt.bin.ext ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/factory_setting/production.subimg
    fi
  fi

  if [ "${a_fsname[0]}" = "rootfs" ]; then
    rm -frv ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/rootfs
    cp -ad ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS} ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/rootfs
  else
    [ "${a_fsname[0]}" = "system" ]
  fi
}

create_filesystem_image() {
  local fsname
  local fstype

  fsname=$1; shift; [ "x${fsname}" != "x" ]
  fstype=$1; shift; [ "x${fstype}" != "x" ]

  case "$fstype" in
    "squashfs")
      mkfsimg_squashfs ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${fsname} ${outdir_subimg_intermediate}/${fsname}.subimg
      ;;
    "yaffs2")
      mkfsimg_yaffs2 ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${fsname} ${outdir_subimg_intermediate}/${fsname}.subimg
      ;;
    "ext4")
      mkfsimg_ext4 ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${fsname} ${outdir_subimg_intermediate}/${fsname}.subimg
      ;;
    "ubifs")
      mkfsimg_ubifs ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${fsname} ${outdir_subimg_intermediate}/${fsname}.subimg
      ;;
    *)
      /bin/false
      ;;
  esac
}

mkfsimg_squashfs_for_usbboot() {
  fs_dstimg=$1; shift; [ "x${fs_dstimg}" != "x" ]

  local ramdisk_workdir="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/usbboot/ramdisk"
  local ramdisk_rootfs_dir="${ramdisk_workdir}/rootfs"
  local path_sdk_kinit="${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_RUNTIME_REL_PATH}/intermediate/ramdisk"

  # Copy files to rootfs directory
  mkdir -p ${ramdisk_rootfs_dir}
  mkdir -p ${ramdisk_rootfs_dir}/home/galois

  cp -ad ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/. ${ramdisk_rootfs_dir}/.
  if [ -d  ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/app ]; then
    cp -ad ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/app/. ${ramdisk_rootfs_dir}/home/galois
  fi
  # Copy 'kinit'
  mkdir -p ${ramdisk_workdir}/kinit
  cp -ad ${path_sdk_kinit}/. ${ramdisk_workdir}/kinit/.

  # Remove unused files
  rm -fr ${ramdisk_rootfs_dir}/usr/arm-unknown-linux-gnueabi/

  # Modify runtime
  local f_init_rcs=${ramdisk_rootfs_dir}/etc/init.d/rcS
  mv $f_init_rcs ${f_init_rcs}.old
  cat ${f_init_rcs}.old \
          | sed -e '/^.*mount_part.*$/d' \
          | sed -e '/^.*mount.*\/galois.*$/d' \
          | sed -e '/^.*mount.*\/dev\/block\/.*$/d' \
          | sed -e '/^.*mount.*\/factory_setting.*$/d' \
          | sed -e '/^.*mount.*\/cache.*$/d' \
          > $f_init_rcs
  chmod +x $f_init_rcs

  # Generate squashfs file
  fakeroot mksquashfs ${ramdisk_rootfs_dir} ${ramdisk_workdir}/kinit/.rootfs-squashfs.bin -noappend

  # Generate initrd
  pushd ${ramdisk_workdir}/kinit || exit 1
  find . | cpio --create --format='newc' | gzip -c -9 > $fs_dstimg
  popd
}

mkfsimg_squashfs() {
  local fs_srcdir
  local fs_dstimg

  fs_srcdir=$1; shift; [ "x${fs_srcdir}" != "x" ]
  fs_dstimg=$1; shift; [ "x${fs_dstimg}" != "x" ]

  [ -d $fs_srcdir ]

  fakeroot mksquashfs ${fs_srcdir} ${fs_dstimg} -noappend
}

mkfsimg_yaffs2() {
  local fs_srcdir
  local fs_dstimg

  fs_srcdir=$1; shift; [ "x${fs_srcdir}" != "x" ]
  fs_dstimg=$1; shift; [ "x${fs_dstimg}" != "x" ]

  [ -d $fs_srcdir ]

  local exec2run
  local cmd_args

  exec2run="${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/mkyaffs2img"
  cmd_args=""
  cmd_args="${cmd_args} -q"
  cmd_args="${cmd_args} --fakeroot"
  cmd_args="${cmd_args} -s ${CONFIG_NAND_PAGE_SIZE}"
  cmd_args="${cmd_args} -e ${nand_param_pages_per_block}"
  cmd_args="${cmd_args} -o 32"
  cmd_args="${cmd_args} -r ${fs_srcdir}"
  cmd_args="${cmd_args} ${fs_dstimg}"

  eval $exec2run "$cmd_args"
}

mkfsimg_ext4() {
  local fs_srcdir
  local fs_dstimg

  fs_srcdir=$1; shift; [ "x${fs_srcdir}" != "x" ]
  fs_dstimg=$1; shift; [ "x${fs_dstimg}" != "x" ]

  [ -d $fs_srcdir ]

  # Check related tools
  type genext2fs
  type e2fsck
  type tune2fs

  local exec2run
  local cmd_args

  ### Get System partition size
  sys_part_size=`cat  ${outdir_subimg_intermediate}/emmc_part_list | sed s/[[:space:]*]//g | grep "${system_partition_name}" | sed -n '1p' | cut -d',' -f3`
  sys_part_size=$sys_part_size"000"

  echo $sys_part_size

  # Create subimg with EXT2 filesystem
  exec2run="genext2fs"
  cmd_args="--squash-uids -N 2290"
  ### FIXME: filesystem image size is hardcoded ###
  cmd_args="${cmd_args} -b $sys_part_size"
  cmd_args="${cmd_args} -d ${fs_srcdir}"
  cmd_args="${cmd_args} ${fs_dstimg}"
  eval $exec2run "$cmd_args"

  # Check filesystem
  exec2run="e2fsck"
  cmd_args="-f -y"
  cmd_args="${cmd_args} ${fs_dstimg}"
  eval $exec2run "$cmd_args"

  # Convert to EXT4
  exec2run="tune2fs"
  cmd_args="-O extents,uninit_bg,dir_index"
  cmd_args="${cmd_args} ${fs_dstimg}"
  eval $exec2run "$cmd_args"
}

mkfsimg_ubifs() {
  local fs_srcdir
  local fs_dstimg

  fs_srcdir=$1; shift; [ "x${fs_srcdir}" != "x" ]
  fs_dstimg=$1; shift; [ "x${fs_dstimg}" != "x" ]

  [ -d $fs_srcdir ]

  ### copy linux kernel into boot folder ###
  mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/rootfs/boot/
  cp ${outdir_subimg_intermediate}/linux_bootimgs.subimg ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/rootfs/boot/

  local fs_dstubi
  local exec2run
  local cmd_args
  local ubifs_params
  local leb_size
  local max_leb_count
  local vol_size_mib
  local block_size_kib

  ### Load NAND flash configuration ###
  load_nand_flash_config || exit 1

  vol_size_mib=$(parse_nand_partition_table "${fsname}")
  [ $? -eq 0 ] && [ "${vol_size_mib}" -gt 0 ] || { echo "Error: failed to parse partition size for ${fsname}"; return 1; }

  ubifs_params=$(calculate_ubifs_parameters ${vol_size_mib})
  leb_size=$(echo ${ubifs_params} | cut -d',' -f1 | cut -d'=' -f2)
  max_leb_count=$(echo ${ubifs_params} | cut -d',' -f2 | cut -d'=' -f2)
  actual_vol_size=$(echo ${ubifs_params} | cut -d',' -f3 | cut -d'=' -f2)
  block_size_kib=$(( ${nand_param_block_size} / 1024 ))
  actual_vol_size_mib=$(( ${actual_vol_size} / 1024 / 1024 ))

  fs_dstubi=${fs_dstimg}.ubifs
  exec2run="mkfs.ubifs"
  #cmd_args=" -F -r ${fs_srcdir} -m ${nand_param_page_size} -e ${leb_size} -c ${max_leb_count} -o ${fs_dstubi} --hash-algo=sha256 --auth-cert=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/linux/intermediate/certs/signing_key.x509 --auth-key=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/linux/intermediate/certs/signing_key.pem"
  cmd_args=" -F -r ${fs_srcdir} -m ${nand_param_page_size} -e ${leb_size} -c ${max_leb_count} -o ${fs_dstubi}"
  eval $exec2run "$cmd_args"

  ubinize_cfg=${fs_dstimg}-ubinize.cfg
  echo "[rootfs-volume]" > ${ubinize_cfg}
  echo "mode=ubi" >> ${ubinize_cfg}
  echo "image=${fs_dstubi}" >> ${ubinize_cfg}
  echo "vol_id=0" >> ${ubinize_cfg}
  echo "vol_size=${actual_vol_size_mib}MiB" >> ${ubinize_cfg}
  echo "vol_type=dynamic" >> ${ubinize_cfg}
  echo "vol_name=${fsname}" >> ${ubinize_cfg}
  echo "vol_flags=autoresize" >> ${ubinize_cfg}

  exec2run="ubinize"
  cmd_args=" -vv -o ${fs_dstimg} -m ${nand_param_page_size} -p ${block_size_kib}KiB -s ${nand_param_page_size} ${ubinize_cfg}"
  eval $exec2run "$cmd_args"
}

########
# Main #
########

### Retrieve list of filesystem images ###
get_fsimg_list

### Split and rename filesystem subdir if necessary ###
handle_fs_subdir

### Generate filesystem images ###
idx=0
while [ $idx -lt ${#a_fsname[*]} ]; do
  create_filesystem_image ${a_fsname[$idx]} ${a_fstype[$idx]}
  let idx=idx+1
done

unset -v idx

unset -f get_fsimg_list
unset -f create_filesystem_image
unset -f mkfsimg_squashfs
unset -f mkfsimg_yaffs2
