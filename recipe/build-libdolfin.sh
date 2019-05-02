#!/bin/bash
set -eux

cd dolfin

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
  export LDFLAGS="-Wl,-rpath,$PREFIX/lib $LDFLAGS"
fi

# scrub problematic -fdebug-prefix-map from C[XX]FLAGS
# these are loaded in the clang[++] activate scripts
export CFLAGS=$(echo $CFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')
export CXXFLAGS=$(echo $CXXFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')

# add ufc header from ffc sources
UFC_INCLUDE_DIR=$PREFIX/include
mkdir -p $UFC_INCLUDE_DIR
cp ../ffc/ffc/backends/ufc/ufc.h $UFC_INCLUDE_DIR/ufc.h

# DOLFIN

rm -rf build
mkdir build
cd build

export LIBRARY_PATH=$PREFIX/lib
export INCLUDE_PATH=$PREFIX/include

export PETSC_DIR=$PREFIX
export SLEPC_DIR=$PREFIX
export BLAS_DIR=$LIBRARY_PATH

cmake .. \
  -DDOLFIN_ENABLE_MPI=on \
  -DDOLFIN_ENABLE_PETSC=on \
  -DDOLFIN_ENABLE_SCOTCH=on \
  -DDOLFIN_ENABLE_HDF5=on \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
  -DCMAKE_INCLUDE_PATH=$INCLUDE_PATH \
  -DCMAKE_LIBRARY_PATH=$LIBRARY_PATH \
  -DUFC_INCLUDE_DIR=$UFC_INCLUDE_DIR \
  -DPYTHON_EXECUTABLE=$BUILD_PREFIX/bin/python || (cat CMakeFiles/CMakeError.log && exit 1)

make VERBOSE=1 -j${CPU_COUNT}
make install

# Don't include demos in installed package
rm -rf $PREFIX/share/dolfin/demo

# remove paths for unused deps in cmake files
# these paths may not exist on targets and aren't needed,
# but cmake will die with 'no rule to make /Applications/...libclang_rt.osx.a'

if [[ "$(uname)" == "Darwin" ]]; then
    find $PREFIX/share/dolfin -name '*.cmake' -print -exec sh -c "sed -E -i ''  's@/Applications/Xcode.app[^;]*(.dylib|.framework|.a);@@g' {}" \;
else
    find $PREFIX/share/dolfin -name '*.cmake' -print -exec sh -c "sed -E -i''  's@/usr/lib(64)?/[^;]*(.so|.a);@@g' {}" \;
fi
