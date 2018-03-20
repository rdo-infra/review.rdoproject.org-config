#!/bin/bash
# Optimizes an image for use with WeIRDO to save significant time on jobs.

. rdo-base.sh
. rdo-rpmfactory-base.sh

# Pre-install base packages unrelated to RDO or OpenStack to speed up jobs
# See "filter_packages.sh" for package retrieval method
cat weirdo-packages.txt |xargs sudo yum -y install

# we run weirdo jobs in permissive mode in ci.centos.org so we should do it
# also in review.rdoproject.org or gate jobs using current-passed-ci could fail

sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/sysconfig/selinux

arch="$(uname -p)"

# Pre-cache Cirros images for use with puppet-openstack-integration and
# Packstack tests
mkdir -p ~/cache/files

case $arch in
    x86_64)
        cirros_version="0.3.4"
        ;;
    ppc64le)
        cirros_version="0.4.0"
        ;;
esac

wget --tries=10 http://download.cirros-cloud.net/$cirros_version/cirros-$cirros_version-$arch-uec.tar.gz -P ~/cache/files/
wget --tries=10 http://download.cirros-cloud.net/$cirros_version/cirros-$cirros_version-$arch-disk.img -P ~/cache/files/
