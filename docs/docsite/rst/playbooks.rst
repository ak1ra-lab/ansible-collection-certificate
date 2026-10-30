.. _ansible_collections.ak1ra_lab.certificate.docsite.playbooks:

Playbooks
=========

``ak1ra_lab.certificate`` is a role library. It ships the ``acme_dns``,
``acme_dns_register``, ``certbot``, and ``cert_manager`` roles, but no runnable
playbooks or scripts.

The role argument specs in ``roles/<role>/meta/argument_specs.yml`` are the
canonical variable reference, and :doc:`collection_index` renders them as the
generated role reference. Role READMEs keep purpose, deployed artifacts, and
examples; they do not duplicate the variable tables.

The operational certificate playbooks live in the separate
`ansible-playbooks-services <https://github.com/ak1ra-lab/ansible-playbooks-services>`_
repository. Use that repository for inventories, site playbooks, and the
playbook entry points that apply these roles.

Certificate consumption remains intentionally not bundled. A web server role or
site playbook installs the certificate paths and reloads its service from a
deploy hook.
