#!/bin/bash
set -e

function log_and_die () {
    find "$INSTANT_CACHE_DIR" -name 'compile.log' -exec echo $'\n\n\n{}' \; -exec cat {} \;
    exit 1
}

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

export INSTANT_CACHE_DIR=${PWD}/instant
rm -rf "$INSTANT_CACHE_DIR"

# FIXME: remove SRC_DIR when updating to conda-build 2 with source_files
pushd "${SRC_DIR}/test/unit/python"
TESTS="jit fem/test_form.py::test_assemble_linear"

RUN_TESTS="python -b -m pytest -vs $TESTS"
# serial
$RUN_TESTS || log_and_die

# parallel
if [[ "$(uname)" == "Darwin" ]]; then
  # FIXME: skip mpi tests on Linux pending conda-smithy fix #337
  mpiexec -n 3 $RUN_TESTS || log_and_die
fi
