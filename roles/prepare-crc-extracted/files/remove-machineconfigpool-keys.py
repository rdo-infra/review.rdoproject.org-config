#!/usr/bin/env python3

import yaml
import sys

# Usage: remove-keys.py machineconfigpool/render-master.yaml new-master.yaml
# NOTE: by adding '/etc/node-sizing-enabled.env' or /etc/node-sizing.env,
# your host will reboot after a while, when machineconfig operator will
# "catch" the difference. Later the kubelet will have troubles to start, due
# the config file is "generated" via script before kubelet systemd service
# starts.
content_to_remove = ['/etc/containers/registries.conf',
                     '/etc/containers/policy.json']


def read_yaml(yaml_path):
    with open(yaml_path) as f:
        return yaml.safe_load(f)


def write_yaml(yaml_path, yaml_content):
    with open(yaml_path, 'w') as f:
        yaml.safe_dump(yaml_content, f)


def remove_metadata_version(yaml_content):
    if 'resourceVersion' in yaml_content.get('metadata'):
        del yaml_content['metadata']['resourceVersion']
    if 'uid' in yaml_content.get('metadata'):
        del yaml_content['metadata']['uid']
    return yaml_content


def remove_keys(yaml_content):
    new_files = []
    if yaml_content.get('spec').get('config').get('storage').get('files'):
        for file in yaml_content['spec']['config']['storage']['files']:
            if 'path' in file and file['path'] not in content_to_remove:
                new_files.append(file)
        yaml_content['spec']['config']['storage']['files'] = new_files
        yaml_content = remove_metadata_version(yaml_content)
        return yaml_content
    else:
        print("File does not contain valid machineconfigpool manifest")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide more arguments, like:")
        print("remove-keys.py machineconfigpool/master.yaml new-master.yaml")
        sys.exit(1)

    yaml_path = sys.argv[1]
    yaml_content = read_yaml(yaml_path)
    changed_yaml = remove_keys(yaml_content)
    write_yaml(sys.argv[2], changed_yaml)
