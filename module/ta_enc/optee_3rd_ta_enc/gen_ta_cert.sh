#!/bin/bash

##==============================================================================
## Goal  : Generate Genx TA CERT image
## Input : xxx.ta
## Output: xxx.cert
##
## Usage : gen_ta_cert.sh xxx.ta
##==============================================================================

if [ $# != "1" ];then
  printf "\nUsage: $0 <TA>\n"
  exit 1
fi

source build/module/ta_enc/optee_3rd_ta_enc/optee_3rd_ta_common.rc $1

printf "\ntmp_dir=$tmp_dir"
if [ ! -d $tmp_dir ];then
  mkdir $tmp_dir
fi

printf "\nOutDIR=$OutputData\n"
if [ ! -d $OutputData ];then
  mkdir $OutputData
fi

check_file_exist $OPTEE_3RD_TA_CERT_RSA_PRV
check_file_exist $OPTEE_3RD_TA_CERT_MDK
check_file_exist $OPTEE_3RD_TA_RSA_PUB
check_file_exist $OPTEE_3RD_TA_AES_key

in_tacert_payload=$tmp_dir/tacert_payload
gen_tacert_payload $in_tacert_payload

in_tacert_extras=$tmp_dir/tacert_extras
gen_tacert_extras $in_tacert_extras

echo -e "\nOPTEE_3RD_TACERT_ImageType is $OPTEE_3RD_TACERT_ImageType"
out_TACEERT_store=$OutputData/$OPTEE_3RD_TA_CERT_NAME
gen_tacert_secure_image $in_tacert_extras $in_tacert_payload $out_TACEERT_store
