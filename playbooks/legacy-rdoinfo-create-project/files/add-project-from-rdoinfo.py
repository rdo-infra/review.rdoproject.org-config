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
    with open("zuul.d/projects.yaml") as infile:
        info = yaml.load(infile, Loader=yaml.RoundTripLoader)

    data = yaml.comments.CommentedMap(
        [('project', yaml.comments.CommentedMap(
            [('name', "review.rdoproject.org/%s/%s-distgit" % (project_prefix, project_name)),
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

    with open('zuul.d/projects.yaml', 'w') as outfile:
        outfile.write(yaml.dump(info, Dumper=yaml.RoundTripDumper,
                                indent=2, block_seq_indent=0))

if __name__ == '__main__':
    add_project_resources(sys.argv[1], sys.argv[2], sys.argv[3])
