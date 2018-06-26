#!/bin/bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

export DIJITSO_CACHE_DIR=${PWD}/instant

pushd "python/test/unit"
TESTS="jit fem/test_form.py::test_assemble_linear"

RUN_TESTS="python -b -m pytest -vs $TESTS"
# serial
$RUN_TESTS

# parallel
mpiexec -n 3 $RUN_TESTS 2>&1 </dev/null | cat
