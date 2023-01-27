#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2020-2023 Leroy Hopson <godot-xterm@leroy.geek.nz>
# SPDX-License-Identifier: MIT

set -e

# Parse args.
args=$@
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -t|--target)
      target="$2"
      shift
      shift
      ;;
    --disable-pty)
      disable_pty="yes"
      shift
      ;;
    *)
      echo "Usage: ./build.sh [-t|--target <release|debug>] [--disable_pty]";
      exit 128
      shift
      ;;
  esac
done

# Set defaults.
target=${target:-debug}
disable_pty=${disable_pty:-no}
nproc=$(nproc || sysctl -n hw.ncpu)

# Get the absolute path to the directory this script is in.
NATIVE_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Run script inside a nix shell if it is available.
if command -v nix-shell && [ $NIX_PATH ] && [ -z $IN_NIX_SHELL ]; then
	cd ${NATIVE_DIR}
	nix-shell --pure --keep SCONS_CACHE --run "NIX_PATH=${NIX_PATH} ./build.sh $args"
	exit
fi

# Update git submodules.
updateSubmodules() {
	eval $1=$2 # E.g LIBUV_DIR=${NATIVE_DIR}/thirdparty/libuv

	if [ -z "$(ls -A -- "$2")" ]; then
		cd ${NATIVE_DIR}
		git submodule update --init --recursive -- $2
	fi
}

updateSubmodules LIBUV_DIR ${NATIVE_DIR}/thirdparty/libuv
updateSubmodules LIBTSM_DIR ${NATIVE_DIR}/thirdparty/libtsm 
updateSubmodules GODOT_CPP_DIR ${NATIVE_DIR}/thirdparty/godot-cpp

# Build libuv as a static library.
cd ${LIBUV_DIR}
mkdir -p build || true
cd build
args="-DCMAKE_BUILD_TYPE=$target -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
	-DCMAKE_OSX_ARCHITECTURES=$(uname -m)"
if [ "$target" == "release" ]; then
	args="$args -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL"
else
	args="$args -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL"
fi
cmake .. $args
cd ..
cmake --build build --config $target

# Build libgodot-xterm.
cd ${NATIVE_DIR}
scons target=template_$target arch=$(uname -m) disable_pty=$disable_pty

# Use Docker to build libgodot-xterm javascript.
if [ -x "$(command -v docker-compose)" ]; then
	UID_GID="0:0" TARGET=$target docker-compose build javascript
	UID_GID="$(id -u):$(id -g)" TARGET=$target docker-compose run --rm javascript
fi
