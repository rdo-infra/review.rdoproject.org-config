import jinja2
import ruamel.yaml as yaml
import sys


def add_project_resources(prefix, name, maintainers, deps_current_release):
    project_prefix = prefix
    project_name = name
    project_maintainers = maintainers.split('\n')
    release = deps_current_release

    jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(
                                    ['/tmp/']))
    jinja_template = jinja_env.get_template("resource.j2")
    content = jinja_template.render(project_maintainers=project_maintainers,
                                    project_prefix=project_prefix,
                                    project_name=project_name,
                                    release=release)
    with open("resources/%s-%s.yaml" % (project_prefix, project_name),
              'w') as fp:
        fp.write(content)

    # Add project to gerritbot configuration
    with open("gerritbot/channels.yaml") as gerritbot:
        yml_gerritbot = yaml.YAML()
        yml_gerritbot.indent(mapping=4, sequence=4, offset=2)
        info = yml_gerritbot.load(gerritbot)

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
    yml_gerritbot.dump(info, open('gerritbot/channels.yaml', 'w'))

    # And also to the Zuul configuration, but only for distgits
    # The specific -distgit repo is only created for RDO Trunk packages,
    # not deps
    if prefix != 'deps':
        yml = yaml.YAML()
        yml.indent(mapping=2, sequence=4, offset=2)
        yml.preserve_quotes = True
        yml.width = sys.maxsize

        with open("zuul.d/projects.yaml") as infile:
            info = yml.load(infile)

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

        data = yaml.comments.CommentedMap(
            [('project', yaml.comments.CommentedMap(
                [('name', "review.rdoproject.org/%s/%s" % (project_prefix, project_name)),
                 ('templates', yaml.comments.CommentedSeq(['package-check-jobs', 'system-required']))])
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


def add_project_package(prefix, name, deps_current_release):
    # Add the project to the rdo.yaml resource, so it can be indexed
    # by RepoXplorer

    release = deps_current_release

    with open('resources/rdo.yaml') as fp:
        yml_rdo = yaml.YAML(typ='rt')
        yml_rdo.indent(mapping=2, sequence=2)
        yml_rdo.preserve_quotes = True
        resource = yml_rdo.load(fp)

    if prefix != 'deps':
        project = "%s/%s-distgit" % (prefix, name)
        data = yaml.comments.CommentedMap(
            [(project, yaml.comments.CommentedMap([
                ('zuul/include', []),
                ('repoxplorer/branches', ["rpm-master"]),
                ('default-branch', 'rpm-master'),
            ]))])
    else:
        project = "%s/%s" % (prefix, name)
        data = yaml.comments.CommentedMap(
            [(project, yaml.comments.CommentedMap([
                ('zuul/include', []),
                ('repoxplorer/branches', ["c9s-%s-rdo" % release]),
                ('default-branch', 'c9s-%s-rdo' % release),
            ]))])

    if data not in resource['resources']['projects']['RDO']['source-repositories']:
        resource['resources']['projects']['RDO']['source-repositories'].append(data)
    else:
        print("Key %s is already in" % project)

    resource['resources']['projects']['RDO']['source-repositories'] = sorted(
        resource['resources']['projects']['RDO']['source-repositories'], key=lambda i: sorted(i.keys()))

    yml_rdo.dump(resource, open('resources/rdo.yaml', 'w'))


if __name__ == '__main__':
    add_project_resources(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
    add_project_package(sys.argv[1], sys.argv[2], sys.argv[4])
