# Bash script: stage 2 build

run_script() {
  script_name=$1; shift

  script_to_run="${preboot_module_dir}/lib/scripts/stage2/${script_name}"

  [ -f ${script_to_run} ]
  . ${script_to_run}
}

preboot_build_basedir=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preboot
preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preboot

preboot_topdir=${topdir}/boot/preboot

# Generate PMIC autogen header
if [ ! -f "${preboot_module_dir}/gen_pmic_header.sh" ]; then
    echo "Error: ${preboot_module_dir}/gen_pmic_header.sh not found"
    exit 1
fi
source "${preboot_module_dir}/gen_pmic_header.sh"

run_script build-args.bashrc

run_script func-get-feature-list.bashrc
run_script func-build-and-install-one.bashrc

if [ "is$1" != "ispack_tee" ]; then
  run_script build-hwinit-features.bashrc ree n
  run_script build-bootflow-features.bashrc ree n
else
  run_script build-hwinit-features.bashrc tee n
  run_script build-bootflow-features.bashrc tee n
fi

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
