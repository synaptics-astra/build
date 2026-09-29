# POSIX shell script: stage 1 build

run_script() {
  script_name=$1; shift
  stage=$1; shift

  script_to_run="${preboot_module_dir}/lib/scripts/stage1/${script_name}"

  [ -f ${script_to_run} ]
    set -- "$stage"
    . ${script_to_run}
}


preboot_build_basedir=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}
preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}

preboot_topdir=${topdir}/boot/preboot

preboot_outdir_build_release="${preboot_build_basedir}/intermediate/release"
preboot_outdir_build_intermediate="${preboot_build_basedir}/intermediate/obj"
if [ "is${CONFIG_PREBOOT_PROFILE}" = "isnocs" ]; then
  #if nocs && non-GenX case, build miniloader only
  if [ "{CONFIG_GENX_ENABLE}" = "y" ]; then
    preboot_build_sysinit=y
  else
    preboot_build_sysinit=n
  fi
  preboot_build_miniloader=y
else
  preboot_build_sysinit=y
  preboot_build_miniloader=y
fi

# Generate PMIC autogen header
if [ ! -f "${preboot_module_dir}/gen_pmic_header.sh" ]; then
    echo "Error: ${preboot_module_dir}/gen_pmic_header.sh not found"
    exit 1
fi
"${preboot_module_dir}/gen_pmic_header.sh" "${CONFIG_SYNA_SDK_PATH}"

run_script build-args.bashrc 1
run_script build-one.bashrc "1"

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
