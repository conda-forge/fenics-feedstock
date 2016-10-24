#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

# Components (ffc, etc.)
pip install --no-deps --no-binary :all: -r "${RECIPE_DIR}/component-requirements.txt"

# DOLFIN
rm -rf build
mkdir build
cd build

export LIBRARY_PATH=$PREFIX/lib
export INCLUDE_PATH=$PREFIX/include

export BLAS_DIR=$LIBRARY_PATH

cmake .. \
  -DDOLFIN_ENABLE_OPENMP=off \
  -DDOLFIN_ENABLE_MPI=off \
  -DDOLFIN_ENABLE_PETSC=off \
  -DDOLFIN_ENABLE_HDF5=off \
  -DDOLFIN_ENABLE_VTK=off \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INCLUDE_PATH=$INCLUDE_PATH \
  -DCMAKE_LIBRARY_PATH=$LIBRARY_PATH \
  -DPYTHON_EXECUTABLE=$PYTHON || (cat CMakeFiles/CMakeError.log && exit 1)

make VERBOSE=1 -j${CPU_COUNT}
make install
