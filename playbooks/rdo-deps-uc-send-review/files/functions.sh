#!/bin/bash

# function is_patch_already() is used to get URL of patches
# which bump the dependency to desired version.
# params: pkg_name, pkg_vers and branch
# returns: 0 if URLs found, 1 else
#          it appends the DEPENDS_ON variable with the URLs
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
