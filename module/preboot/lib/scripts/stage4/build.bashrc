# Bash script: stage 4 build

#0. NOCS flow only for all chips
echo "nocs release for ${syna_chip_name}:${syna_chip_rev}:${nocs_types}"

mkdir -p ${CONFIG_SYNA_SDK_REL_PATH}/boot
#1. copy corresponding type-X prebuilt images to release
syna_nocs_path=boot/security/images/chip/${syna_chip_name}/${syna_chip_rev}/nocs/${nocs_types}/
if [ -d "${topdir}/${syna_nocs_path}" ]; then
  mkdir -p ${CONFIG_SYNA_SDK_REL_PATH}/${syna_nocs_path}
  cp -ad ${topdir}/${syna_nocs_path}/* ${CONFIG_SYNA_SDK_REL_PATH}/${syna_nocs_path}
else
  echo "there is no nocs ${nocs_types} images for ${syna_chip_name} ${syna_chip_rev}"
  exit 1;
fi
#2. copy build/pack script to release
mkdir -p ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/
cp ${topdir}/boot/preboot/build ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
cp ${topdir}/boot/preboot/pack ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
cp -rf ${topdir}/boot/preboot/lib ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
cp -rf ${topdir}/boot/preboot/tools ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot

#3. release miniloader source code
cp -rf ${topdir}/boot/preboot/fw_include ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
cp -rf ${topdir}/boot/preboot/include ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
cp -rf ${topdir}/boot/preboot/tools ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot
mkdir -p ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source
cp -rf ${topdir}/boot/preboot/source/miniloader ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source
rm ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source/miniloader/bm_normal.c
rm ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source/miniloader/*ddr.lds
cp -rf ${topdir}/boot/preboot/source/common ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source
mkdir -p ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source/sysinit/hwinit/release/diag/chip/${syna_chip_name}/${syna_chip_rev}
cp ${topdir}/boot/preboot/source/sysinit/hwinit/release/diag/chip/${syna_chip_name}/${syna_chip_rev}/libminiddr_init.a ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source/sysinit/hwinit/release/diag/chip/${syna_chip_name}/${syna_chip_rev}/
cp ${topdir}/boot/preboot/source/sysinit/hwinit/release/diag/chip/${syna_chip_name}/${syna_chip_rev}/diag_ddr_init.h ${CONFIG_SYNA_SDK_REL_PATH}/boot/preboot/source/sysinit/hwinit/release/diag/chip/${syna_chip_name}/${syna_chip_rev}/
# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
