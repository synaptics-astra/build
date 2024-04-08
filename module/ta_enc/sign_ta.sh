#!/bin/bash

[ $# -ne 2 ] && echo "sign_ta.sh config_file ta_name" && exit 1

source build/header.rc
source build/chip.rc
source build/install.rc

source build/module/ta_enc/common.rc

# install TA cert
ta_name=$2
cp -adv ${product_path}/tacert/${ta_name}.cert ${clear_ta_path}/


### Sign TA binaries ###
f_ta=${clear_ta_path}/${ta_name}.ta_raw
[ -f ${f_ta} ]

f_signed_ta=${enc_ta_path}/${ta_name}.ta

enc_ta ${product_path}/tz30.cfg $f_ta $f_signed_ta

echo "sign ${f_ta} out: ${f_signed_ta}"
