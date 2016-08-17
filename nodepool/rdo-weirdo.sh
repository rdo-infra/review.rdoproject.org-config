#!/bin/bash
# Optimizes an image for use with WeIRDO to save significant time on jobs.

. rdo-base.sh
. rdo-rpmfactory-base.sh

# See "rdo-weirdo-get-packages.sh" for package retrieval method
cat weirdo-packages.txt |xargs sudo yum -y install

# Pre-cache Cirros images for use with puppet-openstack-integration and
# Packstack tests
mkdir -p ~/cache/files
wget --tries=10 http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-uec.tar.gz -P ~/cache/files/
wget --tries=10 http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img -P ~/cache/files/
