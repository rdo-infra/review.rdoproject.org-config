#!/bin/bash
# Recovers the list of packages installed inside a WeIRDO job that are provided
# from base CentOS repositories from an archived journalctl log.
# The purpose is to use this list of packages to pre-install them in the
# nodepool image to save a significant amount of time.

# This script PURPOSEFULLY does not recover any OpenStack-related packages or
# packages that are provided by RDO repositories.
# These OpenStack packages are installed inside the jobs as one of the objective
# of the jobs is to ensure that these packages work.

# URL to an archived journalctl.txt.gz file as argument
# i.e, http://46.231.133.241:8080/v1/AUTH_rdo/artifacts/31/1431/1/check/gate-weirdo-integration-master-packstack-scenario001/00cf242/artifacts/journalctl.txt.gz
journal="${1}"
curl -O ${journal}
gunzip journalctl.txt.gz

# The delorean repos appear in the journal, retrieve them dynamically and set them up
DELOREAN=$(egrep -wo "DELOREAN=.*" journalctl.txt || egrep -wo "url=.*delorean.repo" journalctl.txt)
DELOREAN=$(echo "${DELOREAN}" |awk '{print $1}' |cut -f2 -d =)

DELOREAN_DEPS=$(egrep -wo "DELOREAN_DEPS=.*" journalctl.txt || egrep -wo "url=.*delorean-deps.repo" journalctl.txt)
DELOREAN_DEPS=$(echo "${DELOREAN_DEPS}" |awk '{print $1}' |cut -f2 -d =)

curl $DELOREAN |tee /etc/yum.repos.d/delorean.repo
curl $DELOREAN_DEPS |tee /etc/yum.repos.d/delorean-deps.repo

# Retrieve the list of installed packages throughout the job
grep yum journalctl.txt |awk '/Installed/ {print $7}' |cut -f2 -d : > packages.txt

for package in $(cat packages.txt)
do
    echo -n "."
    name=$(repoquery -q --qf="%{name}" ${package} |uniq)
    repoquery -q --qf="%{repo}" ${name} |egrep -q "base|updates|extras" && echo ${name} >> real_packages.txt
done

# Sort packages, remove empty lines, remove centos-release packages
cat real_packages.txt |sort |sed -e "/^$/d" -e "/^centos-release.*/d" > real_packages.txt
