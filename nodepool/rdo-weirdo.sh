#!/bin/bash
# Optimizes an image for use with WeIRDO to save significant time on jobs.

. rdo-base.sh
. rdo-rpmfactory-base.sh

# See "rdo-weirdo-get-packages.sh" for package retrieval method
cat weirdo-packages.txt |xargs yum -y install