#!/bin/bash

PMIC_MODELS_CONF="${BUILD_PREBOOT_PATH}/pmic_models"

declare -A PMIC_MODELS
load_pmic_models() {
  PMIC_MODELS["unknown"]=0
  PMIC_MODELS["none"]=0

  if [ -f "$PMIC_MODELS_CONF" ]; then
    local current_id=1
    while IFS=', ' read -r name alias || [ -n "$name" ]; do
      [[ "$name" =~ ^#.* ]] && continue
      [[ -z "$name" ]] && continue
      name=$(echo $name | xargs)
      PMIC_MODELS["$name"]=$current_id
      current_id=$((current_id + 1))
    done < "$PMIC_MODELS_CONF"
  else
    echo "Error: PMIC models configuration file not found at $PMIC_MODELS_CONF" >&2
    exit 1
  fi
}
load_pmic_models

PMIC_CONFIG_MAGIC=0x504D4943
PMIC_CONFIG_VERSION=0x00000001
PMIC_CONFIG_SIZE=136
PMIC_TARGET_SIZE=192

# PWM channel constants
PWM_INVALID_CHANNEL=255

show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --vcore-models M0,M1,M2,M3       VCORE PMIC models for GPIO combinations 0,1,2,3"
  echo "  --vcpu-models M0,M1,M2,M3        VCPU PMIC models for GPIO combinations 0,1,2,3"
  echo "  --vcore-i2c-ch CH                VCORE I2C channel numeric value (0-5)"
  echo "  --vcpu-i2c-ch CH                 VCPU I2C channel numeric value (0-5)"
  echo "  --vcore-i2c-ch-str STR           VCORE I2C channel name (for display)"
  echo "  --vcpu-i2c-ch-str STR            VCPU I2C channel name (for display)"
  echo "  --pmic-type TYPE                 PMIC type (1-I2C, 2-PWM, 3-SM Timer, 4-Auto)"
  echo "  --vcore-gpioh GPIO               VCORE GPIO high bit for auto detection"
  echo "  --vcore-gpiol GPIO               VCORE GPIO low bit for auto detection"
  echo "  --vcpu-gpioh GPIO                VCPU GPIO high bit for auto detection"
  echo "  --vcpu-gpiol GPIO                VCPU GPIO low bit for auto detection"
  echo "  --vcore-pwm-gpio VAL             VCORE PWM GPIO"
  echo "  --vcpu-pwm-gpio VAL              VCPU PWM GPIO"
  echo "  --vcore-smtmr-gpio VAL           VCORE SM Timer GPIO"
  echo "  --vcpu-smtmr-gpio VAL            VCPU SM Timer GPIO"
  echo "  --vcore-pwm-freq VAL             VCORE PWM frequency (Hz)"
  echo "  --vcore-pwm-polarity VAL         VCORE PWM polarity"
  echo "  --vcore-pwm-volt-min VAL         VCORE PWM min voltage (uV)"
  echo "  --vcore-pwm-volt-max VAL         VCORE PWM max voltage (uV)"
  echo "  --vcore-pwm-duty-min-volt VAL    VCORE PWM duty at min voltage"
  echo "  --vcore-pwm-duty-max-volt VAL    VCORE PWM duty at max voltage"
  echo "  --vcpu-pwm-freq VAL              VCPU PWM frequency (Hz)"
  echo "  --vcpu-pwm-polarity VAL          VCPU PWM polarity"
  echo "  --vcpu-pwm-volt-min VAL          VCPU PWM min voltage (uV)"
  echo "  --vcpu-pwm-volt-max VAL          VCPU PWM max voltage (uV)"
  echo "  --vcpu-pwm-duty-min-volt VAL     VCPU PWM duty at min voltage"
  echo "  --vcpu-pwm-duty-max-volt VAL     VCPU PWM duty at max voltage"
  echo "  --output FILE                    Output binary file path"
  echo "  --list-models                    List supported PMIC models"
  echo "  --help                           Show this help message"
}

list_models() {
  echo "Supported PMIC models:"
  for name in "${!PMIC_MODELS[@]}"; do
    echo "${PMIC_MODELS[$name]}:$name"
  done | sort -n | while IFS=':' read -r id name; do
    if [ "$name" != "unknown" ] && [ "$name" != "none" ]; then
      printf "  %-12s (ID: 0x%02X)\n" "$name" "$id"
    fi
  done
}

get_pmic_id() {
  local model="$1"
  local model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]' | xargs)
  if [ -n "${PMIC_MODELS[$model_lower]}" ]; then
    echo "${PMIC_MODELS[$model_lower]}"
  else
    echo "0"
  fi
}

