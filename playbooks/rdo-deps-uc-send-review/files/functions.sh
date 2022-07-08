#!/bin/bash

# function is_patch_already() aims to check whether a patch
# which bumps the dependency to desired version exists or not.
# params: pkg_name, pkg_vers and branch
# returns: 0 if patch found, 1 else
function is_patch_already() {
    local pkg_name=${1:-$pkg_name}
    local pkg_vers=${2:-$pkg_vers}
    local branch=${3:-$branch}
	local change_endpoint_url=""
	local change_url=""
	local specfile=""

    local opened_changes=$(ssh -p 29418 amoralej+rdo-trunk@review.rdoproject.org \
                           gerrit query --format=JSON \
                           status:open \
                           project:deps/${pkg_name} \
                           branch:${branch}
                          )
    local change_ids=$(echo "$opened_changes" | jq '.id' | tr -d '"' | sed "s/null//")

    for change_id in $change_ids; do
        change_endpoint_url="https://review.rdoproject.org/r/changes/deps%2F$pkg_name~$branch~$change_id/revisions/current"
        specfile=$(curl -s -f $change_endpoint_url/files/ | sed 1d | jq 'keys[]' | tr -d '"' | grep -e "\.spec$")
        if [ $? -eq 0 ]; then
            specfile=$(echo "$specfile" | sed "s/\//%2f/")
            curl -s -f $change_endpoint_url/files/$specfile/content | base64 -d | grep -e "^Version:.*$pkg_vers" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                return 0
            fi
        fi
    done
	return 1
}

# function is_in_rdoinfo_patch_already() aims to check if
# the NVR is already present in rdoinfo opened patch.
# params: nvr, release and topic
# returns: 0 if NVR found, 1 else
function is_in_rdoinfo_patch_already() {
    local nvr=${1:-$nvr}
    local release=${2:-$release}
    local topic=${3:-$topic}
    local tmp_dir="/tmp/rdoinfo_${topic}_opened_change_ids/"
    local cache_filename="${tmp_dir}/ids"
	mkdir $tmp_dir >/dev/null 2>&1
	# We cache the files for 10 minutes
	is_cache=$(find $cache_filename -type f -mmin -10 2>/dev/null)
	if [ ! -f "$is_cache" ]; then
        ssh -p 29418 amoralej+rdo-trunk@review.rdoproject.org \
                     gerrit query --format=JSON \
                     status:open \
                     project:rdoinfo \
                     topic:$topic \
                     branch:master | jq '.id' | tr -d '"' | sed "s/null//"> $cache_filename

        while read change_id; do
            change_endpoint_url="https://review.rdoproject.org/r/changes/rdoinfo~master~$change_id/revisions/current"
            specfile=$(curl -s -f $change_endpoint_url/files/ | sed 1d | jq 'keys[]' | tr -d '"' | grep -e "${release}-testing.yml$")
            if [ $? -eq 0 ]; then
                specfile=$(echo "$specfile" | sed "s/\//%2f/")
                curl -s -f $change_endpoint_url/files/$specfile/content | base64 -d > ${tmp_dir}/${change_id}-${release}-testing.yml
            fi
        done < $cache_filename
    fi

    grep -e "$nvr" $tmp_dir/* >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}
