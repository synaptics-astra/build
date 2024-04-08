# Bash script: stage 2: build bootflow features

if [ "is${syna_sec_lvl}" = "isgenx" ]; then
  opt_profile=$genx_types
else
  opt_profile="normal"
fi

opt_bootflow="VERIFIEDBOOT"
opt_bootflow_version=""


declare bootflow_features
bootflow_features=$(get_feature_list $syna_chip_name/bootflow.list)

while read -r line
do
  build_and_install_bootflow_feature ${line}
done <<< "${bootflow_features}"

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
