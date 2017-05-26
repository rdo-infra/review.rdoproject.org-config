#!/bin/bash
# This scripts takes as input a list provided by "rpm -qa |sort".
# Typically, input will be provided from a command ran at the end of a CI
# job to get the full list of packages that were installed as part of the run.

# The goal, afterwards, is to provide a list of packages that can be safely
# pre-installed prior to running jobs in order to save time.
# This is very rough around the edges but works right now. It does take a
# while to run due to having to verify each package dependencies recursively.

package_list="${1}"
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
echo "Resolving package names in ${package_list}..."
for package in $(cat "${package_list}"); do
    repoquery -q --qf="%{name}" "${package}" >>"resolved_${package_list}"
    echo -n "."
done
echo

# Generate a blacklist of packages that are found in openstack repositories
disable_base_repos
echo "Blacklisting first layer of packages..."
for package in $(cat "resolved_${package_list}"); do
    repoquery -q --qf="%{repo}" "${package}" |egrep -q "centos-|rdo|delorean" && echo "${package}" >>blacklist_tmp.txt
    echo -n "."
done

# Of those blacklisted packages, also retrieve packages that could require them
enable_base_repos
echo "Recursively blacklisting all first layer dependencies/requirements..."
for package in $(cat blacklist_tmp.txt)
do
    repoquery -q --qf="%{name}" --whatrequires --recursive --resolve "${package}" >>blacklist_tmp.txt
    echo -n "."
done

# Unify into a single blacklist
cat blacklist_tmp.txt |sort |uniq >blacklist.txt

# Remove delta/blacklist from full resolved package list
echo "Filtering initial package list..."
cp -p "resolved_${package_list}" filtered_packages.txt
for package in $(cat blacklist.txt)
do
    sed -i -e "/$package/d" "filtered_packages.txt"
    echo -n "."
done

echo "Done: filtered package list is inside filtered_packages.txt"
echo