# Bash script: stage 3 build

gen_pmic_config() {
  # Generate PMIC configuration binary
  pmic_generate=n
  pmic_type=1

  if [ "x${CONFIG_PMIC_IF_I2C}" = "xy" ] || [ "x${CONFIG_PMIC_IF_AUTO}" = "xy" ]; then
    if [ "x${CONFIG_PMIC_IF_AUTO}" = "xy" ]; then
      vcore_models="${CONFIG_VCORE_PMIC_MODEL_0:-none},${CONFIG_VCORE_PMIC_MODEL_1:-none},${CONFIG_VCORE_PMIC_MODEL_2:-none},${CONFIG_VCORE_PMIC_MODEL_3:-none}"
      vcpu_models="${CONFIG_VCPU_PMIC_MODEL_0:-none},${CONFIG_VCPU_PMIC_MODEL_1:-none},${CONFIG_VCPU_PMIC_MODEL_2:-none},${CONFIG_VCPU_PMIC_MODEL_3:-none}"
      echo "Generating PMIC configuration with Auto Detection"
      pmic_type=4
      pmic_generate=y
    else
      vcore_model=$(echo ${CONFIG_VCORE_PMIC_MODEL} | sed 's/"//g')
      vcpu_model=$(echo ${CONFIG_VCPU_PMIC_MODEL} | sed 's/"//g')
      vcore_models="${vcore_model:-none},none,none,none"
      vcpu_models="${vcpu_model:-none},none,none,none"
      pmic_type=1
      if [ "x${vcore_model}" != "x" ] || [ "x${vcpu_model}" != "x" ]; then
        echo "Generating PMIC configuration for I2C mode"
        pmic_generate=y
      fi
    fi

    if [ "x${pmic_generate}" = "xy" ]; then
      pmic_args="--output ${preboot_outdir_release}/pmic_config.bin"
      pmic_args="${pmic_args} --vcore-models ${vcore_models} --vcpu-models ${vcpu_models}"
      pmic_args="${pmic_args} --vcore-i2c-ch ${CONFIG_VCORE_PMIC_I2CCH_NUM} --vcpu-i2c-ch ${CONFIG_VCPU_PMIC_I2CCH_NUM}"
      if [ -n "${CONFIG_VCORE_PMIC_I2CCH}" ]; then
        pmic_args="${pmic_args} --vcore-i2c-ch-str ${CONFIG_VCORE_PMIC_I2CCH}"
      fi
      if [ -n "${CONFIG_VCPU_PMIC_I2CCH}" ]; then
        pmic_args="${pmic_args} --vcpu-i2c-ch-str ${CONFIG_VCPU_PMIC_I2CCH}"
      fi
      pmic_args="${pmic_args} --pmic-type ${pmic_type}"
      pmic_args="${pmic_args} --vcore-gpioh ${CONFIG_VCORE_PMIC_GPIOH:-255} --vcore-gpiol ${CONFIG_VCORE_PMIC_GPIOL:-255}"
      pmic_args="${pmic_args} --vcpu-gpioh ${CONFIG_VCPU_PMIC_GPIOH:-255} --vcpu-gpiol ${CONFIG_VCPU_PMIC_GPIOL:-255}"
    fi

  elif [ "x${CONFIG_PMIC_IF_PWM}" = "xy" ] || [ "x${CONFIG_PMIC_PWM_BACKEND_SMTIMER}" = "xy" ]; then
    if [ "x${CONFIG_PMIC_PWM_BACKEND_SMTIMER}" = "xy" ]; then
      echo "Generating PMIC configuration for SM Timer mode"
      pmic_type=3
    else
      echo "Generating PMIC configuration for PWM mode"
      pmic_type=2
    fi

    vcore_pwm_gpio=$(echo ${CONFIG_VCORE_PWM_GPIO} | sed 's/"//g')
    vcpu_pwm_gpio=$(echo ${CONFIG_VCPU_PWM_GPIO} | sed 's/"//g')

    pmic_args="--output ${preboot_outdir_release}/pmic_config.bin"
    pmic_args="${pmic_args} --pmic-type ${pmic_type} --vcore-pwm-gpio ${vcore_pwm_gpio} --vcpu-pwm-gpio ${vcpu_pwm_gpio}"
    pmic_args="${pmic_args} --vcore-models none,none,none,none --vcpu-models none,none,none,none"
    pmic_args="${pmic_args} --vcore-pwm-freq ${CONFIG_VCORE_PWM_FREQ_HZ:-0} --vcore-pwm-polarity ${CONFIG_VCORE_PWM_POLARITY:-0}"
    pmic_args="${pmic_args} --vcore-pwm-volt-min ${CONFIG_VCORE_PWM_VOLT_MIN_UV:-0} --vcore-pwm-volt-max ${CONFIG_VCORE_PWM_VOLT_MAX_UV:-0}"
    pmic_args="${pmic_args} --vcore-pwm-duty-min-volt ${CONFIG_VCORE_PWM_DUTY_AT_VOLT_MIN:-0} --vcore-pwm-duty-max-volt ${CONFIG_VCORE_PWM_DUTY_AT_VOLT_MAX:-0}"
    pmic_args="${pmic_args} --vcpu-pwm-freq ${CONFIG_VCPU_PWM_FREQ_HZ:-0} --vcpu-pwm-polarity ${CONFIG_VCPU_PWM_POLARITY:-0}"
    pmic_args="${pmic_args} --vcpu-pwm-volt-min ${CONFIG_VCPU_PWM_VOLT_MIN_UV:-0} --vcpu-pwm-volt-max ${CONFIG_VCPU_PWM_VOLT_MAX_UV:-0}"
    pmic_args="${pmic_args} --vcpu-pwm-duty-min-volt ${CONFIG_VCPU_PWM_DUTY_AT_VOLT_MIN:-0} --vcpu-pwm-duty-max-volt ${CONFIG_VCPU_PWM_DUTY_AT_VOLT_MAX:-0}"
    pmic_args="${pmic_args} --vcore-smtmr-gpio ${CONFIG_VCORE_SMTMR_GPIO:-255} --vcpu-smtmr-gpio ${CONFIG_VCPU_SMTMR_GPIO:-255}"
    pmic_generate=y
  fi

  if [ "x${pmic_generate}" = "xy" ]; then
    SDK_TOP=${topdir}
    BUILD_PREBOOT_PATH=${SDK_TOP}/build/module/preboot
    export BUILD_PREBOOT_PATH
    set -- ${pmic_args}
    ${topdir}/build/module/preboot/gen_pmic_config.sh "$@"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to generate PMIC configuration binary"
      exit 1
    fi
  else
    echo "Info: No PMIC configuration specified, skipping"
  fi
}

