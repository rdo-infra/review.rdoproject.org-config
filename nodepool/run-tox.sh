#!/bin/bash -x

# https://github.com/openstack-infra/project-config/blob/master/jenkins/scripts/run-tox.sh

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pbr freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#
# Usage: run-tox.sh VENV
#
# Where VENV is the name of the tox environment to run (specified in the
# project's tox.ini file).

venv=$1

if [[ -z "$venv" ]]; then
    echo "Usage: $?"
    echo
    echo "VENV: The tox environment to run (eg 'python27')"
    exit 1
fi

function freeze_venv {
    [ -e $bin_path/pbr ] && freezecmd=pbr || freezecmd=pip

    echo "Begin $freezecmd freeze output from test virtualenv:"
    echo "======================================================================"
    ${bin_path}/${freezecmd} freeze
    echo "======================================================================"
}

bin_path=.tox/$venv/bin

export TMPDIR=$(/bin/mktemp -d)
export UPPER_CONSTRAINTS_FILE=$(pwd)/upper-constraints.txt
trap "rm -rf $TMPDIR" EXIT

tox -v -e$venv
result=$?

freeze_venv

exit $result
