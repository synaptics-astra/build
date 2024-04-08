# Bash script: common

### Find out exectuables to be built ###
pushd ${basedir_src_executables}

list_executables=$(find . -mindepth 1 -maxdepth 1 -type d)

for e in $list_executables; do
  echo "Build executable: $(expr $e : '^\.\/\(.*\)')"
  make -C $e all OBJDIR=${opt_outdir_intermediate}/$e
  /bin/cp -ad ${opt_outdir_intermediate}/$e/$e ${opt_outdir_release}/.
done

popd
