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
    with open("zuul/projects.yaml") as infile:
        info = yaml.load(infile, Loader=yaml.RoundTripLoader)

    data = yaml.comments.CommentedMap([('name', "%s/%s-distgit" %
                                        (project_prefix, project_name)),
                                       ('template',
                                        [yaml.comments.CommentedMap(
                                            [('name',
                                              'package-distgit-check-jobs')])])
                                       ])
    data['template'][0].ca.items['name'] = [None, None,
                                            yaml.tokens.CommentToken(
                                                '\n\n',
                                                yaml.error.CommentMark(0),
                                                None), None]
    if data not in info['projects']:
        info['projects'].append(data)
    else:
        print("Zuul config already includes %s/%s-distgit" %
              (project_prefix, project_name))

    data = yaml.comments.CommentedMap([('name', "%s/%s" %
                                        (project_prefix, project_name)),
                                       ('template',
                                        [yaml.comments.CommentedMap(
                                            [('name', 'package-check-jobs')])])
                                       ])

    data['template'][0].ca.items['name'] = [None, None,
                                            yaml.tokens.CommentToken(
                                                '\n\n',
                                                yaml.error.CommentMark(0),
                                                None), None]
    if data not in info['projects']:
        info['projects'].append(data)
    else:
        print("Zuul config already includes %s/%s" %
              (project_prefix, project_name))

    info['projects'].sort()

    with open('zuul/projects.yaml', 'w') as outfile:
        outfile.write(yaml.dump(info, Dumper=yaml.RoundTripDumper,
                                indent=4, block_seq_indent=2))

if __name__ == '__main__':
    add_project_resources(sys.argv[1], sys.argv[2], sys.argv[3])
