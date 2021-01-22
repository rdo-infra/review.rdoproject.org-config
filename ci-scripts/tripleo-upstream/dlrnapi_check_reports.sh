#!/bin/bash

set -eu

: ${EXTENDED_HASH:=""}

source $WORKSPACE/hash_info.sh
pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client shyaml
PATH=$PATH:/home/$USER/.local/bin

DLRN_API_HASH_ARGS="--commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH"

if [[ ! -z $EXTENDED_HASH ]]; then
    DLRN_API_HASH_ARGS="$DLRN_API_HASH_ARGS \
    --extended-hash $EXTENDED_HASH"
fi

dlrnapi --url $DLRNAPI_URL \
    repo-status  \
    $DLRN_API_HASH_ARGS \
    --success true | tee -a $WORKSPACE/repo_success_output.txt