parse_i2c_channel() {
  local i2c_ch="$1"
  i2c_ch=$(echo "$i2c_ch" | sed 's/^"\(.*\)"$/\1/')
  [[ "$i2c_ch" =~ ^[0-9]+$ ]] && echo "$i2c_ch" || echo 0
}

hex_to_binary() {
  local hex_string="$1"
  local output_file="$2"
    local i

  hex_string=$(echo "$hex_string" | tr -d ' \n')

  local len=${#hex_string}
    if [ $((len % 2)) -ne 0 ]; then
        echo "Error: Hex string must have even length" >&2
        return 1
    fi

  : > "$output_file"  # Create/truncate file
  for ((i=0; i<len; i+=2)); do
    local byte="${hex_string:$i:2}"
    printf "\x$byte" >> "$output_file"
  done

  return 0
}

calculate_checksum() {
  local data="$1"
  local checksum=0
  local i=0

    # Process 4-byte words (little-endian)
    while [ $i -lt $((${#data} - 8)) ]; do  # Exclude last 4 bytes (checksum field)
    local byte1=$((0x${data:$i:2}))
    local byte2=$((0x${data:$((i+2)):2}))
    local byte3=$((0x${data:$((i+4)):2}))
    local byte4=$((0x${data:$((i+6)):2}))

    local word=$((byte1 + (byte2 << 8) + (byte3 << 16) + (byte4 << 24)))
    checksum=$((checksum ^ word))
    i=$((i + 8))
  done
  checksum=$((checksum & 0xFFFFFFFF))
  echo "$checksum"
}

write_le32() {
  local value=$1
  printf "%02x%02x%02x%02x" \
    $((value & 0xFF)) \
    $(((value >> 8) & 0xFF)) \
    $(((value >> 16) & 0xFF)) \
    $(((value >> 24) & 0xFF))
}

generate_pmic_config() {
  local vcore_models_str="$1"
  local vcpu_models_str="$2"
  local vcore_i2c_val_raw="$3"
  local vcpu_i2c_val_raw="$4"
  local vcore_pwm_gpio="${5:-255}"
  local vcpu_pwm_gpio="${6:-255}"
  local output_file="$7"
  local vcore_i2c_ch_str="$8"
  local vcpu_i2c_ch_str="$9"
  local pmic_type="${10:-1}"
  local vcore_gpioh="${11:-255}"
  local vcore_gpiol="${12:-255}"
  local vcpu_gpioh="${13:-255}"
  local vcpu_gpiol="${14:-255}"
  # New PWM fields
  local vcore_pwm_freq="${15:-0}"
  local vcore_pwm_polarity="${16:-0}"
  local vcore_pwm_volt_min_uv="${17:-0}"
  local vcore_pwm_volt_max_uv="${18:-0}"
  local vcore_pwm_duty_at_volt_min="${19:-0}"
  local vcore_pwm_duty_at_volt_max="${20:-0}"
  local vcpu_pwm_freq="${21:-0}"
  local vcpu_pwm_polarity="${22:-0}"
  local vcpu_pwm_volt_min_uv="${23:-0}"
  local vcpu_pwm_volt_max_uv="${24:-0}"
  local vcpu_pwm_duty_at_volt_min="${25:-0}"
  local vcpu_pwm_duty_at_volt_max="${26:-0}"
  local vcore_smtmr_gpio="${27:-255}"
  local vcpu_smtmr_gpio="${28:-255}"

  local vcore_i2c_val=$(parse_i2c_channel "$vcore_i2c_val_raw")
  local vcpu_i2c_val=$(parse_i2c_channel "$vcpu_i2c_val_raw")

  # Split models
  IFS=',' read -r -a vcore_models <<< "$vcore_models_str"
  IFS=',' read -r -a vcpu_models <<< "$vcpu_models_str"

  local config_data=""
  config_data+=$(write_le32 $PMIC_CONFIG_MAGIC)    # 1. magic
  config_data+=$(write_le32 $PMIC_CONFIG_VERSION)  # 2. version

  # 3-6. VCORE IDs
  for i in {0..3}; do
    id=$(get_pmic_id "${vcore_models[$i]}")
    config_data+=$(write_le32 $id)
  done

  # 7-10. VCPU IDs
  for i in {0..3}; do
    id=$(get_pmic_id "${vcpu_models[$i]}")
    config_data+=$(write_le32 $id)
  done

  config_data+=$(write_le32 $vcore_i2c_val)        # 11. vcore_i2c_ch
  config_data+=$(write_le32 $vcpu_i2c_val)         # 12. vcpu_i2c_ch
  config_data+=$(write_le32 $vcore_gpioh)          # 13. vcore_gpioh
  config_data+=$(write_le32 $vcore_gpiol)          # 14. vcore_gpiol
  config_data+=$(write_le32 $vcpu_gpioh)           # 15. vcpu_gpioh
  config_data+=$(write_le32 $vcpu_gpiol)           # 16. vcpu_gpiol
  config_data+=$(write_le32 $pmic_type)            # 17. pmic_type
  config_data+=$(write_le32 $vcore_pwm_gpio)       # 18. vcore_pwm_gpio
  config_data+=$(write_le32 $vcpu_pwm_gpio)        # 19. vcpu_pwm_gpio
  config_data+=$(write_le32 $vcore_smtmr_gpio)     # 20. vcore_smtmr_gpio
  config_data+=$(write_le32 $vcpu_smtmr_gpio)      # 21. vcpu_smtmr_gpio

  # PWM regulator configuration
  config_data+=$(write_le32 $vcore_pwm_freq)            # 22. vcore_pwm_freq_hz
  config_data+=$(write_le32 $vcore_pwm_polarity)         # 23. vcore_pwm_polarity
  config_data+=$(write_le32 $vcore_pwm_volt_min_uv)      # 24. vcore_pwm_volt_min_uv
  config_data+=$(write_le32 $vcore_pwm_volt_max_uv)      # 25. vcore_pwm_volt_max_uv
  config_data+=$(write_le32 $vcore_pwm_duty_at_volt_min) # 26. vcore_pwm_duty_at_volt_min
  config_data+=$(write_le32 $vcore_pwm_duty_at_volt_max) # 27. vcore_pwm_duty_at_volt_max

  config_data+=$(write_le32 $vcpu_pwm_freq)            # 28. vcpu_pwm_freq_hz
  config_data+=$(write_le32 $vcpu_pwm_polarity)         # 29. vcpu_pwm_polarity
  config_data+=$(write_le32 $vcpu_pwm_volt_min_uv)      # 30. vcpu_pwm_volt_min_uv
  config_data+=$(write_le32 $vcpu_pwm_volt_max_uv)      # 31. vcpu_pwm_volt_max_uv
  config_data+=$(write_le32 $vcpu_pwm_duty_at_volt_min) # 32. vcpu_pwm_duty_at_volt_min
  config_data+=$(write_le32 $vcpu_pwm_duty_at_volt_max) # 33. vcpu_pwm_duty_at_volt_max

  config_data+="00000000"                          # 34. checksum placeholder

  local checksum=$(calculate_checksum "$config_data")
  local checksum_hex=$(write_le32 $checksum)
  config_data="${config_data:0:-8}$checksum_hex"

  local output_dir=$(dirname "$output_file")
  [ ! -d "$output_dir" ] && mkdir -p "$output_dir"
  hex_to_binary "$config_data" "$output_file"

  current_size=$(stat -c %s $output_file)
  padding_size=$((PMIC_TARGET_SIZE - current_size))
  dd if=/dev/zero bs=1 count=${padding_size} >> $output_file 2>/dev/null

  # Selective Logging
  local type_str="Unknown"
  case "$pmic_type" in 1) type_str="I2C" ;; 2) type_str="PWM" ;; 3) type_str="SM Timer" ;; 4) type_str="Auto Det" ;; esac

  printf "  PMIC Type: %s (%d)\n" "$type_str" "$pmic_type"
  if [ "$pmic_type" -eq 1 ] || [ "$pmic_type" -eq 4 ]; then
    printf "  I2C Ch(vcore/vcpu): %s/%s\n" "${vcore_i2c_ch_str:-NONE}" "${vcpu_i2c_ch_str:-NONE}"
    printf "  Model(vcore/vcpu): %s/%s\n" "${vcore_models_str:-NONE}" "${vcpu_models_str:-NONE}"
  fi
  if [ "$pmic_type" -eq 4 ]; then
    printf "  GPIO Straps H/L: VCORE:%d/%d, VCPU:%d/%d\n" "$vcore_gpioh" "$vcore_gpiol" "$vcpu_gpioh" "$vcpu_gpiol"
  fi
  if [ "$pmic_type" -eq 2 ]; then
    printf "  PWM GPIOs: VCORE:0x%08x, VCPU:0x%08x\n" "$vcore_pwm_gpio" "$vcpu_pwm_gpio"
    printf "  PWM Freq: VCORE:%d Hz, VCPU:%d Hz\n" "$vcore_pwm_freq" "$vcpu_pwm_freq"
  fi
  if [ "$pmic_type" -eq 3 ]; then
    printf "  Timer GPIOs: VCORE:0x%08x, VCPU:0x%08x\n" "$vcore_smtmr_gpio" "$vcpu_smtmr_gpio"
    printf "  PWM Freq: VCORE:%d Hz, VCPU:%d Hz\n" "$vcore_pwm_freq" "$vcpu_pwm_freq"
  fi


  echo "  Size: $PMIC_CONFIG_SIZE bytes"
  return 0
}

main() {
  local vcore_models="" vcpu_models="" vcore_i2c_ch="" vcpu_i2c_ch=""
  local vcore_i2c_ch_str="" vcpu_i2c_ch_str="" vcore_pwm_gpio=255 vcpu_pwm_gpio=255
  local pmic_type=1 vcore_gpioh=255 vcore_gpiol=255 vcpu_gpioh=255 vcpu_gpiol=255
  local vcore_pwm_freq=0 vcore_pwm_polarity=0 vcore_pwm_volt_min_uv=0 vcore_pwm_volt_max_uv=0
  local vcore_pwm_duty_at_volt_min=0 vcore_pwm_duty_at_volt_max=0
  local vcpu_pwm_freq=0 vcpu_pwm_polarity=0 vcpu_pwm_volt_min_uv=0 vcpu_pwm_volt_max_uv=0
  local vcpu_pwm_duty_at_volt_min=0 vcpu_pwm_duty_at_volt_max=0
  local vcore_smtmr_gpio=255 vcpu_smtmr_gpio=255
  local output_file=""


  while [ $# -gt 0 ]; do
    case "$1" in
      --vcore-models) shift; vcore_models="$1" ;;
      --vcpu-models) shift; vcpu_models="$1" ;;
      --vcore-i2c-ch) shift; vcore_i2c_ch="$1" ;;
      --vcpu-i2c-ch) shift; vcpu_i2c_ch="$1" ;;
      --vcore-i2c-ch-str) shift; vcore_i2c_ch_str="$1" ;;
      --vcpu-i2c-ch-str) shift; vcpu_i2c_ch_str="$1" ;;
      --vcore-pwm-gpio) shift; vcore_pwm_gpio="$1" ;;
      --vcpu-pwm-gpio) shift; vcpu_pwm_gpio="$1" ;;
      --pmic-type) shift; pmic_type="$1" ;;
      --vcore-gpioh) shift; vcore_gpioh="$1" ;;
      --vcore-gpiol) shift; vcore_gpiol="$1" ;;
      --vcpu-gpioh) shift; vcpu_gpioh="$1" ;;
      --vcpu-gpiol) shift; vcpu_gpiol="$1" ;;
      --vcore-pwm-freq) shift; vcore_pwm_freq="$1" ;;
      --vcore-pwm-polarity) shift; vcore_pwm_polarity="$1" ;;
      --vcore-pwm-volt-min) shift; vcore_pwm_volt_min_uv="$1" ;;
      --vcore-pwm-volt-max) shift; vcore_pwm_volt_max_uv="$1" ;;
      --vcore-pwm-duty-min-volt) shift; vcore_pwm_duty_at_volt_min="$1" ;;
      --vcore-pwm-duty-max-volt) shift; vcore_pwm_duty_at_volt_max="$1" ;;
      --vcpu-pwm-freq) shift; vcpu_pwm_freq="$1" ;;
      --vcpu-pwm-polarity) shift; vcpu_pwm_polarity="$1" ;;
      --vcpu-pwm-volt-min) shift; vcpu_pwm_volt_min_uv="$1" ;;
      --vcpu-pwm-volt-max) shift; vcpu_pwm_volt_max_uv="$1" ;;
      --vcpu-pwm-duty-min-volt) shift; vcpu_pwm_duty_at_volt_min="$1" ;;
      --vcpu-pwm-duty-max-volt) shift; vcpu_pwm_duty_at_volt_max="$1" ;;
      --vcore-smtmr-gpio) shift; vcore_smtmr_gpio="$1" ;;
      --vcpu-smtmr-gpio) shift; vcpu_smtmr_gpio="$1" ;;
      --output) shift; output_file="$1" ;;
      --list-models) list_models; return 0 ;;
      --help|-h) show_usage; return 0 ;;
      *) echo "Error: Unknown option '$1'"; show_usage; return 1 ;;
    esac
    shift
  done

  if [ -z "$output_file" ]; then echo "Error: --output is required"; return 1; fi

  generate_pmic_config "$vcore_models" "$vcpu_models" "$vcore_i2c_ch" "$vcpu_i2c_ch" "$vcore_pwm_gpio" "$vcpu_pwm_gpio" "$output_file" "$vcore_i2c_ch_str" "$vcpu_i2c_ch_str" "$pmic_type" "$vcore_gpioh" "$vcore_gpiol" "$vcpu_gpioh" "$vcpu_gpiol" \
    "$vcore_pwm_freq" "$vcore_pwm_polarity" "$vcore_pwm_volt_min_uv" "$vcore_pwm_volt_max_uv" "$vcore_pwm_duty_at_volt_min" "$vcore_pwm_duty_at_volt_max" \
    "$vcpu_pwm_freq" "$vcpu_pwm_polarity" "$vcpu_pwm_volt_min_uv" "$vcpu_pwm_volt_max_uv" "$vcpu_pwm_duty_at_volt_min" "$vcpu_pwm_duty_at_volt_max" \
    "$vcore_smtmr_gpio" "$vcpu_smtmr_gpio"
}

main "$@"
