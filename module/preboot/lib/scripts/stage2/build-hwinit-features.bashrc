# Bash script: stage 2: build hwinit features

if [ "is${syna_sec_lvl}" = "isgenx" ]; then
  opt_profile=$genx_types
else
  opt_profile="normal"
fi

opt_bootflow="VERIFIEDBOOT"
opt_bootflow_version=""

hwinit_features=$(get_feature_list $syna_chip_name/hwinit.list)

echo "$hwinit_features"

echo "$hwinit_features" | while read -r line; do
  build_and_install_hwinit_feature ${line}
done

# vim: set ai filetype=sh tabstop=2 softtabstop=2 shiftwidth=2 expandtab:
