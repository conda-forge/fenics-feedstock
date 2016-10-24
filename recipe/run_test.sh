#!/bin/bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=10.9
  export CXXFLAGS="-std=c++11 -stdlib=libc++ $CXXFLAGS"
fi

pushd "$SRC_DIR"
rm -rf $HOME/.instant

pushd build/test/unit/python
py.test -v fem/test_form.py || (
    find $HOME/.instant/error -name '*.log' -print -exec cat '{}' \;
    exit 1
)
popd
