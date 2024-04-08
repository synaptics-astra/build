#!/bin/bash

source build/header.rc
source build/chip.rc
source build/security.rc

subimg_name=${2}

imagedir=${topdir}/build/module/image
basedir_script_subimg=${imagedir}/lib/subimage

if [ "is${subimg_name}" = "is" ]; then
	echo "Usage: make image-pack subimg=[subimg name]"
	echo "       result will be at out/[product]/target/obj/PACKAGING/subimg_intermediate/"
	echo "       it's for engineer debug purpose"
	echo "       subimg list:"
	subimg_list=`ls ${basedir_script_subimg} | sed 'N;s/\n/ /;b'`
	echo "           "${subimg_list}
	exit 0
fi

if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  script_dir=${imagedir}/lib/boot_type/emmc
fi
if [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  script_dir=${imagedir}/lib/boot_type/nand
fi

source ${script_dir}/packaging.bashrc single ${subimg_name}
