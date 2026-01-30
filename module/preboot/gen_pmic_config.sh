#!/bin/bash

declare -A PMIC_MODELS=(
    ["unknown"]=0
    ["m88pg86x"]=1
    ["sy8824b"]=2
    ["ncp6335d"]=3
    ["mp886x"]=4
    ["sy8827n"]=5
    ["hl7593wl06"]=6
    ["tps62868"]=7
    ["rt5739"]=8
    ["fp6359"]=9
    ["tps6287x"]=10
)

PMIC_CONFIG_MAGIC=0x504D4943
PMIC_CONFIG_VERSION=0x00000001
PMIC_CONFIG_SIZE=32

# PWM channel constants
PWM_INVALID_CHANNEL=255

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --vcore-model MODEL    VCORE PMIC model name (e.g., tps6287x, fp6359)"
    echo "  --vcpu-model MODEL     VCPU PMIC model name (e.g., fp6359, tps62868)"
    echo "  --vcore-pwm-ch CH      VCORE PWM channel (0-255, empty for 0xFF)"
    echo "  --vcpu-pwm-ch CH       VCPU PWM channel (0-255, empty for 0xFF)"
    echo "  --output FILE          Output binary file path"
    echo "  --list-models          List supported PMIC models"
    echo "  --help                 Show this help message"
}

list_models() {
    echo "Supported PMIC models:"
    for model in "${!PMIC_MODELS[@]}"; do
        if [ "$model" != "unknown" ]; then
            printf "  %-12s (ID: 0x%02X)\n" "$model" "${PMIC_MODELS[$model]}"
        fi
    done
}

get_pmic_id() {
    local model="$1"
    local model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')

    if [ -n "${PMIC_MODELS[$model_lower]}" ]; then
        echo "${PMIC_MODELS[$model_lower]}"
    else
        echo "${PMIC_MODELS[unknown]}"
    fi
}

# Parse PWM channel value
# Args: $1 - PWM channel string (can be empty, number, or quoted string)
# Returns: PWM channel value (0xFF if empty, otherwise the number)
parse_pwm_channel() {
    local pwm_ch="$1"

    # Remove quotes if present
    pwm_ch=$(echo "$pwm_ch" | sed 's/^"\(.*\)"$/\1/')

    # If empty string, return 0xFF
    if [ -z "$pwm_ch" ] || [ "$pwm_ch" = "" ]; then
        echo $PWM_INVALID_CHANNEL
        return 0
    fi

    # Validate it's a number
    if [[ "$pwm_ch" =~ ^[0-9]+$ ]]; then
        # Check range (0-255)
        if [ "$pwm_ch" -ge 0 ] && [ "$pwm_ch" -le 255 ]; then
            echo "$pwm_ch"
            return 0
        else
            echo "Error: PWM channel must be between 0-255, got: $pwm_ch" >&2
            return 1
        fi
    else
        echo "Error: PWM channel must be a number, got: $pwm_ch" >&2
        return 1
    fi
}

