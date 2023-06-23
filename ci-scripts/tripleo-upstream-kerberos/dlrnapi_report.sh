: ${EXTENDED_HASH:=""}

source $WORKSPACE/hash_info.sh
if [ "$SUCCESS" = "true" ] || [ "$SUCCESS" = "True" ]; then
    echo "REPORTING SUCCESS TO DLRN API"
else
    echo "REPORTING FAILURE TO DLRN API"
fi

if [[ "$FULL_HASH" == *"_"* ]]; then
    HASH_ARGS=" --commit-hash $COMMIT_HASH --distro-hash $DISTRO_HASH"
    # When voting on downstream include the extended hash
    if  [[ ! -z $EXTENDED_HASH ]]; then
        HASH_ARGS="$HASH_ARGS --extended_hash $EXTENDED_HASH"
    fi
else
    HASH_ARGS="--agg-hash $FULL_HASH"
fi

pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client[kerberos] shyaml
PATH=$PATH:$HOME/.local/bin
# TODO(evallesp): Delete when not testing. Not checking SSL Certificate by dlrnapi.
export SSL_VERIFY=0
dlrnapi --url $DLRNAPI_URL \
    --server-principal $DLRNAPI_SERVER_PRINCIPAL \
    --auth-method kerberosAuth \
    report-result \
    $HASH_ARGS \
    --job-id $TOCI_JOBTYPE \
    --info-url "$LOG_HOST_URL/$LOG_PATH" \
    --timestamp $(date +%s) \
    --success $SUCCESS

