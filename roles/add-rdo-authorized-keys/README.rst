Install the RDO team SSH public keys

This role installs the shared RDO team public keys (defaults/main.yaml)
into authorized_keys on all hosts, so CI nodes can be accessed for
debugging or post-mortem analysis (e.g. zuul autohold).

The key list in defaults/public_keys can be overridden per job.
