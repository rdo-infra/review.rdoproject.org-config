import jinja2
import ruamel.yaml as yaml
import sys


def add_project_resources(prefix, name, maintainers):
    project_prefix = prefix
    project_name = name
    project_maintainers = maintainers.split('\n')

    jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(
                                    ['/tmp/']))
    jinja_template = jinja_env.get_template("resource.j2")
    content = jinja_template.render(project_maintainers=project_maintainers,
                                    project_prefix=project_prefix,
                                    project_name=project_name)
    with open("resources/%s-%s.yaml" % (project_prefix, project_name),
              'w') as fp:
        fp.write(content)

    # Add project to gerritbot configuration
    with open("gerritbot/channels.yaml") as gerritbot:
        info = yaml.load(gerritbot, Loader=yaml.RoundTripLoader)

    if prefix != 'deps':
        newkey = "%s/%s-distgit" % (project_prefix, project_name)
        if newkey not in info['rdo']['projects']:
            info['rdo']['projects'].append(newkey)
        else:
            print("Key %s already in gerritbot" % newkey)

    newkey = "%s/%s" % (project_prefix, project_name)
    if newkey not in info['rdo']['projects']:
        info['rdo']['projects'].append(newkey)
    else:
        print("Key %s already in gerritbot" % newkey)

    info['rdo']['projects'].sort()
    with open('gerritbot/channels.yaml', 'w') as outfile:
        outfile.write(yaml.dump(info, Dumper=yaml.RoundTripDumper,
                                indent=4, block_seq_indent=2))

    # And also to the Zuul configuration

    yml = yaml.YAML()
    yml.indent(mapping=2, sequence=4, offset=2)

    with open("zuul.d/projects.yaml") as infile:
        info = yml.load(infile)

    # The specific -distgit repo is only created for RDO Trunk packages,
    # not deps
    if prefix != 'deps':
        data = yaml.comments.CommentedMap(
            [('project', yaml.comments.CommentedMap(
                [('name', "review.rdoproject.org/%s/%s-distgit" % (project_prefix, project_name)),
                 ('default-branch', 'rpm-master'),
                 ('templates', yaml.comments.CommentedSeq(['package-distgit-check-jobs', 'system-required']))])
            )])

        data['project']['templates'].ca.items[1] = [
             yaml.tokens.CommentToken('\n\n', yaml.error.CommentMark(0), None), None, None, None]

        if data not in info:
            info.append(data)
        else:
            print("Zuul config already includes %s/%s-distgit" %
                  (project_prefix, project_name))

    if prefix != 'deps':
        data = yaml.comments.CommentedMap(
            [('project', yaml.comments.CommentedMap(
                [('name', "review.rdoproject.org/%s/%s" % (project_prefix, project_name)),
                 ('templates', yaml.comments.CommentedSeq(['package-check-jobs', 'system-required']))])
            )])
    else:
        data = yaml.comments.CommentedMap(
            [('project', yaml.comments.CommentedMap(
                [('name', "review.rdoproject.org/%s/%s" % (project_prefix, project_name)),
                 ('templates', yaml.comments.CommentedSeq(['deps-distgit-check-jobs', 'system-required']))])
            )])

    data['project']['templates'].ca.items[1] = [
         yaml.tokens.CommentToken('\n\n', yaml.error.CommentMark(0), None), None, None, None]

    if data not in info:
        info.append(data)
    else:
        print("Zuul config already includes %s/%s" %
              (project_prefix, project_name))

    info = sorted(info, key=lambda i: i['project']['name'])
    yml.dump(info, open('zuul.d/projects.yaml', 'w'))

    # Strip the extra 2 spaces that ruamel.yaml appends because we told it
    # to indent an extra 2 spaces. Because the top level entry is a list it
    # applies that indentation at the top. It doesn't indent the comment lines
    # extra though, so don't do them.
    with open('zuul.d/projects.yaml', 'r') as fp:
        content = fp.readlines()
    with open('zuul.d/projects.yaml', 'w') as fp:
        for line in content:
            if '#' in line:
                fp.write(line)
            elif len(line) < 2:
                fp.write(line)
            else:
                fp.write(line[2:])


def add_project_package(prefix, name):
    # Add the project to the rdo.yaml resource, so it can be indexed
    # by RepoXplorer
    with open('resources/rdo.yaml') as fp:
        resource =  yaml.load(fp, Loader=yaml.RoundTripLoader, preserve_quotes=True)

    project = "%s/%s-distgit" % (prefix, name)
    data = yaml.comments.CommentedMap(
        [(project, yaml.comments.CommentedMap([
            ('zuul/include', []),
            ('repoxplorer/branches', ["rpm-master"]),
        ]))])
    if data not in resource['resources']['projects']['RDO']['source-repositories']:
        resource['resources']['projects']['RDO']['source-repositories'].append(data)
    else:
        print("Key %s is already in" % project)

    resource['resources']['projects']['RDO']['source-repositories'] = sorted(
        resource['resources']['projects']['RDO']['source-repositories'], key=lambda i: sorted(i.keys()))

    with open('resources/rdo.yaml', 'w') as fp:
        fp.write(yaml.dump(resource,
                           Dumper=yaml.RoundTripDumper,
                           indent=2,
                           block_seq_indent=0))

if __name__ == '__main__':
    add_project_resources(sys.argv[1], sys.argv[2], sys.argv[3])
    if sys.argv[1] != 'deps':
        add_project_package(sys.argv[1], sys.argv[2])
