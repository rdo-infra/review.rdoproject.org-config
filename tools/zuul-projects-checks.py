#!/usr/bin/env python

# Copyright 2017 SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys

import yaml


projects_yaml = 'zuul.d/projects.yaml'
projects = yaml.safe_load(open(projects_yaml))


def check_system_templates():
    """Check that each repo has a system-required template."""

    errors = False
    print("\nChecking for usage of system-required")
    print("=====================================")
    for entry in projects:
        project = entry['project']
        # TODO(pabelanger): Skip this as it only sets up default-branch
        if project['name'] == '^review.rdoproject.org/openstack/.*-distgit':
            continue
        try:
            correct = False
            for template in project['templates']:
                if template == 'system-required':
                    correct = True
            if not correct:
                raise
        except:
            print("  ERROR: Project %s has no system-required template" %
                  project['name'])
            errors = True

    if not errors:
        print("... all fine.")
    return errors


def check_projects_sorted():
    """Check that the projects are in alphabetical order per section."""

    print("\nChecking project list for alphabetical order")
    print("============================================")

    errors = False
    last = ""
    for entry in projects:
        current = entry['project']['name']
        if (last > current):
            print("  ERROR: Wrong alphabetical order: %(last)s, %(current)s" %
                  {"last": last, "current": current})
            errors = True
        last = current

    if not errors:
        print("... all fine.")
    return errors


def check_all():

    errors = check_system_templates()
    errors = check_projects_sorted() or errors

    if errors:
        print("\nFound errors in zuul.d/projects.yaml!\n")
    else:
        print("\nNo errors found in zuul.d/projects.yaml!\n")
    return errors


if __name__ == "__main__":
    sys.exit(check_all())
