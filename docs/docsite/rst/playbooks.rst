.. _ansible_collections.ak1ra_lab.certificate.docsite.playbooks:

Playbooks
=========

The collection ships thin playbook entry points under ``playbooks/``. They set
privileges, gather facts, and apply roles; the variable contracts stay in the
role argument specs.

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Playbook
     - Behavior
   * - ``acme-dns.yaml``
     - Deploys the acme-dns server role.
   * - ``certbot.yaml``
     - Obtains certificates with certbot. DNS-01 and HTTP-01 are selected
       through the ``certbot_*`` contract.

The playbooks accept ``playbook_hosts`` as an inventory override, following the
same pattern as the other ``ak1ra_lab`` collections. The playbook files are the
source of truth for the exact variables and task order.

Examples
--------

.. code-block:: shell

   ansible-playbook playbooks/acme-dns.yaml -e playbook_hosts=acme-dns
   ansible-playbook playbooks/certbot.yaml -e playbook_hosts=web

Certificate consumption is intentionally not bundled. A web server role or
site playbook installs the certificate paths and reloads its service from a
deploy hook.
