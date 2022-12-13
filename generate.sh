#
# Generate a release bundle of CEF (Chromium Embedded Framework) for Open592.
#
# The goal of this program is to enable generating a release
# bundle of CEF which the Open592 browsercontrol can utilize
# to drive it's webview on Linux. We support the same architectures
# that CEF does:
#
# - x86_64
# - ARM
# - ARM64
#
# The following software is required to run this script:
#
# - uname
# - curl
# - cmake
#
# Please see the LICENSE.txt file for license information.
#

#!/usr/bin/env bash

set -euo pipefail

log() {
    echo "[${0##*/}]: $1" >&2;
}

fatal() {
    log "<FATAL> $1";
    exit 1;
}

ARCH=$1
CEF_ARCH="notfound"

log "Executing generate.sh for ${ARCH} on $(uname -m)"

if [ "${ARCH}" == "x86_64" ]; then
    CEF_NAME="cef_binary_107.1.12+g65b79a6+chromium-107.0.5304.122_linux64"
elif [ "${ARCH}" == "armv7" ]; then
    CEF_NAME="cef_binary_107.1.12+g65b79a6+chromium-107.0.5304.122_linuxarm"
elif [ "${ARCH}" == "aarch64" ]; then
    CEF_NAME="cef_binary_107.1.12+g65b79a6+chromium-107.0.5304.122_linuxarm64"
else
    fatal "Unsupported architecture ${ARCH}"
fi

CEF_DOWNLOAD_URL="https://cef-builds.spotifycdn.com/${CEF_NAME}_minimal.tar.bz2"

log "Downloading CEF from ${CEF_DOWNLOAD_URL}"

if ! [ -x "$(command -v curl)" ]; then
    fatal "This script requires curl to be installed"
fi

if ! [ -x "$(command -v cmake)" ]; then
    fatal "This script requires cmake to be installed"
fi

if ! [ -x "$(command -v strip)" ]; then
    fatal "This script requires strip to be installed"
fi

mkdir ./working-dir
curl --create-dirs -o ./working-dir/cef.tar.bz2 ${CEF_DOWNLOAD_URL}
cd ./working-dir

tar -xvjf cef.tar.bz2 --strip-components=1 -C ./

mkdir build && cd build

cmake ../

make libcef_dll_wrapper

# Move into working-dir
cd ../

mkdir ./artifacts

cp -a ./build/libcef_dll_wrapper/libcef_dll_wrapper.a ./artifacts
cp -a ./Release/*.so ./artifacts
cp -a ./include ./artifacts

# Strip symbols
strip -w ./artifacts/*.so ./artifacts/*.a

# Package up artifacts
mkdir ./outputs

tar -cvjSf ./outputs/${CEF_NAME}.tar.bz2 artifacts