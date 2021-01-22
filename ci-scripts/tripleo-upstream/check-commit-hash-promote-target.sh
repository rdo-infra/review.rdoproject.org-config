#!/bin/bash

set -eu

: ${PROMOTE_TARGET:="promoted-components"}
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
    promotion-get  \
    $DLRN_API_HASH_ARGS \
    --promote-name $PROMOTE_TARGET \
    | tee -a $WORKSPACE/commit_hash_promote_target_output.txt
