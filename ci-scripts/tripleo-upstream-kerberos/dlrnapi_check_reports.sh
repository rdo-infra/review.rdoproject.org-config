#!/bin/bash

set -eu

: ${EXTENDED_HASH:=""}

source $WORKSPACE/hash_info.sh
pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client[kerberos] shyaml
PATH=$PATH:/home/$USER/.local/bin

DLRN_API_HASH_ARGS="--commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH"

if [[ ! -z $EXTENDED_HASH ]]; then
    DLRN_API_HASH_ARGS="$DLRN_API_HASH_ARGS \
    --extended-hash $EXTENDED_HASH"
fi
# TODO(evallesp): Delete when not testing. Not checking SSL Certificate by dlrnapi.
export SSL_VERIFY=0
dlrnapi --url $DLRNAPI_URL \
    --server-principal $DLRNAPI_SERVER_PRINCIPAL \
    --auth-method kerberosAuth \
    repo-status  \
    --force-auth \
    $DLRN_API_HASH_ARGS \
    --success true | tee -a $WORKSPACE/repo_success_output.txt
