#!/bin/bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

mpiexec="mpiexec"

export DIJITSO_CACHE_DIR=${PWD}/instant

# verify that we have the features we intend to
python <<EOF
import dolfin
dolfin.info(dolfin.parameters["form_compiler"], True)
assert dolfin.has_hdf5(), 'hdf5'
assert dolfin.has_hdf5_parallel(), 'parallel hdf5'
assert dolfin.has_petsc(), 'petsc'
assert dolfin.has_petsc4py(), 'petsc4py'
assert dolfin.has_slepc(), 'slepc'
assert dolfin.has_scotch(), 'scotch'
assert dolfin.has_mpi(), 'mpi'
assert dolfin.has_parmetis(), 'parmetis'
EOF
