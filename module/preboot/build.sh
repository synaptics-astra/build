#!/bin/bash

# set -x
source build/header.rc
source build/chip.rc
source build/install.rc
source build/security.rc

rebuild_nocs_preboot=${2}

if [ "x${BASH_VERSION}" != "x" ]; then
  set -o errtrace
fi

########
# Main #
########

### Uncomment follow line to show environment settins ###
# set

if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
### Variables ###
preboot_module_dir=$(readlink -f $(dirname $0))
fi

if [ $clean -eq 1 ]; then
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

script_run_stages=${preboot_module_dir}/lib/scripts/run-stages.bashrc
[ -f ${script_run_stages} ]
source ${script_run_stages}

### Run the first existed stage script  ###
if [ "is${CONFIG_PREBOOT_PROFILE}" = "isnocs" ]; then
  try_stages 1
else
  if [ -d ${CONFIG_SYNA_SDK_PATH}/boot/preboot/prebuilts ]; then
    try_stages 3
  else
    try_stages 1
  fi
fi

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