gen_bootflag_config() {
  if [ "x${CONFIG_PREBOOT_SKIP_FW}" = "xy" ]; then
    bootflag_args="${bootflag_args} --skip-fw"
  fi

  if [ "x${CONFIG_PREBOOT_FORCE_SPI}" = "xy" ]; then
    bootflag_args="${bootflag_args} --force-spi"
  fi

  bootflag_args="${bootflag_args} --output ${preboot_outdir_release}/bootflag_config.bin"
  ${topdir}/build/module/preboot/gen_bootflag_config.sh ${bootflag_args}

  if [ $? -eq 0 ]; then
    echo "BOOTFLAG configuration binary generated successfully"
  else
    echo "Error: Failed to generate BOOTFLAG configuration binary"
    exit 1
  fi
}

gen_boot_config() {
  gen_bootflag_config
  gen_pmic_config

  if [ ! -f ${preboot_outdir_release}/bootflag_config.bin ] || [ ! -f ${preboot_outdir_release}/pmic_config.bin ]; then
    echo "BOOT: skipping BOOT configuration generation"
    return 0
  fi

  echo "Padding BOOTFLAG with PMIC"
  cat ${preboot_outdir_release}/bootflag_config.bin ${preboot_outdir_release}/pmic_config.bin > ${preboot_outdir_release}/boot_config.bin

  boot_config_size=$(stat -c %s ${preboot_outdir_release}/boot_config.bin)
  if [ $boot_config_size -ne 256 ]; then
    echo "Error: BOOT configuration size is invalid"
    exit 1
  fi

  # Calculate Checksum
  tmp_file=$(mktemp)

  dd if="${preboot_outdir_release}/boot_config.bin" bs=4 skip=1 2>/dev/null | \
  od -An -t u4 -v -w4 > "$tmp_file"

  checksum=0
  while read -r val; do
    checksum=$(( (checksum ^ val) & 0xFFFFFFFF ))
  done < "$tmp_file"

  rm -f "$tmp_file"

  # use octal string to support POSIX printf
  checksum_octal=$(printf '\\%03o\\%03o\\%03o\\%03o' \
    $(( (checksum)       & 0xFF )) \
    $(( (checksum >> 8)  & 0xFF )) \
    $(( (checksum >> 16) & 0xFF )) \
    $(( (checksum >> 24) & 0xFF )) )

  printf "$checksum_octal" | dd of="${preboot_outdir_release}/boot_config.bin" bs=1 count=4 conv=notrunc status=none

  # Align preboot_esmt.bin to 512KB and place BOOT config at 509KB
  current_size=$(stat -c %s ${preboot_outdir_release}/preboot_esmt.bin)
  align_size=$((512 * 1024))  # 512KB
  reserved_size=$((3 * 1024))  # Reserve last 3KB for SPI boot (version_table 2KB + header 1KB)
  boot_config_offset=256  # BOOTFLAG config starts from 256 bytes offset of the block end
  
  # Calculate padding to make room for BOOT config at (512KB-3KB-256 bytes)
  target_size=$((align_size - reserved_size - boot_config_offset))
  if [ $current_size -gt $target_size ]; then
    echo "Error: preboot_esmt.bin size ($current_size) exceeds available space ($target_size) for BOOTFLAG config"
    exit 1
  fi
  
  padding_size=$((target_size - current_size))
  echo "Padding preboot_esmt.bin with ${padding_size} bytes"
  dd if=/dev/zero bs=1 count=${padding_size} >> ${preboot_outdir_release}/preboot_esmt.bin 2>/dev/null

  # Append BOOT config to the end of preboot
  cat ${preboot_outdir_release}/boot_config.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  
  # Also append BOOT config to factory version if it exists
  if [ -f ${preboot_outdir_release}/preboot_esmt_factory.bin ]; then
    # Align preboot_esmt_factory.bin to 512KB and place BOOT config at 509KB
    current_size=$(stat -c %s ${preboot_outdir_release}/preboot_esmt_factory.bin)
    if [ $current_size -gt $target_size ]; then
      echo "Error: preboot_esmt_factory.bin size ($current_size) exceeds available space ($target_size) for BOOT config"
      exit 1
    fi
  
    padding_size=$((target_size - current_size))
    if [ $padding_size -gt 0 ]; then
      echo "Padding preboot_esmt_factory.bin with ${padding_size} bytes"
      dd if=/dev/zero bs=1 count=${padding_size} >> ${preboot_outdir_release}/preboot_esmt_factory.bin 2>/dev/null
    fi
  
    # Append BOOTFLAG config to the end of preboot
    cat ${preboot_outdir_release}/boot_config.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  fi
}

opt_cross_compile=${CONFIG_TOOLCHAIN_BSP}
opt_chip_name=${syna_chip_name}

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  opt_genx_enable=${CONFIG_GENX_ENABLE}
fi

if [ "is${CONFIG_RDK_SYS}" = "isy" ]; then
  opt_rdk_sys=${CONFIG_RDK_SYS}
fi

if [ "is${CONFIG_UBOOT_SPIUBOOT}" = "isy" ]; then
    opt_spi_uboot=${CONFIG_UBOOT_SPIUBOOT}
fi

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  opt_config_ddrphyfw=y
else
  opt_config_ddrphyfw=n
fi

if [ "is${CONFIG_OPEN_TEE}" = "isy" ]; then
  opt_open_tee=${CONFIG_OPEN_TEE}
fi

opt_production_build="${CONFIG_PRODUCTION_BUILD}"

### Variables  ###
preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}
preboot_outdir_build_release="${preboot_outdir_release}/intermediate/release"

preboot_topdir=${topdir}/boot/preboot

# Feature: bootflow
preboot_prebuilts_dir_bootflow="${preboot_topdir}/prebuilts"
if [ "is${CONFIG_OPEN_TEE}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/bcm_ree/${syna_chip_name}"
else
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/bcm_tee/${syna_chip_name}"
fi
preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${syna_chip_rev}"
if [ "is${opt_genx_enable}" = "is" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${CONFIG_PREBOOT_MARKET_ID}"
else
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/${CONFIG_PREBOOT_PROFILE}"
fi
preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/bootflow"
if [ "is${CONFIG_PREBOOT_BOOTFLOW_NR}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/NR"
elif [ "is${CONFIG_PREBOOT_BOOTFLOW_AB}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/AB"
else
  /bin/false
fi
if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/EMMC"
elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/NAND"
  if [ "is${CONFIG_NAND_RANDOMIZER}" = "isy" ]; then
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/randomizer_y"
  else
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/randomizer_n"
  fi
elif [ "is${CONFIG_IMAGE_USBBOOT}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/USBBOOT"
elif [ "is${CONFIG_IMAGE_SPISUBOOT}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/SPISUBOOT"
else
  /bin/false
fi
if [ "is${CONFIG_FASTBOOT_FLOW}" = "isy" ]; then
  preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/fastboot_y"
else
  if [ "is${CONFIG_PREBOOT_ANDROID_BOOTCTRL}" = "isy" ]; then
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/fastboot_n_android_bootctrl"
  else
    preboot_prebuilts_dir_bootflow="${preboot_prebuilts_dir_bootflow}/fastboot_n"
  fi
fi
## FIXME: if nand, enable/disable randomization

# Feature: hwinit
preboot_prebuilts_dir_hwinit="${preboot_topdir}/prebuilts"
if [ "is${CONFIG_OPEN_TEE}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/bcm_ree/${syna_chip_name}"
else
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/bcm_tee/${syna_chip_name}"
fi
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${syna_chip_rev}"
if [ "is${opt_genx_enable}" = "is" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MARKET_ID}"
else
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_PROFILE}"
fi
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/hwinit"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_DDR_TYPE}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_SIZE}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_SPEED}"
preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/${CONFIG_PREBOOT_MEMORY_VARIANT}"
if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/EMMC"
elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/NAND"
elif [ "is${CONFIG_IMAGE_USBBOOT}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/USBBOOT"
elif [ "is${CONFIG_IMAGE_SPISUBOOT}" = "isy" ]; then
  preboot_prebuilts_dir_hwinit="${preboot_prebuilts_dir_hwinit}/SPISUBOOT"
else
  /bin/false
fi
## FIXME: if nand, enable/disable randomization

### Copy prebuilt binaries  ###
mkdir -p ${preboot_outdir_release}
mkdir -p ${preboot_outdir_build_release}

if [ "is${opt_genx_enable}" != "is" ]; then
  ### gen x compose preboot esmt image ###
  f_K0_BOOT_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_BOOT_store.bin
  f_K0_TEE_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_TEE_store.bin
  f_K1_BOOT_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_BOOT_A_store.bin
  f_K1_BOOT_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_BOOT_B_store.bin
  f_K1_TEE_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_A_store.bin
  f_K0_REE_store=${preboot_prebuilts_dir_bootflow}/key_stores/K0_REE_store.bin
  f_K1_TEE_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_B_store.bin
  f_K1_TEE_C_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_C_store.bin
  f_K1_TEE_D_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_TEE_D_store.bin
  f_K1_REE_A_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_A_store.bin
  f_K1_REE_B_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_B_store.bin
  f_K1_REE_C_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_C_store.bin
  f_K1_REE_D_store=${preboot_prebuilts_dir_bootflow}/key_stores/K1_REE_D_store.bin

  if [ "is${opt_spi_uboot}" != "is" ]; then
    f_EROM=${preboot_prebuilts_dir_bootflow}/uboot/erom.bin
    f_BCM_Kernel=${preboot_prebuilts_dir_bootflow}/uboot/bcm_kernel.bin
    f_boot_monitor=${preboot_prebuilts_dir_bootflow}/uboot/boot_monitor.bin
  elif [ "${opt_flash_type}" = "USBBOOT" ]; then
    f_EROM=${preboot_prebuilts_dir_bootflow}/usb/erom.bin
    f_BCM_Kernel=${preboot_prebuilts_dir_bootflow}/usb/bcm_kernel.bin
    f_boot_monitor=${preboot_prebuilts_dir_bootflow}/usb/boot_monitor.bin
  else
    f_EROM=${preboot_prebuilts_dir_bootflow}/erom.bin
    f_BCM_Kernel=${preboot_prebuilts_dir_bootflow}/bcm_kernel.bin
    f_boot_monitor=${preboot_prebuilts_dir_bootflow}/boot_monitor.bin
  fi

  f_scs_data_param=${preboot_prebuilts_dir_hwinit}/scs_data_param.sign
  if [ "is${opt_production_build}" = "isy" ]; then
    f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en_mp.bin
    f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en_mp.bin
  else
    f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en.bin
    f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en.bin
  fi
  if [ "is${syna_chip_name}" = "isplatypus" ] || [ "is${syna_chip_name}" = "ismyna2" ]; then
    dd if=/dev/zero of=${preboot_outdir_build_release}/ddrphy.bin bs=1 count=98424
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    ##FIXME: will add DOLPHIN ddrphy image handle here.
    f_gen3_ddr_phy_fw_0=${preboot_prebuilts_dir_hwinit}/gen3_ddr_phy_fw_0.bin
    f_gen3_ddr_phy_fw_1=${preboot_prebuilts_dir_hwinit}/gen3_ddr_phy_fw_1.bin
    /bin/cp $f_gen3_ddr_phy_fw_0 ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin
    /bin/cp $f_gen3_ddr_phy_fw_1 ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin
  fi

  if [ -f "$f_K0_BOOT_store" ] && [ -f "$f_K0_TEE_store" ] && [ -f "$f_K1_BOOT_A_store" ] && [ -f "$f_K1_BOOT_B_store" ] && [ -f "$f_K1_TEE_A_store" ] && [ -f "$f_EROM" ] && [ -f "$f_K0_REE_store" ] && [ -f "$f_BCM_Kernel" ] && [ -f "$f_K1_TEE_B_store" ] && [ -f "$f_K1_TEE_C_store" ] && [ -f "$f_K1_TEE_D_store" ] && [ -f "$f_K1_REE_A_store" ] && [ -f "$f_K1_REE_B_store" ] && [ -f "$f_K1_REE_C_store" ] && [ -f "$f_K1_REE_D_store" ] && [ -f "$f_boot_monitor" ]; then
    :
  else
    echo "Error: missing required prebuilt file(s)" >&2
    exit 1
  fi

  /bin/cp $f_K0_BOOT_store ${preboot_outdir_build_release}/K0_BOOT_store.bin
  /bin/cp $f_K0_TEE_store ${preboot_outdir_build_release}/K0_TEE_store.bin
  /bin/cp $f_K1_BOOT_A_store ${preboot_outdir_build_release}/K1_BOOT_A_store.bin
  /bin/cp $f_K1_BOOT_B_store ${preboot_outdir_build_release}/K1_BOOT_B_store.bin
  /bin/cp $f_K1_TEE_A_store ${preboot_outdir_build_release}/K1_TEE_A_store.bin
  /bin/cp $f_EROM ${preboot_outdir_build_release}/erom.bin
  /bin/cp $f_K0_REE_store ${preboot_outdir_build_release}/K0_REE_store.bin
  /bin/cp $f_BCM_Kernel ${preboot_outdir_build_release}/bcm_kernel.bin
  /bin/cp $f_K1_TEE_B_store ${preboot_outdir_build_release}/K1_TEE_B_store.bin
  /bin/cp $f_K1_TEE_C_store ${preboot_outdir_build_release}/K1_TEE_C_store.bin
  /bin/cp $f_K1_TEE_D_store ${preboot_outdir_build_release}/K1_TEE_D_store.bin
  /bin/cp $f_K1_REE_A_store ${preboot_outdir_build_release}/K1_REE_A_store.bin
  /bin/cp $f_K1_REE_B_store ${preboot_outdir_build_release}/K1_REE_B_store.bin
  /bin/cp $f_K1_REE_C_store ${preboot_outdir_build_release}/K1_REE_C_store.bin
  /bin/cp $f_K1_REE_D_store ${preboot_outdir_build_release}/K1_REE_D_store.bin
  /bin/cp $f_boot_monitor ${preboot_outdir_build_release}/boot_monitor.bin
  /bin/cp $f_sysinit ${preboot_outdir_build_release}/sysinit_en.bin
  /bin/cp $f_scs_data_param ${preboot_outdir_build_release}/scs_data_param.sign
  /bin/cp $f_miniloader ${preboot_outdir_build_release}/miniloader_en.bin

  ### generate SCS_Unchecked_Area ###
  dd if=/dev/zero of=${preboot_outdir_build_release}/scs_data_unchecked.bin  bs=1  count=4096

  # Pack binaries
  cat ${preboot_outdir_build_release}/K0_BOOT_store.bin > ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K0_TEE_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_BOOT_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_BOOT_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K0_REE_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/bcm_kernel.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_TEE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/K1_REE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/scs_data_param.sign >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/scs_data_unchecked.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/boot_monitor.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  if [ "is${opt_chip_name}" = "isplatypus" ] || [ "is${opt_chip_name}" = "ismyna2" ]; then
    cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    cat ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin >> ${preboot_outdir_release}/preboot_esmt.bin
    cat ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin >> ${preboot_outdir_release}/preboot_esmt.bin
  fi
  cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin

  ### Generate BOOT configuration binary (GenX path) ###
  gen_boot_config

  # Generate information of packed binaries
  echo -n "K0_BOOT_store," > ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_BOOT_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K0_TEE_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_TEE_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_BOOT_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_BOOT_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_BOOT_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_BOOT_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "erom," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K0_REE_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K0_REE_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "bcm_kernel," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/bcm_kernel.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_C_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_TEE_D_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_TEE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_A_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_A_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_B_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_B_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_C_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_C_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "K1_REE_D_store," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/K1_REE_D_store.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "SCS_DATA_PARAM," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/scs_data_param.sign >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "SCS_DATA_unchecked," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/scs_data_unchecked.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "boot_monitor," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/boot_monitor.bin >> ${preboot_outdir_release}/preboot_esmt.info
  echo -n "sysinit," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.info
  if [ "is${opt_chip_name}" = "isplatypus" ] || [ "is${opt_chip_name}" = "ismyna2" ]; then
    echo -n "ddrphy," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.info
  elif [ "is${opt_config_ddrphyfw}" = "isy" ] && [ "is${opt_chip_name}" = "isdolphin" ]; then
    echo -n "gen3_ddr_phy_fw_0," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/gen3_ddr_phy_fw_0.bin >> ${preboot_outdir_release}/preboot_esmt.info
    echo -n "gen3_ddr_phy_fw_1," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_build_release}/gen3_ddr_phy_fw_1.bin >> ${preboot_outdir_release}/preboot_esmt.info
  fi
  echo -n "miniloader," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.info


  # Add BOOT config info if it was generated
  if [ -f ${preboot_outdir_release}/boot_config.bin ]; then
    echo -n "boot_config," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_release}/boot_config.bin >> ${preboot_outdir_release}/preboot_esmt.info
  fi

else
# EROM, TSM, Copy SYSINIT and MINILOADER
f_erom=${preboot_prebuilts_dir_bootflow}/erom.bin
f_tsm=${preboot_prebuilts_dir_bootflow}/tsm.bin
f_ddrphy=${preboot_prebuilts_dir_hwinit}/ddrphy.bin
if [ "is${opt_production_build}" = "isy" ]; then
  f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en_mp.bin
  f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en_mp.bin
else
  f_sysinit=${preboot_prebuilts_dir_hwinit}/sysinit_en.bin
  f_miniloader=${preboot_prebuilts_dir_bootflow}/miniloader_en.bin
fi

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  if [ -f ${f_ddrphy} ]; then
    INSTALL_F $f_ddrphy ${preboot_outdir_build_release}/
  fi
fi

INSTALL_F $f_erom ${preboot_outdir_build_release}/
INSTALL_F $f_tsm ${preboot_outdir_build_release}/
cp -ad $f_sysinit ${preboot_outdir_build_release}/sysinit_en.bin
cp -ad $f_miniloader ${preboot_outdir_build_release}/miniloader_en.bin

if [ -f ${preboot_prebuilts_dir_bootflow}/erom.factory ]; then
  INSTALL_F ${preboot_prebuilts_dir_bootflow}/erom.factory ${preboot_outdir_build_release}/
fi
if [ -f ${preboot_prebuilts_dir_bootflow}/tsm.factory ]; then
  INSTALL_F ${preboot_prebuilts_dir_bootflow}/tsm.factory ${preboot_outdir_build_release}/
fi

### Pack EROM, SYSINIT, MINILOADER and TSM together

# Pack binaries
cat ${preboot_outdir_build_release}/erom.bin > ${preboot_outdir_release}/preboot_esmt.bin
cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin
if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.bin
fi
cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.bin

cat ${preboot_outdir_build_release}/tsm.bin >> ${preboot_outdir_release}/preboot_esmt.bin

if [ -f ${preboot_outdir_build_release}/erom.factory ] && [ -f ${preboot_outdir_build_release}/tsm.factory ]; then
  cat ${preboot_outdir_build_release}/erom.factory > ${preboot_outdir_release}/preboot_esmt_factory.bin
  cat ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
    cat ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  fi
  cat ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt_factory.bin
  cat ${preboot_outdir_build_release}/tsm.factory >> ${preboot_outdir_release}/preboot_esmt_factory.bin
fi

  ### Generate BOOT configuration binary ###
  gen_boot_config

# Generate information of packed binaries
echo -n "erom," > ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/erom.bin >> ${preboot_outdir_release}/preboot_esmt.info

echo -n "sysinit," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/sysinit_en.bin >> ${preboot_outdir_release}/preboot_esmt.info

if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
  echo -n "ddrphy," >> ${preboot_outdir_release}/preboot_esmt.info
  stat -c %s ${preboot_outdir_build_release}/ddrphy.bin >> ${preboot_outdir_release}/preboot_esmt.info
fi

echo -n "miniloader," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/miniloader_en.bin >> ${preboot_outdir_release}/preboot_esmt.info

echo -n "tsm," >> ${preboot_outdir_release}/preboot_esmt.info
stat -c %s ${preboot_outdir_build_release}/tsm.bin >> ${preboot_outdir_release}/preboot_esmt.info

  # Add BOOT config info if it was generated
  if [ -f ${preboot_outdir_release}/boot_config.bin ]; then
    echo -n "boot_config," >> ${preboot_outdir_release}/preboot_esmt.info
    stat -c %s ${preboot_outdir_release}/boot_config.bin >> ${preboot_outdir_release}/preboot_esmt.info
  fi

fi
