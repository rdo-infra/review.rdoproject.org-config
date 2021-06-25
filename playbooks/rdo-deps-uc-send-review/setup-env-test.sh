#!/bin/bash

rm -rf workspace
mkdir workspace

pushd workspace

git clone git@github.com:rdo-infra/releng.git
git clone https://review.rdoproject.org/cgit/gating_scripts
git clone git clone https://github.com/openstack/requirements
pushd gating_scripts
git review -d 33506
popd
git clone https://github.com/redhat-openstack/rdoinfo
pushd rdoinfo
echo "- project: python-aniso8601" | tee -a buildsys-tags/cloud8s-openstack-xena-candidate.yml >/dev/null
echo "  buildsys-tags:" | tee -a buildsys-tags/cloud8s-openstack-xena-candidate.yml >/dev/null
echo "    cloud8s-openstack-xena-candidate: python-aniso8601-8.1.1-1.el8" | tee -a buildsys-tags/cloud8s-openstack-xena-candidate.yml >/dev/null
popd

popd
