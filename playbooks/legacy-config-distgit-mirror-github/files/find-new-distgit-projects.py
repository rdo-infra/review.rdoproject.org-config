import ruamel.yaml as yaml
import sys


def find_distgit(filename):
    # Find new distgit projects in a SF resource file
    with open(filename) as resource:
        info = yaml.load(resource, Loader=yaml.RoundTripLoader)

    for key in info['resources']['repos']:
        if key.endswith('-distgit'):
            if key.startswith('openstack/') or key.startswith('puppet/'):
                # We only care about distgits
                print(key)


if __name__ == '__main__':
    find_distgit(sys.argv[1])
