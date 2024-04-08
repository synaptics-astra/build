#!/bin/bash
source build/header.rc

mod_dir=${CONFIG_SYNA_SDK_PATH}/linux_5_15/modules

cur_script=""
function run_script()
{
   if [[ -f "$cur_script" ]] ; then
       ${cur_script} "$@"
   fi
}

script_list=()

if [ "is${CONFIG_DRIVERS_RTL8363NB}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/net/dsa/rtl8363nb/build.sh")
fi

if [ "is${CONFIG_DRIVERS_DSPG_KEYPAD}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/input/keyboard/dspg-keypad/build.sh")
fi

if [ "is${CONFIG_DRIVERS_DSPG_HOOKSWITCH}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/input/keyboard/dspg-hookswitch/build.sh")
fi

if [ "is${CONFIG_DRIVERS_TLC5917}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/leds/tlc5917/build.sh")
fi

if [ "is${CONFIG_DRIVERS_AXI_METER}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/soc/berlin/modules/axi_meter/build.sh")
fi

if [ "is${CONFIG_DRIVERS_FXL6408}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/gpio/fxl6408/build.sh")
fi

if [ "is${CONFIG_DRIVERS_HWMON}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/hwmon/syna-hwmon/build.sh")
fi

if [ "is${CONFIG_DRIVERS_BLUETOOTH_LPM}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/bluetooth/lpm/build.sh")
fi

if [ "is${CONFIG_DRIVERS_BLUETOOTH_RFKILL}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/bluetooth/rfkill/build.sh")
fi

if [ "is${CONFIG_DRIVERS_SM}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/soc/berlin/modules/sm/build.sh")
fi

if [ "is${CONFIG_DRIVERS_REGULATORS}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/regulator/hl7593/build.sh")
script_list+=("${mod_dir}/drivers/regulator/rt5739/build.sh")
script_list+=("${mod_dir}/drivers/regulator/tps6286x/build.sh")
fi

if [ "is${CONFIG_DRIVERS_I2C_DYNDMX_PINCTRL}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/i2c/muxes/i2c-dyndmx-pinctrl/build.sh")
fi

if [ "is${CONFIG_DRIVERS_DWC3_SYNA}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/usb/dwc3/dwc3-syna/build.sh")
fi

if [ "is${CONFIG_DRIVERS_SUNPLUS}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/net/phy/sunplus/build.sh")
fi

if [ "is${CONFIG_DRIVERS_CADENCE_HPNFC}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/mtd/nand/cadence_hpnfc/build.sh")
fi

if [ "is${CONFIG_DRIVERS_SYNAPTICS_PHY}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/phy/synaptics/phy-berlin-pcie/build.sh")
script_list+=("${mod_dir}/drivers/phy/synaptics/phy-syna-usb/build.sh")
fi

if [ "is${CONFIG_DRIVERS_PINCTRL}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/pinctrl/berlin/pinctrl-myna2/build.sh")
script_list+=("${mod_dir}/drivers/pinctrl/berlin/pinctrl-platypus/build.sh")
script_list+=("${mod_dir}/drivers/pinctrl/berlin/pinctrl-dolphin/build.sh")
fi

if [ "is${CONFIG_DRIVERS_CLK}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/clk/berlin/myna2-clks/build.sh")
script_list+=("${mod_dir}/drivers/clk/berlin/platypus-clks/build.sh")
script_list+=("${mod_dir}/drivers/clk/berlin/dolphin-clks/build.sh")
script_list+=("${mod_dir}/drivers/clk/berlin/dolphin-pll/build.sh")
fi

if [ "is${CONFIG_DRIVERS_PCIE_BERLIN}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/pci/controller/dwc/pcie-berlin/build.sh")
fi

if [ "is${CONFIG_DRIVERS_BERLIN_IR}" = "isy" ]; then
script_list+=("${mod_dir}/drivers/input/keyboard/berlin-ir/build.sh")
fi

for s in "${script_list[@]}";do
    cur_script=${s}
    run_script "$@"
done
