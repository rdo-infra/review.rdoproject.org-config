#!/bin/bash
set -ex

# Simple script to test several DLRN packages
GIT_BASE_URL="https://review.rdoproject.org/r/p"
TAG="${1:-pike-uc}"
PACKAGES_TO_BUILD="${2:-python-glanceclient}"
PROJECT_DISTRO_BRANCH="rpm-master"

# Setup virtualenv with tox and use it
tox -epy27 --notest
. .tox/py27/bin/activate

# Prepare config
target="centos"
baseurl="http://trunk.rdoproject.org/centos7/"
src="master"
branch=""
tag="pike-uc"

# If we're testing a commit on a specific branch, make sure we're using it
if [[ "${TAG}" != "pike-uc" ]]; then
    branch=$(echo $TAG | awk -F- '{print $1}')
    tag=$TAG
    baseurl="http://trunk.rdoproject.org/${branch}/centos7/"
    src="stable/${branch}"
    if [ $TAG = "mitaka" ]; then
        PROJECT_DISTRO_BRANCH="rpm-${TAG}"
    else
        PROJECT_DISTRO_BRANCH="${TAG}-rdo"
    fi
fi

# Update the configuration
sed -i "s%target=.*%target=${target}%" projects.ini
sed -i "s%source=.*%source=${src}%" projects.ini
sed -i "s%baseurl=.*%baseurl=${baseurl}%" projects.ini
sed -i "s%tags=.*%tags=${tag}%" projects.ini

PACKAGE_LINE=""
# Prepare directories
mkdir -p data/repos
for PACKAGE in ${PACKAGES_TO_BUILD}; do
    PROJECT_TO_BUILD_MAPPED=$(rdopkg findpkg $PACKAGE -l ../rdoinfo | grep ^name | awk '{print $2}')
    PROJECT_IN_RDOINFO=$(rdopkg findpkg $PACKAGE -l ../rdoinfo | grep ^project: | awk '{print $2}')
    if [[ "$PROJECT_IN_RDOINFO" =~ puppet- ]]; then
        PROJECT_DISTRO="puppet/$PROJECT_IN_RDOINFO-distgit"
    else
        PROJECT_DISTRO="openstack/$PROJECT_IN_RDOINFO-distgit"
    fi
    PROJECT_DISTRO_DIR=${PROJECT_TO_BUILD_MAPPED}_distro

    if [ -e /usr/bin/zuul-cloner ]; then
        zuul-cloner --workspace data/ $GIT_BASE_URL $PROJECT_DISTRO --branch $PROJECT_DISTRO_BRANCH
        mv data/$PROJECT_DISTRO data/$PROJECT_DISTRO_DIR
    else
        # We're outside the gate, just do a regular git clone
        pushd data/
        # rm -rf first for idempotency
        rm -rf $PROJECT_DISTRO_DIR
        git clone "${GIT_BASE_URL}/${PROJECT_DISTRO}" $PROJECT_DISTRO_DIR
        cd $PROJECT_DISTRO_DIR
        git checkout $PROJECT_DISTRO_BRANCH
        popd
    fi
    PACKAGE_LINE="$PACKAGE_LINE --package-name $PACKAGE"
done


# If the commands below throws an error we still want the logs
function copy_logs() {
    mkdir -p logs
    rsync -avzr data/repos logs/centos
}
trap copy_logs ERR EXIT

# Run DLRN
dlrn --config-file projects.ini --head-only $PACKAGE_LINE --dev --info-repo ../rdoinfo
copy_logs
# Clean up mock cache, just in case there is a change for the next run
mock -r data/dlrn-1.cfg --scrub=all
