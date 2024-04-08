# Bash script: run selected stages

declare stage_script_exist

#############
# Functions #
#############

try_stage_script() {
  local stage
  stage=$1; shift

  stage_script_exist=""

  local script_to_run
  script_to_run=${preboot_module_dir}/lib/scripts/stage${stage}/build.bashrc

  if [ -f ${script_to_run} ]; then
    source ${script_to_run} &
    wait $!

    stage_script_exist="y"
  else
    stage_script_exist="n"
  fi
}

try_stages() {
  local stage_found="n"

  while true
  do
    local stage_to_run

    stage_to_run=$1
    if [ "x${stage_to_run}" = "x" ]; then
      break
    else
      shift
    fi

    # Run stage script if exists
    try_stage_script ${stage_to_run}
    if [ "is${stage_script_exist}" = "isy" ]; then
      stage_found="y"
      break
    fi
  done

  if [ "is${stage_found}" != "isy" ]; then
    echo "ERROR: could not find any script of selected stages"
    /bin/false
  fi
}

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
