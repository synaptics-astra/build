# POSIX shell script: run selected stages

#############
# Functions #
#############

try_stage_script() {
  _try_stage_script_stage=$1
  shift
  only_pack=${1-}

  stage_script_exist=""

  _try_stage_script_path=${preboot_module_dir}/lib/scripts/stage${_try_stage_script_stage}/build.bashrc

  if [ -f "${_try_stage_script_path}" ]; then
    (
      set -- "$only_pack"
      . "${_try_stage_script_path}"
    )

    stage_script_exist="y"
  else
    stage_script_exist="n"
  fi
}

try_stages() {
  _try_stages_found="n"

  while true
  do
    _try_stages_stage=${1-}
    if [ "x${_try_stages_stage}" = "x" ]; then
      break
    else
      shift
      only_pack=${1-}
    fi

    # Run stage script if exists
    try_stage_script "${_try_stages_stage}" "${only_pack}"
    if [ "is${stage_script_exist}" = "isy" ]; then
      _try_stages_found="y"
      break
    fi
  done

  if [ "is${_try_stages_found}" != "isy" ]; then
    echo "ERROR: could not find any script of selected stages"
    /bin/false
  fi
}

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
