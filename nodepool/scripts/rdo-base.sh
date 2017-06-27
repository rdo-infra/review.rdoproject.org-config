#!/bin/bash
# RDO "fork" of base.sh

set -xe

# Setup unbound as a forwarding DNS server
sudo yum -y install unbound
cat >> /tmp/forwarding.conf << EOF
forward-zone:
  name: "."
  forward-addr: 208.67.222.222
  forward-addr: 8.8.8.8
EOF
sudo systemctl enable unbound
sudo cp /tmp/forwarding.conf /etc/unbound/conf.d/forwarding.conf
sudo restorecon -R /etc/unbound
sudo chmod +x /etc/rc.d/rc.local
echo "sed 's/nameserver.*/nameserver 127.0.0.1/' /etc/resolv.conf" |sudo tee -a /etc/rc.d/rc.local

sudo yum update -y > /dev/null

# Base requirements
sudo yum install -y python-setuptools git wget curl patch iproute \
                    libffi-devel openssl-devel libxml2-devel \
                    libxslt-devel ruby-devel redhat-lsb-core \
                    libselinux-python yum-plugin-priorities \
                    rubygems net-tools lsof
sudo easy_install pip
sudo pip install tox twine

# The jenkins user. Must be able to use sudo without password
sudo useradd -m jenkins
sudo gpasswd -a jenkins wheel
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers.d/90-cloud-init-users
echo "Defaults   !requiretty" | sudo tee --append /etc/sudoers.d/90-cloud-init-users

# SSH key for the Jenkins user
sudo mkdir /home/jenkins/.ssh
sudo cp /opt/nodepool-scripts/authorized_keys /home/jenkins/.ssh/authorized_keys
sudo ssh-keygen -N '' -f /home/jenkins/.ssh/id_rsa
sudo chown -R jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chmod 600 /home/jenkins/.ssh/authorized_keys
sudo restorecon -R -v /home/jenkins/.ssh/authorized_keys

# Nodepool will try to connect on the fresh node using the user
# defined as username in the provider.image section conf. Usually
# it is the clouduser. So fetch it and authorize the pub key
# for that user.
cloud_user=$(egrep " name:" /etc/cloud/cloud.cfg | awk '{print $2}')
cat /opt/nodepool-scripts/authorized_keys | sudo tee -a /home/$cloud_user/.ssh/authorized_keys

# Install java (required by Jenkins)
sudo yum install -y java

# Install zuul_swift_upload and zuul-cloner
# TODO: replace this section by zuul package
sudo yum install -y python-requests gcc python-devel python-crypto
sudo pip install zuul glob2 python-magic requestsexceptions

# Patch Zuul-Cloner https://review.openstack.org/#/c/442370/
pushd /usr/lib/python2.7/site-packages
sudo patch -p1 < /opt/nodepool-scripts/PATCH-Find-fallback-branch-in-zuul-cloner.patch
popd

# Copy slave tools
sudo cp -v /opt/nodepool-scripts/*.py /usr/local/bin/

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Base setup done."
