#!/bin/bash

VER_FILE=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/etc/version_info.txt
mkdir -p ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SYNA_SDK_OUT_ROOTFS}/etc
rm -f ${VER_FILE}

#
# current sdk version: v1.3
#
SDK_VER="v1.3"

echo "SDK_VER:"${SDK_VER} > ${VER_FILE}

echo "BUILT_TIME:"$(date "+%Y-%m-%d %H:%M:%S") >> ${VER_FILE}

if [ "${RELEASE}" = "y" ] ; then
echo "BUILD_TYPE:REL" >> ${VER_FILE}
else
echo "BUILD_TYPE:DBG" >> ${VER_FILE}
fi

echo "PROFILE:"${CONFIG_PRODUCT_NAME} >> ${VER_FILE}