# Convert hex string to binary
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
    local vcore_model="$1"
    local vcpu_model="$2"
    local vcore_pwm_ch="$3"
    local vcpu_pwm_ch="$4"
    local output_file="$5"

    local vcore_id=0
    local vcpu_id=0
    local vcore_pwm_val=0
    local vcpu_pwm_val=0

    # Check if this is I2C mode BEFORE modifying model names
    local is_i2c_mode=0
    if [ -n "$vcore_model" ] && [ "$vcore_model" != "" ] || [ -n "$vcpu_model" ] && [ "$vcpu_model" != "" ]; then
        is_i2c_mode=1
    fi

    # Validate PMIC models and get IDs
    if [ -z "$vcore_model" ] || [ "$vcore_model" = "" ]; then
        vcore_id=0
        vcore_model="none"
        echo "VCORE PMIC model not specified, using 0x00"
    else
        vcore_id=$(get_pmic_id "$vcore_model")
        if [ "$vcore_id" = "0" ] && [ "$vcore_model" != "unknown" ]; then
            echo "Warning: Unknown VCORE PMIC model '$vcore_model', using default"
        fi
    fi

    if [ -z "$vcpu_model" ] || [ "$vcpu_model" = "" ]; then
        vcpu_id=0
        vcpu_model="none"
        echo "VCPU PMIC model not specified, using 0x00"
    else
        vcpu_id=$(get_pmic_id "$vcpu_model")
        if [ "$vcpu_id" = "0" ] && [ "$vcpu_model" != "unknown" ]; then
            echo "Warning: Unknown VCPU PMIC model '$vcpu_model', using default"
        fi
    fi

    # Parse PWM channels
    vcore_pwm_val=$(parse_pwm_channel "$vcore_pwm_ch")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid VCORE PWM channel: $vcore_pwm_ch"
        return 1
    fi

    vcpu_pwm_val=$(parse_pwm_channel "$vcpu_pwm_ch")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid VCPU PWM channel: $vcpu_pwm_ch"
        return 1
    fi

    # Apply I2C mode logic - set PWM channels to 0 instead of 0xFF
    if [ $is_i2c_mode -eq 1 ]; then
        if [ "$vcore_pwm_val" -eq $PWM_INVALID_CHANNEL ]; then
            vcore_pwm_val=0
        fi
        if [ "$vcpu_pwm_val" -eq $PWM_INVALID_CHANNEL ]; then
            vcpu_pwm_val=0
        fi
    fi

    # Determine PWM valid flag (1 if any PWM channel is valid, 0 otherwise)
    local pwm_valid=0
    if [ $is_i2c_mode -eq 0 ]; then
        # Not I2C mode - check if any PWM channel was actually specified (not empty)
        local vcore_pwm_clean=$(echo "$vcore_pwm_ch" | sed 's/^"\(.*\)"$/\1/')
        local vcpu_pwm_clean=$(echo "$vcpu_pwm_ch" | sed 's/^"\(.*\)"$/\1/')
        if ([ -n "$vcore_pwm_clean" ] && [ "$vcore_pwm_clean" != "" ]) || ([ -n "$vcpu_pwm_clean" ] && [ "$vcpu_pwm_clean" != "" ]); then
            pwm_valid=1
        fi
    fi

    local config_data=""
    config_data+=$(write_le32 $PMIC_CONFIG_MAGIC)    # magic
    config_data+=$(write_le32 $PMIC_CONFIG_VERSION)  # version
    config_data+=$(write_le32 $vcore_id)             # vcore_id
    config_data+=$(write_le32 $vcpu_id)              # vcpu_id
    config_data+=$(write_le32 $pwm_valid)            # pwm_valid
    config_data+=$(write_le32 $vcore_pwm_val)        # vcore_pwm_ch
    config_data+=$(write_le32 $vcpu_pwm_val)         # vcpu_pwm_ch
    config_data+="00000000"                          # checksum placeholder

    local checksum=$(calculate_checksum "$config_data")

    local checksum_hex=$(write_le32 $checksum)
    config_data="${config_data:0:-8}$checksum_hex"

    local output_dir=$(dirname "$output_file")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi

    hex_to_binary "$config_data" "$output_file"

    if [ $? -eq 0 ]; then
        #echo "Generated PMIC config: $output_file"
        printf "  VCORE Model: %s (ID: 0x%02X)\n" "$vcore_model" "$vcore_id"
        printf "  VCPU Model: %s (ID: 0x%02X)\n" "$vcpu_model" "$vcpu_id"
        printf "  PWM Valid: %s\n" "$([ $pwm_valid -eq 1 ] && echo 'Yes' || echo 'No')"
        if [ "$vcore_pwm_val" -eq $PWM_INVALID_CHANNEL ]; then
            printf "  VCORE PWM Channel: Not configured (0xFF)\n"
        else
            printf "  VCORE PWM Channel: %d (0x%02X)\n" "$vcore_pwm_val" "$vcore_pwm_val"
        fi
        if [ "$vcpu_pwm_val" -eq $PWM_INVALID_CHANNEL ]; then
            printf "  VCPU PWM Channel: Not configured (0xFF)\n"
        else
            printf "  VCPU PWM Channel: %d (0x%02X)\n" "$vcpu_pwm_val" "$vcpu_pwm_val"
        fi
        echo "  Size: $PMIC_CONFIG_SIZE bytes"
        printf "  Checksum: 0x%08X\n" "$checksum"
        return 0
    else
        echo "Error: Failed to write PMIC config file: $output_file"
        return 1
    fi
}

