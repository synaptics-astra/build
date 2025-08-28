# POSIX shell script: preboot build

. build/header.rc
. build/chip.rc
. build/install.rc
. build/security.rc

rebuild_nocs_preboot=$2

########
# Main #
########

# Uncomment the following line to show environment settings
# set

if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
  # Variables
  preboot_module_dir=$(cd "$(dirname "$0")" && pwd)
fi

# Ensure $clean is set, default to 0 if not
: "${clean:=0}"

if [ "$clean" -eq 1 ]; then
  exit 0
fi

if [ "is${rebuild_nocs_preboot}" = "is" ]; then
  echo "no param for rebuild-nocs-reboot"
else
  echo "#################################NOCS####################################"
  echo "${rebuild_nocs_preboot}"
  opt_rebuild_nocs_preboot=${rebuild_nocs_preboot}
  echo "${opt_rebuild_nocs_preboot}"
fi

script_run_stages="${preboot_module_dir}/lib/scripts/run-stages.bashrc"
if [ -f "$script_run_stages" ]; then
  . "$script_run_stages"
fi

# Run the first existing stage script
if [ "is${CONFIG_PREBOOT_PROFILE}" = "isnocs" ]; then
  try_stages 1
else
  if [ -d "${CONFIG_SYNA_SDK_PATH}/boot/preboot/prebuilts" ]; then
    try_stages 3
  else
    try_stages 1
  fi
fi

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab: