#!/bin/bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

export INSTANT_CACHE_DIR=${PWD}/instant

# FIXME: remove SRC_DIR when updating to conda-build 2 with source_files
pushd "${SRC_DIR}/test/unit/python"
TESTS="jit fem/test_form.py::test_assemble_linear"

RUN_TESTS="python -b -m pytest -vs $TESTS"
# serial
$RUN_TESTS
# parallel

if [[ "$(uname)" == "Darwin" ]]; then
  # FIXME: skip mpi tests on Linux pending conda-smithy fix #337
  mpiexec -n 3 $RUN_TESTS
fi
