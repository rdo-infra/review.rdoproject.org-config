#!/usr/bin/env python
# Ensures that every Gerrit project is configured in Gerrit replication,
# Zuul layout and Gerritbot.

import collections
import ConfigParser
import glob
import json
import re
import requests
import sys
import yaml
from StringIO import StringIO

GERRIT = "https://review.rdoproject.org/r/"
PROJECT_LIST = GERRIT + "/projects/"

def print_header(text):
    """
    Helper to print a header
    """
    print "#" * (len(text) + 4)
    print "# " + text + " #"
    print "#" * (len(text) + 4)


def project_in_replication(patterns, project):
    for pattern in patterns:
        if pattern.match(project):
            return True
    return False


def project_in_zuul(zuul_projects, project):
    if project in zuul_projects:
        return True
    return False


def project_in_gerritbot(gerritbot_projects, project):
    if project in gerritbot_projects:
        return True
    return False

###
# Retrieve Gerrit project list
###
# Gerrit's response is pretty-printed JSON but the first line is garbage, get
# rid of it
projects = requests.get(PROJECT_LIST)
projects = json.loads('\n'.join(projects.text.split('\n')[1:]))

###
# Retrieve Gerrit replication.config
###
# replication.config is really just a ini-like config file with leading spaces
# for the parameters, load it properly by stripping the whitespace
with open('gerrit/replication.config') as file:
    config = file.readlines()
replication = ConfigParser.ConfigParser()
replication.readfp(StringIO(''.join([l.lstrip() for l in config])))

# What we're really interested from the replication.config file is the projects
# field which is a pattern we want to be matching against
patterns = list()
for section in replication.sections():
    try:
        patterns.append(re.compile(replication.get(section, 'projects')))
    except ConfigParser.NoOptionError:
        pass

###
# Retrieve list of projects in Gerritbot
###
gerritbot_projects = list()
with open('gerritbot/channels.yaml') as f:
    config = yaml.load(f.read())
    for project in config['rdo']['projects']:
        gerritbot_projects.append(project)

###
# Retrieve list of projects in Zuul layout
###
zuul_files = glob.glob('zuul/*.yaml')
zuul_projects = list()
for file in zuul_files:
    with open(file, 'r') as f:
        config = yaml.load(f.read())
    for project in config['projects']:
        zuul_projects.append(project['name'])


error = False
errors = collections.defaultdict(lambda: list())
for project in projects:
    # Check if project is replicated
    if not project_in_replication(patterns, project):
        error = True
        errors['replication'].append(project)

    # Check if project is in gerritbot
    if not project_in_gerritbot(gerritbot_projects, project):
        error = True
        errors['gerritbot'].append(project)

    # Check if project is in zuul layout
    if not project_in_zuul(zuul_projects, project):
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

if error:
    sys.exit(1)
else:
    sys.exit(0)