# Bash script: subimage: linux_bootimgs: nand

export PATH="/sbin:$PATH"

declare -a a_fsname
declare -a a_fstype

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
