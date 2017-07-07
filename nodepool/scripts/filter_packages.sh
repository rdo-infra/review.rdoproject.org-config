#!/bin/bash
# This scripts takes as input a list provided by "rpm -qa |sort":
# ./filter_packages.sh list.txt

# Typically, input will be provided from a command ran at the end of a CI
# job to get the full list of packages that were installed as part of the run.

# The script:
#  1) Resolves the package names from the rpm -qa output
#  2) Blacklists verbatim matches in blacklisted repositories (RDO and release_packages)
#  3) Blacklists packages which requires blacklisted packages
#  4) Filters the initial list of packages against the comprehensive blacklist
#  5) Provides a list of packages that is *only* available on CentOS base repos
#     and does not require packages which are found in blacklisted repositories

# This script takes a long time to run due to the recursive nature of checking
# each package's dependencies.

# RDO repositories should be set up prior to running this script but is not
# enforced here -- it could be trunk repositories (delorean/delorean-deps)
# for example. If RDO repositories are not set up, there will be false
# positives.

# Even after all that, all additions and deletions are manually verified to
# ensure we're not introducing a package we're not interested in.

package_list="${1}"
filtered="filtered.txt"
resolved=$(mktemp)
blacklist_tmp=$(mktemp)
blacklist=$(mktemp)

release_packages="centos-release-ceph-jewel centos-release-qemu-ev"
export base_repositories="base updates extras"

function enable_base_repos() {
    echo "Enabling base repositories..."
    for repository in "${base_repositories}"; do
        yum-config-manager --enable ${repository} >/dev/null
        echo -n "."
    done
    echo
}

function disable_base_repos() {
    echo "Disabling base repositories..."
    for repository in "${base_repositories}"; do
        yum-config-manager --disable ${repository} >/dev/null
        echo -n "."
    done
    echo
}

# Install release packages
echo "Intalling release packages..."
yum -y install ${release_packages}

# Resolve package names
enable_base_repos
echo "Resolving $(wc -l ${package_list} |awk '{print $1}') package names from ${package_list}..."
for package in $(cat "${package_list}"); do
    repoquery -q --qf="%{name}" "${package}" >>${resolved}
    echo -n "."
done
echo

# Generate a blacklist of packages that are found in openstack repositories
disable_base_repos
echo "Blacklisting first layer of packages..."
for package in $(cat ${resolved}); do
    repoquery -q --qf="%{repo}" "${package}" |egrep -q "centos-|rdo|delorean" && echo "${package}" >>${blacklist_tmp}
    echo -n "."
done

# Of those blacklisted packages, also retrieve packages that could require them
enable_base_repos
echo "Recursively blacklisting all first layer dependencies/requirements... this will take a long time!"
for package in $(cat ${blacklist_tmp})
do
    repoquery -q --qf="%{name}" --whatrequires --recursive --resolve "${package}" >>${blacklist_tmp}
    echo -n "."
done

# Unify into a single cleaned up blacklist
cat ${blacklist_tmp} |sort |uniq >${blacklist}
echo "Working with $(wc -l ${blacklist} |awk '{print $1}') packages in the comprehensive blacklist."

# Remove delta/blacklist from full resolved package list
echo "Filtering initial package list..."
cp -p ${resolved} ${filtered}
for package in $(cat ${blacklist})
do
    sed -i -e "/$package/d" ${filtered}
    echo -n "."
done

echo "Done: filtered package list is inside ${filtered}"
echo
