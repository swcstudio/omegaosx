#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

set -e

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OMEGA_ROOT_DIR=${SCRIPT_DIR}/../..
VERSION=$( cat ${OMEGA_ROOT_DIR}/VERSION )
IMAGE_NAME="omegaosx/osxdk:${VERSION}"

docker run -it -v ${OMEGA_ROOT_DIR}:/root/omegaosx ${IMAGE_NAME}
