set -e
echo ======== UPLOAD CLOUD IMAGES
source $WORKSPACE/hash_info.sh

pushd $HOME

ls *.tar *.qcow2 || true

export RSYNC_RSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
rsync_cmd="rsync --verbose --archive --no-perms --no-owner --no-group --delay-updates --relative"

DISTRO="${DISTRO_NAME}${DISTRO_VERSION}"

# If set by downstream/internal SF jobs don't override UPLOAD_URL
if [ -z "$UPLOAD_URL" ]; then
    if [ -n "$DISTRO" ]; then
        if [[ "$DISTRO" =~ "redhat" ]]; then
            UPLOAD_URL=rcm-uploader@images.rdoproject.org:/var/www/html/images/rhel/images/$DISTRO/$RELEASE/rdo_trunk
        else
            UPLOAD_URL=uploader@images.rdoproject.org:/var/www/html/images/$DISTRO/$RELEASE/rdo_trunk
        fi
    else
        # Legacy url for very old ditro-unaware jobs
        UPLOAD_URL=uploader@images.rdoproject.org:/var/www/html/images/$RELEASE/rdo_trunk
    fi
fi
echo "UPLOAD_URL is $UPLOAD_URL"


# Check if directory $FULL_HASH exists, if not create it.
if [ ! -d $FULL_HASH ]; then
    mkdir -p $FULL_HASH
fi
if [ -f "overcloud-full.tar" ]; then
    mv overcloud-full.tar overcloud-full.tar.md5 $FULL_HASH
fi
if [ -f "overcloud-hardened-uefi-full.qcow2" ]; then
    mv overcloud-hardened-uefi-full.qcow2 overcloud-hardened-uefi-full.qcow2.md5 $FULL_HASH
fi
if [ -f "ironic-python-agent.tar" ]; then
    mv ironic-python-agent.tar ironic-python-agent.tar.md5 $FULL_HASH
fi

$rsync_cmd $FULL_HASH $UPLOAD_URL
$rsync_cmd --delete --include 'tripleo-ci-testing**' --exclude '*' ./ $UPLOAD_URL/
# Creating link to tripleo-ci-testing with actual $FULL_HASH
ln -s $FULL_HASH tripleo-ci-testing

rsync -av tripleo-ci-testing $UPLOAD_URL

popd
echo ======== UPLOAD CLOUD IMAGES COMPLETE
