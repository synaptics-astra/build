# Bash script: boot_type: EMMC: emmc_flash_type

### Check EMMC parameters ###
emmc_param_total_blocks=$(( ${CONFIG_EMMC_TOTAL_SIZE}/${CONFIG_EMMC_BLOCK_SIZE} ))
emmc_param_pages_per_block=$(( ${CONFIG_EMMC_BLOCK_SIZE}/${CONFIG_EMMC_PAGE_SIZE} ))

[ $(( ${CONFIG_EMMC_BLOCK_SIZE}*${emmc_param_total_blocks} )) -eq ${CONFIG_EMMC_TOTAL_SIZE} ]
[ $(( ${CONFIG_EMMC_PAGE_SIZE}*${emmc_param_pages_per_block} )) -eq ${CONFIG_EMMC_BLOCK_SIZE} ]
