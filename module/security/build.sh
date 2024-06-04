#!/bin/bash

echo "security build script"
source build/header.rc
if [ "is${CONFIG_VSSDK_RELEASE}" != "isy" ]; then
  source build/chip.rc
fi
source build/install.rc

# Working directories
workdir_security_keys=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_KEY_PATH}/${syna_chip_name}/${syna_chip_rev}
product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
workdir_security_ver=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_VERSION_PATH}

if [ $clean -eq 1 ]; then
  rm -rf ${workdir_security_keys}
  rm -rf ${workdir_security_ver}
  exit 0
fi

# Create directories
mkdir -p ${workdir_security_keys}

# Copy keys
if [ "x${CONFIG_GENX_ENABLE}" != "x" ] || [ "is${syna_sec_lvl}" = "isgenx" ]; then
  ### copy GenX keys
  key_src_dir=${CONFIG_SYNA_SDK_KEY_PATH}/chip/${syna_chip_name}/${syna_chip_rev}/generic
  mkdir -p ${workdir_security_keys}/generic
  cp -adfr ${key_src_dir}/* \
           ${workdir_security_keys}/generic
else
  hex32_market_id=$(printf "%08x" ${syna_chip_mid})

  key_src_dir=${CONFIG_SYNA_SDK_KEY_PATH}/chip/${syna_chip_name}/${syna_chip_rev}/mid-${hex32_market_id}
  mkdir -p ${workdir_security_keys}/mid-${hex32_market_id}/
  cp -ad ${key_src_dir}/oem/* \
         ${workdir_security_keys}/mid-${hex32_market_id}/
  if [ -d ${key_src_dir}/mrvl ]; then
    INSTALL_D ${key_src_dir}/mrvl/codetype_1 \
           ${workdir_security_keys}/mid-${hex32_market_id}/
    if [ -d ${key_src_dir}/mrvl/codetype_2 ]; then
      INSTALL_D ${key_src_dir}/mrvl/codetype_2 \
      ${workdir_security_keys}/mid-${hex32_market_id}/
    fi
    INSTALL_D ${key_src_dir}/mrvl/codetype_3 \
           ${workdir_security_keys}/mid-${hex32_market_id}/
    INSTALL_D ${key_src_dir}/mrvl/codetype_4 \
           ${workdir_security_keys}/mid-${hex32_market_id}/
  fi
fi

gen_secimg_cfg() {
  f_sec_cfg=$1; shift
  v_codetype=$1; shift

  ### Check security config file ###
  [ -f $f_sec_cfg ]

  ### parse security_ver.cfg ###
  v_IMGVersion=$(grep "SOCSWVersion" $f_sec_cfg | awk {'print $3'})
  mkdir -p ${workdir_security_ver}/codetype_$v_codetype

  local config_file=${workdir_security_ver}/codetype_$v_codetype/config
  ### update security version ###
  echo "[security_version]" > ${config_file}
  echo "extrsak_store = 0" > ${config_file}
  echo "image_signing = $v_IMGVersion" >> ${config_file}
  echo -e "\n" >> ${config_file}
  echo "[signing_tool]" >> ${config_file}
  echo "security_version_style = count" >> ${config_file}
}

if [ -f ${product_dir}/security_ver.cfg ]; then
  gen_secimg_cfg ${product_dir}/security_ver.cfg 1
  gen_secimg_cfg ${product_dir}/security_ver.cfg 3
  gen_secimg_cfg ${product_dir}/security_ver.cfg 4
  gen_secimg_cfg ${product_dir}/security_ver.cfg 5
fi


