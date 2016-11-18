#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# Components (ffc, etc.)
pip install --no-deps --no-binary :all: -r "${RECIPE_DIR}/component-requirements.txt"

# DOLFIN

# tarball includes cached swig output built with Python 2.
# Remove it because it breaks building on Python 3.
rm -rf dolfin/swig/modules

rm -rf build
mkdir build
cd build

export LIBRARY_PATH=$PREFIX/lib
export INCLUDE_PATH=$PREFIX/include

export PETSC_DIR=$PREFIX
export SLEPC_DIR=$PREFIX
export BLAS_DIR=$LIBRARY_PATH

cmake .. \
  -DDOLFIN_ENABLE_OPENMP=off \
  -DDOLFIN_ENABLE_MPI=on \
  -DDOLFIN_ENABLE_PETSC=on \
  -DDOLFIN_ENABLE_PETSC4PY=on \
  -DDOLFIN_ENABLE_SCOTCH=on \
  -DDOLFIN_ENABLE_HDF5=off \
  -DDOLFIN_ENABLE_VTK=off \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INCLUDE_PATH=$INCLUDE_PATH \
  -DCMAKE_LIBRARY_PATH=$LIBRARY_PATH \
  -DPYTHON_EXECUTABLE=$PYTHON || (cat CMakeFiles/CMakeError.log && exit 1)

make VERBOSE=1 -j${CPU_COUNT}
make install

# remove paths for unused deps in cmake files
# these paths may not exist on targets and aren't needed,
# but cmake will die with 'no rule to make /Applications/...libclang_rt.osx.a'

if [[ "$(uname)" == "Darwin" ]]; then
    find $PREFIX/share/dolfin -name '*.cmake' -print -exec sh -c "sed -E -i ''  's@/Applications/Xcode.app[^;]*(.dylib|.framework|.a);@@g' {}" \;
else
    find $PREFIX/share/dolfin -name '*.cmake' -print -exec sh -c "sed -E -i''  's@/usr/lib(64)?/[^;]*(.so|.a);@@g' {}" \;
fi


