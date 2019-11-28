#!/bin/bash

set -eu

source $WORKSPACE/hash_info.sh
pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client shyaml
PATH=$PATH:/home/$USER/.local/bin
dlrnapi --url $DLRNAPI_URL \
    repo-status  \
    --commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH \
    --success true
