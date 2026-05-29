#!/bin/bash

BOOT_CONFIG_MAGIC=0x42544346
BOOT_CONFIG_VERSION=0x00000001
BOOTFLAG_TARGET_SIZE=64

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --skip-fw              Don't load firmware in miniloader"
    echo "  --force-spi            Don't check SD in SPI Boot"
    echo "  --help                 Show this help message"
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

write_le32() {
    local value=$1
    printf "%02x%02x%02x%02x" \
        $((value & 0xFF)) \
        $(((value >> 8) & 0xFF)) \
        $(((value >> 16) & 0xFF)) \
        $(((value >> 24) & 0xFF))
}

main() {
    local skip_fw=0
    local force_spi=0

    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --skip-fw)
                skip_fw=1
                ;;
            --force-spi)
                force_spi=1
                ;;
            --output)
                shift
                output_file="$1"
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

    # Validate required arguments
    if [ -z "$output_file" ]; then
        echo "Error: --output is required"
        show_usage
        return 1
    fi

    # Generate configuration
    local config_data=""
    config_data+="00000000"                          # checksum placeholder
    config_data+=$(write_le32 $BOOT_CONFIG_MAGIC)    # magic
    config_data+=$(write_le32 $BOOT_CONFIG_VERSION)  # version

	# Generate bootflag
	flags=$(( (skip_fw << 0) | (force_spi << 1) ))
    config_data+=$(write_le32 $flags)

    hex_to_binary "$config_data" "$output_file"

	current_size=$(stat -c %s $output_file)
    if [ $current_size -gt $BOOTFLAG_TARGET_SIZE ]; then
      echo "Error: BOOTFLAG configure exceeds available space ($BOOTFLAG_TARGET_SIZE)"
      exit 1
    fi

    padding_size=$((BOOTFLAG_TARGET_SIZE - current_size))
    echo "Padding BOOTFLAG configure with ${padding_size} bytes"
    dd if=/dev/zero bs=1 count=${padding_size} >> $output_file 2>/dev/null

    if [ $? -eq 0 ]; then
        #echo "Generated BOOTFLAG config: $output_file"
        printf "  skip firmware: %d\n" "$skip_fw"
        printf "  force SPI: %d\n" "$force_spi"
        echo "  Size: $BOOTFLAG_TARGET_SIZE bytes"
        return 0
    else
        echo "Error: Failed to write BOOTFLAG config file: $output_file"
        return 1
    fi
}

main "$@"
