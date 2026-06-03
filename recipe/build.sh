#!/usr/bin/env bash
set -euxo pipefail

mkdir build
cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX}

make -j${CPU_COUNT}
make install

# Compile external helper objects needed by the Python bindings
${CXX} -O3 -fPIC -c -o ${SRC_DIR}/external/miniz.o ${SRC_DIR}/external/miniz.c
${CXX} -O3 -fPIC -c -o ${SRC_DIR}/external/WinBase64/libbase64.o ${SRC_DIR}/external/WinBase64/base64.cpp

# Build Python bindings
cd "${SRC_DIR}/pythonbindings"
EXT_SUFFIX=$(${PYTHON} -c "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX') or sysconfig.get_config_var('SO'))")
${CXX} ${CXXFLAGS} ${CPPFLAGS} -Wall -shared -fopenmp -std=c++17 -fPIC \
  $(${PYTHON} -m pybind11 --includes) \
  OpenPhase.cpp \
  -o "OpenPhase${EXT_SUFFIX}" \
  -I../external -I../external/WinBase64 -I../include \
  -L"${PREFIX}/lib" -lOpenPhase \
  ../external/miniz.o ../external/WinBase64/libbase64.o \
  ${LDFLAGS}

cp OpenPhase${EXT_SUFFIX} ${SP_DIR}/
