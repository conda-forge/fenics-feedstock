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

# install Python bindings
cd python
$PYTHON -m pip install -v --no-deps .
cd test
$PYTHON -c 'from dolfin import *; info(parameters["form_compiler"], True)'
