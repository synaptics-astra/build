# Bash script: subimage: preboot: usb

### Constants and variables ###

preboot_outdir_build_release="${outdir_preboot_release}/intermediate/release"

### Copy pre-built binary of preboot ###

### for MCU only ###
if [ "is${CONFIG_GENX_MCU}" = "isy" ]; then
	cp -ad ${preboot_outdir_build_release}/key.bin ${outdir_subimg_intermediate}/
	cp -ad ${preboot_outdir_build_release}/spk_raw.bin ${outdir_subimg_intermediate}/spk.bin
	cp -ad ${preboot_outdir_build_release}/bl_en.bin ${outdir_subimg_intermediate}/m52bl.bin
	cp -ad ${preboot_outdir_build_release}/sysmgr_en.bin ${outdir_subimg_intermediate}/sysmgr.subimg
	return
fi

### eROM ###
cp -ad ${preboot_outdir_build_release}/erom.bin ${outdir_subimg_intermediate}/

### BCM Kernel ###
cp -ad ${preboot_outdir_build_release}/K0_BOOT_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K0_TEE_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_BOOT_A_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_BOOT_B_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_TEE_A_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/bcm_kernel.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_TEE_B_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_TEE_C_store.bin ${outdir_subimg_intermediate}/
cp -ad ${preboot_outdir_build_release}/K1_TEE_D_store.bin ${outdir_subimg_intermediate}/

### Boot Monitor ###
cp -ad ${preboot_outdir_build_release}/boot_monitor.bin ${outdir_subimg_intermediate}/

### SCS Data Parameter ###
cp -ad ${preboot_outdir_build_release}/scs_data_param.sign ${outdir_subimg_intermediate}/

### Sysinit ###
cp -ad ${preboot_outdir_build_release}/sysinit_en.bin ${outdir_subimg_intermediate}/

if [ "is${syna_chip_name}" = "isdolphin" ]; then
    cp -ad ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin ${outdir_subimg_intermediate}/
    cp -ad ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin ${outdir_subimg_intermediate}/
fi

### Miniloader ###
cp -ad ${preboot_outdir_build_release}/miniloader_en.bin ${outdir_subimg_intermediate}/
