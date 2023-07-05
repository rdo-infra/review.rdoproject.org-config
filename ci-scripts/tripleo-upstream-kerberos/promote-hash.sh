set -e

echo ======== PROMOTE HASH

source $DLRN_VENV_SCRIPT_PATH/dlrnapi_venv.sh

trap deactivate_dlrnapi_venv EXIT
activate_dlrnapi_venv

: ${DLRNAPI_USERNAME:="review_rdoproject_org"}
: ${HASH_INFO_FILE:="$WORKSPACE/hash_info.sh"}
: ${EXTENDED_HASH:=""}

source $HASH_INFO_FILE

set -u

DLRN_API_HASH_ARGS="--commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH"

if [[ ! -z $EXTENDED_HASH ]]; then
    DLRN_API_HASH_ARGS="$DLRN_API_HASH_ARGS \
    --extended-hash $EXTENDED_HASH"
fi
pip_cmd=$(command -v pip || command -v pip3)

if [[ $KERBEROS_AUTH = true ]]; then
    $pip_cmd install --user dlrnapi-client[kerberos] shyaml
else
    $pip_cmd install --user dlrnapi-client shyaml
fi

PATH=$PATH:$HOME/.local/bin
# Assign label to the specific hash using the DLRN API
if [[ ! -z $DLRNAPI_SERVER_PRINCIPAL ]] && [[ $KERBEROS_AUTH = true ]]; then
    dlrnapi --url $DLRNAPI_URL \
        --server-principal $DLRNAPI_SERVER_PRINCIPAL \
        --auth-method kerberosAuth \
        repo-promote \
        $DLRN_API_HASH_ARGS \
        --promote-name $PROMOTE_NAME
else
    dlrnapi --url $DLRNAPI_URL \
        --username $DLRNAPI_USERNAME \
        repo-promote \
        $DLRN_API_HASH_ARGS \
        --promote-name $PROMOTE_NAME
fi

echo ======== PROMOTE HASH COMPLETED
