#!/bin/bash
# Retrieves or updates an existing repository for
# opendev.org/openstack/project-config for the purpose of re-using
# the nodepool elements and scripts from it.

# This is set up as a cron on nodepool-builder instances as such:
# */5 * * * * /usr/local/bin/project-config-nodepool.sh 2>&1 | systemd-cat -t project-config-nodepool.sh -p info
# Logs available with "journalctl -t project-config-nodepool.sh"

LOCKFILE="/tmp/project-config-nodepool.lock"
SERVER="opendev.org"
DIR="/opt/git"
NAMESPACE="openstack-infra"
PROJECT="project-config"
PROJECT_DIR="${DIR}/${NAMESPACE}/${PROJECT}"

# Check for lockfile so we don't pile up processes (i.e, if git is stuck)
if [[ -e "${LOCKFILE}" ]]; then
    pid=$(cat "${LOCKFILE}")
    echo "${0} already running as pid ${pid}, killing it"
    kill "${pid}"
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

if [[ ! -d "${DIR}/${NAMESPACE}" ]]; then
    echo "${DIR}/${NAMESPACE} doesn't exist, creating it..."
    mkdir -p "${DIR}/${NAMESPACE}"
fi
if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo "${PROJECT_DIR} doesn't exist, cloning it..."
    git clone "git://${SERVER}/${NAMESPACE}/${PROJECT}" "${PROJECT_DIR}"
else
    echo "${PROJECT_DIR} exists, updating it..."
    pushd ${PROJECT_DIR}
        git reset --hard
        git pull origin master
    popd
fi

rm -f "${LOCKFILE}"
