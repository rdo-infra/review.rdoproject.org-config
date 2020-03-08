#!/bin/bash

set -eu

: ${PROMOTE_TARGET:="promoted-components"}

source $WORKSPACE/hash_info.sh
pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client shyaml
PATH=$PATH:/home/$USER/.local/bin

dlrnapi --url $DLRNAPI_URL \
    promotion-get  \
    --commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH \
    --promote-name $PROMOTE_TARGET \
    | tee -a $WORKSPACE/commit_hash_promote_target_output.txt
