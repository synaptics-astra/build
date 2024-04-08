# Bash script: stage 2: build hwinit features

#############
# Functions #
#############

get_feature_list() {
  f_list=$1; shift

  cat "${preboot_module_dir}/lib/features/$f_list" \
    | grep -v "^#" \
    | grep -v "^\s*$"
}

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
