#!/bin/bash -xe

# Copyright (C) 2014 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

export PATH=$PATH:/usr/local/sbin:/usr/sbin

. rdo-base.sh

echo "" >> /home/jenkins/.ssh/authorized_keys
cat /etc/nodepool/id_rsa.pub >> /home/jenkins/.ssh/authorized_keys
echo "" >> /home/jenkins/.ssh/authorized_keys

ROLE=$(cat /etc/nodepool/role)
if [ $ROLE == "primary" ]; then
    cp /etc/nodepool/id_rsa /home/jenkins/.ssh/id_rsa
    chmod 0600 /home/jenkins/.ssh/id_rsa
else
    rm /etc/nodepool/id_rsa
fi

sudo chown -R root:root /etc/nodepool
sudo chmod 0755 /etc/nodepool
sudo chmod 0444 /etc/nodepool/*
