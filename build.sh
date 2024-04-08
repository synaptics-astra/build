#!/bin/bash

source build/header.rc

echo "toplevel script called"

mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}
mkdir -p ${CONFIG_SYNA_SDK_OUT_HOST_OBJ_PATH}
mkdir -p ${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}
mkdir -p ${CONFIG_SYNA_SDK_BUILD_PATH}

# Check defconfig consistency
if [ "is${CONFIG_VSSDK_RELEASE}" = "isy" ]; then
  configs_check_dir="release"
else
  configs_check_dir="product"
fi

diff ${topdir}/out/.config ${topdir}/configs/${configs_check_dir}/${CONFIG_PRODUCT_NAME}/${CONFIG_PRODUCT_NAME}_defconfig || {
  echo "WARNING inconsistent product defconfig file: ${CONFIG_PRODUCT_NAME}"
  sleep 1
}

source build/version.sh

source build/tool.rc
