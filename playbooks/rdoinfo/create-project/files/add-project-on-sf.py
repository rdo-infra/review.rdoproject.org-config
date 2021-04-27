import ruamel.yaml as yaml
import sys


def add_project_resources_on_sf(prefix, name):
    yml = yaml.YAML()
    yml.explicit_start = True
    yml.indent(mapping=2, sequence=2, offset=0)

    # Add project to sf.io configuration
    with open("zuul/rdo.yaml") as rdo:
        info = yml.load(rdo)

    leaf = info[0]['tenant']['source']['rdoproject.org']['untrusted-projects'][-1]['projects']

    # For RDO dependencies, we only have one repo
    if prefix != 'deps':
        newkey = "%s/%s-distgit" % (prefix, name)
        if newkey not in leaf:
            leaf.append(newkey)
        else:
            print("Key %s already in zuul/rdo.yaml" % newkey)

    newkey = "%s/%s" % (prefix, name)
    if newkey not in leaf:
        leaf.append(newkey)
    else:
        print("Key %s already in zuul/rdo.yaml" % newkey)

    leaf.sort()
    yml.dump(info, open('zuul/rdo.yaml', 'w'))


if __name__ == '__main__':
    add_project_resources_on_sf(sys.argv[1], sys.argv[2])
