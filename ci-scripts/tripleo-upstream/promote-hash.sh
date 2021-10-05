set -e

echo ======== PROMOTE HASH

export REQUESTS_CA_BUNDLE=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt

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

# Assign label to the specific hash using the DLRN API
dlrnapi --url $DLRNAPI_URL \
    --username $DLRNAPI_USERNAME \
    repo-promote \
    $DLRN_API_HASH_ARGS \
    --promote-name $PROMOTE_NAME


echo ======== PROMOTE HASH COMPLETED
