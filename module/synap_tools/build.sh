#!/bin/bash

source build/header.rc

mod_dir=${CONFIG_SYNA_SDK_PATH}/synap

cur_script=""
function run_script()
{
   if [[ -f "$cur_script" ]] ; then
       ${cur_script} "$@"
   fi
}

${mod_dir}/framework/build/build_tools.sh "$@"
