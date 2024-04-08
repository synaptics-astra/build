# Bash script: stage 2 build

run_script() {
  script_name=$1; shift

  script_to_run="${preboot_module_dir}/lib/scripts/stage2/${script_name}"

  [ -f ${script_to_run} ]
  source ${script_to_run}
}

preboot_build_basedir=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preboot
preboot_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/preboot

preboot_topdir=${topdir}/boot/preboot

run_script build-args.bashrc

run_script func-get-feature-list.bashrc
run_script func-build-and-install-one.bashrc

run_script build-hwinit-features.bashrc
run_script build-bootflow-features.bashrc

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
