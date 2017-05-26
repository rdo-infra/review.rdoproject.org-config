#!/bin/bash

. rdo-base.sh
. rdo-rpmfactory-base.sh

sudo cp run-tox.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/run-tox.sh

sudo yum -y install centos-release-openstack-liberty

# https://github.com/openstack-infra/system-config/blob/master/modules/openstack_project/manifests/thick_slave.pp
sudo yum install -y mariadb-devel postgresql-devel libjpeg-devel gcc-c++ \
                    zeromq-devel libxslt-devel sqlite-devel libvirt-devel \
                    openldap-devel libxml2-devel liberasurecode-devel \
                    openssl-devel

sudo yum -y remove centos-release-openstack-liberty

# install wait_for_other_jobs
sudo wget https://raw.githubusercontent.com/redhat-cip/software-factory/master/tools/slaves/wait_for_other_jobs.py -O /usr/local/bin/wait_for_other_jobs.py
sudo chmod +x /usr/local/bin/wait_for_other_jobs.py

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Setup finished. Creating snapshot now, this will take a few minutes"
