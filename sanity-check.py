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
        'testbranching',
        'testproject'
    ],
    'gerritbot': [
        'testbranching',
        'testproject',
        'centos-opstools/opstools-doc',
        'centos-opstools/centos-release-opstools',
        'centos-opstools/opstools-ansible',
        'centos-opstools/osops-tools-monitoring-oschecks',
        'centos-opstools/rubygem-cool.io',
        'centos-opstools/rubygem-diff-lcs',
        'centos-opstools/rubygem-fluent-plugin-secure-forward',
        'centos-opstools/rubygem-fluent-plugin-grok-parser',
        'centos-opstools/rubygem-http_parser.rb',
        'centos-opstools/rubygem-msgpack',
        'centos-opstools/rubygem-minitest',
        'centos-opstools/rubygem-oj',
        'centos-opstools/rubygem-power_assert',
        'centos-opstools/rubygem-proxifier',
        'centos-opstools/rubygem-resolve-hostname',
        'centos-opstools/rubygem-rr',
        'centos-opstools/rubygem-rspec',
        'centos-opstools/rubygem-rspec-core',
        'centos-opstools/rubygem-rspec-expectations',
        'centos-opstools/rubygem-rspec-support',
        'centos-opstools/rubygem-rspec-mocks',
        'centos-opstools/rubygem-session',
        'centos-opstools/rubygem-string-scrub',
        'centos-opstools/rubygem-test-unit',
        'centos-opstools/rubygem-test-unit-rr',
        'centos-opstools/rubygem-yajl-ruby',
        'centos-opstools/kibana',
        'centos-opstools/rubygem-builder',
        'centos-opstools/rubygem-introspection',
        'centos-opstools/skydive',
        'centos-opstools/collectd',
        'centos-opstools/fluentd',
        'centos-opstools/python-fluent-logger',
        'centos-opstools/rubygem-fluent-plugin-collectd-nest'
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
projects = requests.get(PROJECT_LIST)
projects = json.loads(projects.text.replace(")]}'\n", ""))

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
    for project in config['rdo']['projects']:
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