main() {
    local vcore_model=""
    local vcpu_model=""
    local vcore_pwm_ch=""
    local vcpu_pwm_ch=""
    local output_file=""
    local list_models_flag=false

    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --vcore-model)
                shift
                vcore_model="$1"
                ;;
            --vcpu-model)
                shift
                vcpu_model="$1"
                ;;
            --vcore-pwm-ch)
                shift
                vcore_pwm_ch="$1"
                ;;
            --vcpu-pwm-ch)
                shift
                vcpu_pwm_ch="$1"
                ;;
            --output)
                shift
                output_file="$1"
                ;;
            --list-models)
                list_models_flag=true
                ;;
            --help|-h)
                show_usage
                return 0
                ;;
            *)
                echo "Error: Unknown option '$1'"
                show_usage
                return 1
                ;;
        esac
        shift
    done

    # Handle list models
    if [ "$list_models_flag" = true ]; then
        list_models
        return 0
    fi

    # Validate required arguments
    if [ -z "$output_file" ]; then
        echo "Error: --output is required when not using --list-models"
        show_usage
        return 1
    fi

    # Check configuration validity: either I2C mode or PWM mode, not both or neither
    # Check if PWM channels are actually specified (not empty strings or quoted empty strings)
    vcore_pwm_specified=0
    vcpu_pwm_specified=0
    # Remove quotes and check if non-empty
    vcore_pwm_clean=$(echo "$vcore_pwm_ch" | sed 's/^"\(.*\)"$/\1/')
    vcpu_pwm_clean=$(echo "$vcpu_pwm_ch" | sed 's/^"\(.*\)"$/\1/')
    if [ -n "$vcore_pwm_clean" ] && [ "$vcore_pwm_clean" != "" ]; then
        vcore_pwm_specified=1
    fi
    if [ -n "$vcpu_pwm_clean" ] && [ "$vcpu_pwm_clean" != "" ]; then
        vcpu_pwm_specified=1
    fi

    if [ -n "$vcore_model" ] || [ -n "$vcpu_model" ]; then
        # I2C mode: PMIC models provided
        if [ $vcore_pwm_specified -eq 1 ] || [ $vcpu_pwm_specified -eq 1 ]; then
            echo "Error: Cannot mix I2C mode (PMIC models) with PWM mode (PWM channels)"
            echo "Use either --vcore-model/--vcpu-model OR --vcore-pwm-ch/--vcpu-pwm-ch, not both"
            show_usage
            return 1
        fi
    elif [ $vcore_pwm_specified -eq 1 ] || [ $vcpu_pwm_specified -eq 1 ]; then
        # PWM mode: PWM channels provided, no PMIC models
        echo "PWM mode: Using PWM channels for voltage control"
    else
        # Neither mode specified
        echo "Error: Must specify either I2C mode (PMIC models) or PWM mode (PWM channels)"
        echo "I2C mode: Use --vcore-model and/or --vcpu-model"
        echo "PWM mode: Use --vcore-pwm-ch and/or --vcpu-pwm-ch (non-empty values)"
        show_usage
        return 1
    fi

    # Generate configuration
    if ! generate_pmic_config "$vcore_model" "$vcpu_model" "$vcore_pwm_ch" "$vcpu_pwm_ch" "$output_file"; then
        return 1
    fi

    return 0
}

main "$@"
