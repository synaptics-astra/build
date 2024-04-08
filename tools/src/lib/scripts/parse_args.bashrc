# Bash script: parse command line arguments

#
# Functions
#

show_help() {
cat << EOF
Usage:
 build [options] prod_name

Options:
 --help			Show help
EOF
}

#
# Main
#

# Show help if there is no argument
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

# Parse arguments
short_options="h"
long_options="help"
long_options="${long_options},chip-name:,chip-rev:,platform:,bootflow:,flash-type:,market-id:"
long_options="${long_options},outdir-intermediate:,outdir-release:"

if ! results=$(getopt -u -o ${short_options} -l ${long_options} -- "$@") ; then
  /bin/false
fi

set -- $results
while [ $# -gt 0 ]; do
  case "$1" in
    --help) show_help; exit 1 ;;
    --chip-name) shift; opt_chip_name=$1; shift ;;
    --chip-rev) shift; opt_chip_rev=$1; shift ;;
    --platform) shift; opt_platform=$1; shift ;;
    --bootflow) shift; opt_bootflow=$1; shift ;;
    --flash-type) shift; opt_flash_type=$1; shift ;;
    --market-id) shift; opt_market_id=$1; shift ;;
    --outdir-intermediate) shift; opt_outdir_intermediate=$1; shift ;;
    --outdir-release) shift; opt_outdir_release=$1; shift ;;
    --) shift; break ;;
    *)  break ;;
  esac
done

# Retrieve product name
if [ $# -gt 0 ]; then
  echo ERROR: unknown additional arguments
  /bin/false
fi
