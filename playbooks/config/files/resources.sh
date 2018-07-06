#!/bin/bash

set -e

GATEWAY_URL="https://review.rdoproject.org"
ENDPOINT="${GATEWAY_URL}/manage/v2/resources/"

APPLIED_OUTPUT="applied-output"
VALIDATED_OUTPUT="validated-output"

trap "rm -f $VALIDATED_OUTPUT && rm -f $APPLIED_OUTPUT" EXIT

[ -z "$1" ] && {
    echo "Valid arguments are validate, apply, direct_apply, get, get_missing_resources. Exit."
    exit 1
}

[ "$1" == "validate" ] && {
    echo "Requesting a resources validation for $GATEWAY_URL"
    # We are going to call a remote resources endpoint
    # We need a cauth cookie - request by username/passowrd
    [ ! -f .service_user_password ] && {
        echo "Unable to find service user password file"
        exit 1
    }
    username="SF_SERVICE_USER"
    cookie_payload=$(python <<SCRIPT
from sfmanager import sfauth
print(sfauth.get_cookie('$GATEWAY_URL', username='$username', password=open('.service_user_password').read().strip()))
SCRIPT
)
    [ -z "$cookie_payload" ] && {
        echo "Unabled to fetch the AUTH_PUB_TKT cookie"
        exit 1
    }
    COOKIE="--cookie 'auth_pubtkt=$cookie_payload'"
}


case $1 in
    validate)
        # Check tips of the HEAD is change on resources/
        HEAD_SHA=$(git --no-pager log --no-merges --format='%H' -n 1 HEAD)
        HEAD_RESOURCES_SHA=$(git --no-pager log --no-merges --format='%H' -n 1 HEAD -- resources)
        if [ "$HEAD_SHA" != "$HEAD_RESOURCES_SHA" ]; then
            echo
            echo "Nothing to validate on the resources."
            exit 0
        fi
        python <<SCRIPT
import os
import yaml
import json

data = dict([(os.path.join('resources', f), open(os.path.join('resources', f)).read())
	     for f in os.listdir('resources') if f.endswith('.yaml') or f.endswith('.yml')])
json.dump({'data': data}, open('data.json', 'w'))
SCRIPT
        http_code=$(curl -s $COOKIE -w "%{http_code}" -H "X-Remote-User: SF_SERVICE_USER" \
         -H "Content-Type: application/json" \
         -d @data.json -X POST $ENDPOINT -o $VALIDATED_OUTPUT)
        rm -f data.json
        cat $VALIDATED_OUTPUT | python -m json.tool
        [ "$http_code" != "200" ] && {
            echo "Resource modifications validation failed (API return code: $http_code)."
            exit 1
        }
        git log -1 --no-merges
        if git log -1 --no-merges | grep "sf-resources: allow-delete" > /dev/null; then
            delete_authorized="true"
        else
            delete_authorized="false"
        fi
        if cat $VALIDATED_OUTPUT | grep "is going to be deleted" > /dev/null; then
            if [ "$delete_authorized" == "false" ]; then
                echo
                echo "Resources deletion(s) have been detected."
                echo "The commit msg tag: 'sf-resources: allow-delete' has not been detected."
                echo "The change won't be validated until you include the tag 'sf-resources: allow-delete'"
                echo "in the commit message."
                exit 1
            fi
        fi
        if git log -1 --no-merges | grep "sf-resources: skip-apply" > /dev/null; then
            echo
            echo "The commit msg tag: 'sf-resources: skip-apply' has been detected."
            echo "The approval of this patch won't trigger the creation of the resources above."
            echo "The purpose of this commit is usually to re-sync config/resources with the reality."
        fi
        exit 0
        ;;
    *)
        echo "Action not supported."
        ;;
esac
