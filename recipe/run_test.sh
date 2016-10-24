#!/bin/bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

pushd "$SRC_DIR"
pushd deps

rm -rf $HOME/.instant

pushd instant/test
python run_tests.py
popd

rm -rf $HOME/.instant

pushd ufl/test
py.test -v
popd

rm -rf $HOME/.instant

pushd fiat/test/unit
python test.py
popd


# skip ffc tests for now, which take forever
# rm -rf $HOME/.instant
# pushd ffc/demo
# popd

popd # deps

rm -rf $HOME/.instant

pushd build/test/unit/python
py.test -v fem/test_form.py || (
    find $HOME/.instant/error -name '*.log' -print -exec cat '{}' \;
    exit 1
)
popd
