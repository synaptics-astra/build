#!/bin/bash

if [ $# != "1" ] && [ $# != "2" ];then
  printf "\nUsage: $0 <TA_PATH> [TA_OUTPATH]\n"
  exit 1
fi

optee_3rd_ta_path=$1

if [ $# = "2" ];then
  OPTEE_3RD_TA_OUTPATH=$2
fi

for file in ${optee_3rd_ta_path}/*; do
  if [ -f "$file" ]; then
    optee_3rd_ta=$(basename $file)
    extension="${optee_3rd_ta##*.}"
    if [ "$extension" = "ta" ]; then
      source build/module/ta_enc/optee_3rd_ta_enc/gen_full_ta_img.sh $file
    fi
  fi
done

