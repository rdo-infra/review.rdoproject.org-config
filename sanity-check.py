#!/usr/bin/env python
# Ensures that every Gerrit project is configured in Gerrit replication,
# Zuul layout and Gerritbot.

from __future__ import print_function

import collections
import glob
import json
import re
import requests
import sys
import yaml
from six.moves import configparser, StringIO

GERRIT = "https://review.rdoproject.org/r/"
PROJECT_LIST = GERRIT + "/projects/"
# Note (dmsimard): centos-opstools might be sent to #centos-devel,
#                  need to verify with them first.
IGNORED_PROJECTS = {
    'replication': [
        'All-Users',
        'gating_scripts',
        'openstack/whitebox-tempest-plugin',
        'rdo',
        'rdo_gating_scripts',
        'testbranching',
        'testproject'
    ],
    'zuul': [
        'All-Users',
        'config',
        'gating_scripts',
        'rdo',
        'rdo_gating_scripts',
        'centos-opstools/opstools-ansible',
        'rdo-infra/ansible-role-logserver',
        'rdo-infra/ansible-role-rdo-base',
        'rdo-infra/ansible-role-rdo-bot',
        'rdo-infra/ansible-role-rdo-kolla-build',
        'rdo-infra/ansible-role-rdo_dashboards',
        'rdo-infra/ansible-role-rdomonitoring',
        'rdo-infra/ansible-role-weirdo-common',
        'rdo-infra/ansible-role-weirdo-kolla',
        'rdo-infra/ansible-role-weirdo-logs',
        'rdo-infra/ansible-role-weirdo-packstack',
        'rdo-infra/ansible-role-weirdo-puppet-openstack',
        'rdo-infra/rdo-infra-playbooks',
        'rdo-infra/weirdo',
        'rdo-jobs',
        'testbranching',
        'testproject',
    ],
    'gerritbot': [
        'openstack/whitebox-tempest-plugin',
        'testbranching',
        'testproject',
    ]
}


def print_header(text):
    print("#" * (len(text) + 4))
    print("# " + text + " #")
    print("#" * (len(text) + 4))


def project_in_replication(project):
    for pattern in replication_patterns:
        if pattern.match(project) or \
                        project in IGNORED_PROJECTS['replication']:
            return True

    # This is tricky - we have some logic to adhere to here.
    # We don't replicate project sources, only their -distgit repositories.
    # Additionally, we also don't replicate puppet repositories.
    # Try to detect this without having to whitelist explicitely each and every
    # project.

    # "<project>-distgit-distgit" wouldn't be in projects
    if ("%s-distgit" % project in projects) or \
            (project.startswith('puppet') and project.endswith('distgit')):
        return True
    return False


def project_in_zuul(project):
    if project in zuul_projects or \
            project in IGNORED_PROJECTS['zuul']:
        return True
    return False


def project_in_gerritbot(project):
    if project in gerritbot_projects or \
            project in IGNORED_PROJECTS['gerritbot']:
        return True
    return False

###
# Retrieve Gerrit project list
###
# Gerrit's response is pretty-printed JSON but the first line is garbage, get
# rid of it
try:
    projects = requests.get(PROJECT_LIST)
    projects = json.loads(projects.text.replace(")]}'\n", ""))
except ValueError as e:
    print_header("Error when retrieving project list from Gerrit")
    print("HTTP: %s" % projects.status_code)
    print("Content: %s" % projects.text)
    raise e

###
# Retrieve Gerrit replication.config
###
# replication.config is really just a ini-like config file with leading spaces
# for the parameters, load it properly by stripping the whitespace
with open('gerrit/replication.config') as file:
    config = file.readlines()
replication = configparser.ConfigParser()
replication.readfp(StringIO(''.join([l.lstrip() for l in config])))

# What we're really interested from the replication.config file is the projects
# field which is a pattern we want to be matching against
replication_patterns = []
for section in replication.sections():
    try:
        pattern = re.compile(replication.get(section, 'projects'))
        replication_patterns.append(pattern)
    except configparser.NoOptionError:
        pass

###
# Retrieve list of projects in Gerritbot
###
gerritbot_projects = []
with open('gerritbot/channels.yaml') as f:
    config = yaml.load(f.read())
    irc_rdo = config['rdo']['projects']
    irc_opstools = config['centos-opstools']['projects']
    for project in irc_rdo + irc_opstools:
        gerritbot_projects.append(project)

###
# Retrieve list of projects in Zuul layout
###
zuul_files = glob.glob('zuul/*.yaml')
zuul_projects = []
for file in zuul_files:
    with open(file, 'r') as f:
        config = yaml.load(f.read())
    for project in config['projects']:
        zuul_projects.append(project['name'])


error = False
errors = collections.defaultdict(lambda: [])
for project in projects:
    # Check if project is replicated
    if not project_in_replication(project):
            error = True
            errors['replication'].append(project)

    # Check if project is in gerritbot
    if not project_in_gerritbot(project):
        error = True
        errors['gerritbot'].append(project)

    # Check if project is in zuul layout
    if not project_in_zuul(project):
        error = True
        errors['zuul'].append(project)

if errors['replication']:
    print_header("Projects not in Gerrit Replication")
    for e in sorted(errors['replication']):
        print(e)

if errors['zuul']:
    print_header("Projects not in Zuul Layout")
    for e in sorted(errors['zuul']):
        print(e)

if errors['gerritbot']:
    print_header("Projects not in Gerritbot")
    for e in sorted(errors['gerritbot']):
        print(e)

sys.exit(error)
