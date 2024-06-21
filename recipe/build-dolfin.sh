#!/bin/bash
set -eux

cd dolfin

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
  $PYTHON -c 'from dolfin import *; info(parameters["form_compiler"], True)'
fi

grep -R pthread_nonshared -C 3 $PREFIX || true
