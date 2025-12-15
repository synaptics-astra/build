
. build/header.rc
. build/chip.rc
. build/install.rc
. build/security.rc

echo "Build/pack preboot mcu"

genx_secure_image() {
  v_image_type=$1; shift
  in_key_type=$1; shift
  in_extras=$1; shift
  in_length=$1; shift
  f_input=$1; shift
  f_output=$1; shift

  ### Check input file ###
  [ -f $f_input ]

  ### Exectuable for generating secure image ###
  if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
    exec_cmd=${security_tools_path}gen_x_secure_image
    [ -x $exec_cmd ]
  else
    exec_cmd=gen_x_secure_image
  fi

  ### Prepare arguments ###
  unset exec_args

  # Other parameters
  exec_args="${exec_args} --chip-name=${syna_chip_name}"
  exec_args="${exec_args} --chip-rev=${syna_chip_rev}"
  exec_args="${exec_args} --img_type=$v_image_type"
  exec_args="${exec_args} --key_type=${in_key_type}"

  #exec_args="${exec_args} --seg_id=0x00000000"
  #exec_args="${exec_args} --seg_id_mask=0xFFFFFFFF"
  #exec_args="${exec_args} --version=0x00000001"
  #exec_args="${exec_args} --version_mask=0xFFFFFFFF"
  exec_args="${exec_args} --length=$in_length"
  exec_args="${exec_args} --extras=$in_extras"
  exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"
  exec_args="${exec_args} --tool-version=genx_v3"

  # Input and output
  exec_args="${exec_args} --in_payload=${f_input} --out_store=${f_output}"

  ### Generate secure image ###
  # echo @@@@ ${exec_cmd} "${exec_args}"
  eval ${exec_cmd} "${exec_args}"
}

syna_platform_name="${CONFIG_PREBOOT_PLATFORM}"

preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}
preboot_outdir_build_release="${preboot_outdir_release}/intermediate/release"

mcuboot_topdir="${CONFIG_SYNA_SDK_PATH}/boot/mcu"
boot_security_topdir="${CONFIG_SYNA_SDK_PATH}/boot/security"
boot_security_prebuilts_dir="${boot_security_topdir}/images/chip/bcm_ree"
boot_security_prebuilts_dir="${boot_security_prebuilts_dir}/${syna_chip_name}/${syna_chip_rev}/generic"
boot_security_keys_dir="${boot_security_prebuilts_dir}/key_stores"

if [ -d "${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}" ]; then
  f_BL=${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}/apbl_output.bin
  f_BL_EXTRA=${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}/apbl_extras.bin
  f_SYSMGR=${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}/fw_output.bin
  f_SYSMGR_EXTRA=${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}/fw_extras.bin
else
  echo "built"
  ### Build MCU BOOT ###
  cd ${mcuboot_topdir} || exit 1
  ./build
  cd - || exit 1
fi

f_K0_SYNA_store=${boot_security_keys_dir}/K0_SYNA_store_4k.bin
f_K0_OEM_store=${boot_security_keys_dir}/K0_OEM_store_4k.bin
f_K0_3rd_store=${boot_security_keys_dir}/K0_3RD_store_4k.bin
f_K1_A_store=${boot_security_keys_dir}/K1_A_store_4k.bin
f_K1_B_store=${boot_security_keys_dir}/K1_B_store_4k.bin
f_K1_C_store=${boot_security_keys_dir}/K1_C_store_4k.bin
f_K1_D_store=${boot_security_keys_dir}/K1_D_store_4k.bin

f_SPK=${boot_security_prebuilts_dir}/spk.bin

echo ${boot_security_keys_dir}
echo ${boot_security_prebuilts_dir}
echo "${mcuboot_topdir}/cm52/image/chip/${syna_chip_name}/${syna_platform_name}"

[[ -f $f_K0_SYNA_store && -f $f_K0_OEM_store && -f $f_K0_3rd_store && -f $f_K1_A_store && -f $f_K1_B_store && -f $f_K1_C_store && -f $f_K1_D_store && -f $f_SPK && -f $f_BL && -f $f_SYSMGR && -f $f_BL_EXTRA && -f $f_SYSMGR_EXTRA ]]

mkdir -p ${preboot_outdir_build_release}

cp $f_K0_SYNA_store ${preboot_outdir_build_release}/K0_SYNA_store_4k.bin
cp $f_K0_OEM_store ${preboot_outdir_build_release}/K0_OEM_store_4k.bin
cp $f_K0_3rd_store ${preboot_outdir_build_release}/K0_3RD_store_4k.bin
cp $f_K1_A_store ${preboot_outdir_build_release}/K1_A_store_4k.bin
cp $f_K1_B_store ${preboot_outdir_build_release}/K1_B_store_4k.bin
cp $f_K1_C_store ${preboot_outdir_build_release}/K1_C_store_4k.bin
cp $f_K1_D_store ${preboot_outdir_build_release}/K1_D_store_4k.bin

cp $f_SPK ${preboot_outdir_build_release}/spk.bin

# 128KB space for spk
truncate --size=131072 ${preboot_outdir_build_release}/spk.bin

# for xspi, shall reserve 64KB for bl image
genx_secure_image "BL" "ree" $f_BL_EXTRA 0x0 $f_BL ${preboot_outdir_build_release}/bl_en.bin

genx_secure_image "SM" "ree" $f_SYSMGR_EXTRA 0x0 $f_SYSMGR ${preboot_outdir_build_release}/sysmgr_en.bin

cat ${preboot_outdir_build_release}/K0_SYNA_store_4k.bin > ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K0_OEM_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K0_3RD_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K1_A_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K1_B_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K1_C_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/K1_D_store_4k.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/spk.bin >> ${preboot_outdir_release}/preboot_ksb.bin
cat ${preboot_outdir_build_release}/bl_en.bin >> ${preboot_outdir_release}/preboot_ksb.bin

/bin/cp ${preboot_outdir_build_release}/sysmgr_en.bin ${preboot_outdir_release}/sysmgr_en.bin

echo "Done pack of preboot mcu firmware"
