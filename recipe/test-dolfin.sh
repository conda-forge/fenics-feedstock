#!/bin/bash
set -e

grep -R pthread -C 3 $PREFIX/share/dolfin || true

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

mpiexec="mpiexec"
if command -v "${PREFIX}/bin/ompi_info" >/dev/null; then
    export OMPI_MCA_plm=isolated
    export OMPI_MCA_rmaps_base_oversubscribe=yes
    export OMPI_MCA_btl_vader_single_copy_mechanism=none
    mpiexec="mpiexec --allow-run-as-root"
fi

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

python -c 'from dolfin import *; info(parameters["form_compiler"], True)'

pushd "dolfin/python/test/unit"
TESTS="jit fem/test_form.py::test_assemble_linear"

RUN_TESTS="python -b -m pytest -vs $TESTS"
# serial
$RUN_TESTS || (ls jitfailure*; cat jitfailure*/*; exit 1)

# parallel
$mpiexec -n 3 $RUN_TESTS 2>&1 </dev/null | cat
