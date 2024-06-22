#!/bin/bash
set -eux

unset CMAKE_PREFIX_PATH

cd dolfin

# scrub problematic -fdebug-prefix-map from C[XX]FLAGS
# these are loaded in the clang[++] activate scripts
export CFLAGS=$(echo $CFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')
export CXXFLAGS=$(echo $CXXFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "0" ]]; then
  # needed for cross-compile openmpi
  export OMPI_CC="$CC"
  export OMPI_CXX="$CXX"

  export OPAL_PREFIX="$PREFIX"
  # disable build tests when cross-compiling
  export CMAKE_ARGS="${CMAKE_ARGS} -DDOLFIN_SKIP_BUILD_TESTS=ON"
fi

if [[ "${target_platform}" == "osx-arm64" ]]; then
  # scotch seems to crash on osx-arm64
  export CMAKE_ARGS="${CMAKE_ARGS} -DDOLFIN_ENABLE_SCOTCH=OFF"
else
  export CMAKE_ARGS="${CMAKE_ARGS} -DDOLFIN_ENABLE_SCOTCH=ON"
fi

# dolfinx pkg-config records compilers
# avoid recording build prefix
export CC=$(basename $CC)
export CXX=$(basename $CXX)

rm -rf build
mkdir build
cd build

export LIBRARY_PATH=$PREFIX/lib
export INCLUDE_PATH=$PREFIX/include

export PETSC_DIR=$PREFIX
export SLEPC_DIR=$PREFIX
export BLAS_DIR=$LIBRARY_PATH

cmake .. \
  ${CMAKE_ARGS} \
  -DDOLFIN_ENABLE_MPI=on \
  -DDOLFIN_ENABLE_PETSC=on \
  -DDOLFIN_ENABLE_SLEPC=on \
  -DDOLFIN_ENABLE_HDF5=on \
  -DPYTHON_EXECUTABLE=$PREFIX/bin/python || (cat CMakeFiles/CMakeError.log && exit 1)

if [[ -f CMakeFiles/CMakeError.log ]]; then
    echo "Captured CMakeError.log"
    cat CMakeFiles/CMakeError.log
fi

make VERBOSE=1 -j${CPU_COUNT}
make install

# Don't include demos in installed package
rm -rf $PREFIX/share/dolfin/demo

# remove paths for unused deps in cmake files
# these paths may not exist on targets and aren't needed,
# but cmake will die with 'no rule to make /Applications/...libclang_rt.osx.a'
# these should be excluded in cmake, but it's not clear how to get them all out
find $PREFIX/share/dolfin -name '*.cmake' -print -exec python3 ${RECIPE_DIR}/cmake_replace.py {} \;

if [[ "$(uname)" == "Linux" ]]; then

    # strip libdolfin
    # it's unclear why this doesn't happen from the default flags
    # it seems to on mac
    strip -s $PREFIX/lib/libdolfin.so
fi

# patch pkg-config file, which has some wonky stuff
cat $PREFIX/lib/pkgconfig/dolfin.pc
mv $PREFIX/lib/pkgconfig/dolfin.pc ./
# sysroot is recorded in $BUILD_PREFIX, but at runtime this will be in $PREFIX
cat dolfin.pc | sed "s@$BUILD_PREFIX@$PREFIX@g" > $PREFIX/lib/pkgconfig/dolfin.pc
cat $PREFIX/lib/pkgconfig/dolfin.pc
