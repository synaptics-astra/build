# Bash script: subimage: preboot: xspi

if [ "is${CONFIG_GENX_MCU}" = "isy" ]; then
if [ "is${CONFIG_UBOOT_SPIUBOOT}" = "isy" ]; then
  truncate --size=258048 ${outdir_preboot_release}/preboot_ksb.bin
  truncate --size=204800 ${outdir_preboot_release}/sysmgr_en.bin
fi
cp -ad ${outdir_preboot_release}/preboot_ksb.bin ${outfile_preboot_subimg}
cp -ad ${outdir_preboot_release}/sysmgr_en.bin ${outdir_subimg_intermediate}/sysmgr.subimg
fi
