#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 input_folder_path"
  exit 1
fi

input_folder=$1
output_file=bk.list

if [ ! -d ${input_folder} ]; then
  echo "input folder doesn't exist"
  exit 1
fi

if [ -f ${output_file} ]; then
rm -f  ${output_file}
fi

pushd ${input_folder}
export LC_ALL=C
find ./ -type f ! -name *.so ! -name *.a ! -name bk.list ! -name .gitignore | sort > ${output_file}
popd

if [ $? -eq 0 ]; then
  echo "Success ${input_folder}/${output_file}"
fi
