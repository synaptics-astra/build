#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 input_book_keeping_file release_folder_path "
  exit 1
fi

input_file=$1
rel_folder=$2

if [ ! -d ${rel_folder} ]; then
  echo "release folder doesn't exist"
  exit 1
fi

if [ ! -f ${input_file} ]; then
  echo "input file doesn't exist"
  exit 1
fi

pushd ${rel_folder}
rm -f ${rel_folder}/bk.list
export LC_ALL=C
find ./ -type f ! -path "*/lib_rel/*" ! -name *.so ! -name *.a \
! -name bk.list ! -name .gitignore \
! -name meson.build | sort > bk.list
popd

diff ${input_file} ${rel_folder}/bk.list
if [ $? -ne 0 ];then
  rm -f ${rel_folder}/bk.list
  echo "Fail"
  exit 1
else
  echo "Success"
  rm -f ${rel_folder}/bk.list
fi
