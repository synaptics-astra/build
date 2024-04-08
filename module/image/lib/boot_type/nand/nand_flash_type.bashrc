# Bash script: boot_type: NAND: nand_flash_type

### Analyzing config file ###
f_flash_cfg=${workdir_product_config}/flash_type.cfg
[ -f $f_flash_cfg ]

list_cfgs=$(cat $f_flash_cfg)

for c in $list_cfgs; do
  declare v=$(expr $c : "^nand_\(.*=.*\)")

  if [ "x$v" != "x" ]; then
    param_name=$(echo $v | cut -d = -f 1)
    param_val=$(echo $v | cut -d = -f 2)

    case "$param_name" in
      "page_size") nand_param_page_size=${param_val} ;;
      "block_size") nand_param_block_size=${param_val} ;;
      "boot_part_size") nand_param_boot_part_size=${param_val} ;;
      "total_size") nand_param_total_size=${param_val} ;;
      "ecc_strength") nand_param_ecc_strength=${param_val} ;;
      *) /bin/false ;;
    esac
    unset param_name
    unset param_val
  fi
  unset v
done
unset list_cfgs

### Check NAND parameters ###
nand_param_total_blocks=$(( ${nand_param_total_size}/${nand_param_block_size} ))
nand_param_pages_per_block=$(( ${nand_param_block_size}/${nand_param_page_size} ))

[ $(( ${nand_param_block_size}*${nand_param_total_blocks} )) -eq ${nand_param_total_size} ]
[ $(( ${nand_param_page_size}*${nand_param_pages_per_block} )) -eq ${nand_param_block_size} ]
