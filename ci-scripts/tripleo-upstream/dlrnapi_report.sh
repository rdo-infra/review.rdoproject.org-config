source $WORKSPACE/hash_info.sh
if [ "$SUCCESS" = "true" ] || [ "$SUCCESS" = "True" ]; then
    echo "REPORTING SUCCESS TO DLRN API"
else
    echo "REPORTING FAILURE TO DLRN API"
fi
pip_cmd=$(command -v pip || command -v pip3)
$pip_cmd install --user dlrnapi-client shyaml
PATH=$PATH:/home/$USER/.local/bin
dlrnapi --url $DLRNAPI_URL \
    report-result \
    --commit-hash $COMMIT_HASH \
    --distro-hash $DISTRO_HASH \
    --job-id $TOCI_JOBTYPE \
    --info-url "$LOG_HOST_URL/$LOG_PATH" \
    --timestamp $(date +%s) \
    --success $SUCCESS

