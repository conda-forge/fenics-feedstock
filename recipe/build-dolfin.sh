#!/bin/bash
set -eux

# scrub problematic -fdebug-prefix-map from C[XX]FLAGS
# these are loaded in the clang[++] activate scripts
export CFLAGS=$(echo $CFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')
export CXXFLAGS=$(echo $CXXFLAGS | sed -E 's@\-fdebug\-prefix\-map[^ ]*@@g')

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "0" ]]; then
  # needed for cross-compile openmpi
  export OMPI_CC="$CC"

  export OPAL_PREFIX="$PREFIX"
fi

# install Python bindings
cd python
$PYTHON -m pip install -v --no-build-isolation --no-deps .

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "1" ]]; then
  cd test
  export OMPI_MCA_btl_sm_backing_directory=/tmp
  $PYTHON -c 'from dolfin import *; info(parameters["form_compiler"], True)'
fi
