#!/bin/bash

##==============================================================================
## Goal  : Generate Genx Secure TA image
## Input : xxx.ta
## Output: xxx.ta
##
## Usage : gen_full_ta_img.sh xxx.ta
##==============================================================================

if [ $# != "1" ];then
  printf "\nUsage: $0 <TA>\n"
  exit 1
fi

source build/module/ta_enc/optee_3rd_ta_enc/gen_ta_cert.sh $1

check_file_exist $OPTEE_3RD_TA_RSA_PRV
check_file_exist $OPTEE_3RD_TA_MDK
check_file_exist $OPTEE_3RD_TA_ROOT_CERT_NAME

in_ta_extras=$tmp_dir/ta_extras
gen_ta_extras $in_ta_extras

echo -e "\nOPTEE_3RD_TA_ImageType is $OPTEE_3RD_TA_ImageType"
cp -adv $1  $OPTEE_3RD_TA_RAW_BIN || exit 0
in_ta_payload=$OPTEE_3RD_TA_RAW_BIN
out_TA_store=$OutputData/$OPTEE_3RD_TA_RAW_NAME
gen_secure_image $in_ta_extras $in_ta_payload $out_TA_store

ta_img_name=$OutputData/$OPTEE_3RD_TA_IMG_NAME
pack_ta $OPTEE_3RD_TA_ROOT_CERT_NAME $OutputData/$OPTEE_3RD_TA_CERT_NAME $out_TA_store $ta_img_name

