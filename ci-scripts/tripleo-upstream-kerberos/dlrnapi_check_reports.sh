#!/bin/bash

set -eu

: ${EXTENDED_HASH:=""}

source $WORKSPACE/hash_info.sh
pip_cmd=$(command -v pip || command -v pip3)

if [[ $KERBEROS_AUTH = true ]]; then
    $pip_cmd install --user dlrnapi-client[kerberos] shyaml
else
    $pip_cmd install --user dlrnapi-client shyaml
fi

PATH=$PATH:/home/$USER/.local/bin

DLRN_API_HASH_ARGS="--commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH"

if [[ ! -z $EXTENDED_HASH ]]; then
    DLRN_API_HASH_ARGS="$DLRN_API_HASH_ARGS \
    --extended-hash $EXTENDED_HASH"
fi

if [[ ! -z $DLRNAPI_SERVER_PRINCIPAL ]] && [[ $KERBEROS_AUTH = true ]]; then
    dlrnapi --url $DLRNAPI_URL \
        --server-principal $DLRNAPI_SERVER_PRINCIPAL \
        --auth-method kerberosAuth \
        --force-auth \
        repo-status  \
        $DLRN_API_HASH_ARGS \
        --success true | tee -a $WORKSPACE/repo_success_output.txt
else
    dlrnapi --url $DLRNAPI_URL \
        repo-status  \
        $DLRN_API_HASH_ARGS \
        --success true | tee -a $WORKSPACE/repo_success_output.txt
fi