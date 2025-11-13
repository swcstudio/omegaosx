#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

set -e

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OMEGA_SRC_DIR=${SCRIPT_DIR}/../..
CARGO_TOML_PATH=${SCRIPT_DIR}/../../Cargo.toml
VERSION=$( cat ${OMEGA_SRC_DIR}/VERSION )
IMAGE_NAME="omegaosx/omegaosx:${VERSION}"

docker run -it --privileged --network=host --device=/dev/kvm --device=/dev/vhost-net -v ${OMEGA_SRC_DIR}:/root/omegaosx ${IMAGE_NAME}
