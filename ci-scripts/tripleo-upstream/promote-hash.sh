set -e

echo ======== PROMOTE HASH

source $DLRN_VENV_SCRIPT_PATH/dlrnapi_venv.sh

trap deactivate_dlrnapi_venv EXIT
activate_dlrnapi_venv

: ${DLRNAPI_USERNAME:="review_rdoproject_org"}
: ${HASH_INFO_FILE:="$WORKSPACE/hash_info.sh"}

source $HASH_INFO_FILE

set -u

# Assign label to the specific hash using the DLRN API
dlrnapi --url $DLRNAPI_URL \
    --username $DLRNAPI_USERNAME \
    repo-promote \
    --commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH \
    --promote-name $PROMOTE_NAME

echo ======== PROMOTE HASH COMPLETED
