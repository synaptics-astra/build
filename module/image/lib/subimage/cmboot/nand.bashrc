# Bash script: subimage: cmboot: nand

#############
# Functions #
#############

generate_cmboot_subimg() {
  ### use genimg to pack tzk and bl ###
  params=""

  if [ -e ${outfile_tee_subimg} ]; then
    params="$params -i TZK* -d ${outfile_tee_subimg}"
  else
    echo "no tee subimage found!!!"
    exit 1
  fi

  if [ -e ${outfile_bootloader_subimg} ]; then
    params="$params -i BTLR -d ${outfile_bootloader_subimg}"
  else
    echo "no bootloader found!!!"
    exit 1
  fi

  if [ -e ${outfile_sysmgr_subimg} ]; then
    params="$params -i SMGR -d ${outfile_sysmgr_subimg}"
  else
    echo "no sysmgr found!!!"
    exit 1
  fi

  echo "######$params"
  ${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/genimg -n cmboot -A 4096 $params -o ${cmboot_packimg}
  rm ${outdir_cmboot}/*.header
  rm ${outdir_cmboot}/*.header.filler
}

mkdir -p ${outdir_cmboot}
generate_cmboot_subimg

### Generate subimg ###
if [ "is${CONFIG_NO_PREPEND_IMG_INFO}" = "isy" ]; then
  cp ${cmboot_subimg} ${outfile_cmboot_subimg}
else
  ${basedir_tools}/prepend_image_info.sh ${cmboot_packimg} ${outfile_cmboot_subimg}
fi
