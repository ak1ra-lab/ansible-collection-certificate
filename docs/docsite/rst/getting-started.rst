.. _ansible_collections.ak1ra_lab.certificate.docsite.getting-started:

Getting started
===============

Install the collection
----------------------

Create a ``requirements.yaml`` in the consuming repository:

.. code-block:: yaml

   ---
   collections:
     - name: ak1ra_lab.certificate
       version: ">=0.1.0"

Install into the project-local collections path:

.. code-block:: shell

   ansible-galaxy collection install -r requirements.yaml -p ./.ansible/collections

``0.1.0`` is the first Galaxy release. Galaxy resolves
``ak1ra_lab.general >= 0.4.0``, ``community.general``, and
``kubernetes.core`` from ``galaxy.yml`` automatically.

For local development, ``just ansible-collection-install`` installs this
collection and its Galaxy dependencies into ``.ansible/collections`` for lint,
mypy, and docs.

Requirements
------------

- Controller: ``ansible-core >= 2.19.0``; tested with 2.19, 2.20, and 2.21
  plus the weekly ``devel``/``milestone`` builds.
- Controller Python ``>= 3.11``; tested with 3.11, 3.12, and 3.13.
  ansible-core 2.20 and 2.21 additionally support Python 3.12-3.14.
- Managed nodes: Debian 12 (target Python 3.11) and Debian 13 (target Python
  3.13). The certificate roles and their Molecule scenarios are tested on
  those images and use the managed node's ``/usr/bin/python3``.
- Controller Python: ``kubernetes`` for ``cert_manager`` (see
  ``requirements.txt``).
- Collections: ``ak1ra_lab.general >= 0.4.0``, ``community.general >= 8.0.0``,
  ``kubernetes.core >= 6.0.0``. ``ansible-galaxy`` resolves them from
  ``galaxy.yml``.

Release order
-------------

The ``ak1ra_lab`` collections are released in dependency order:
``ak1ra_lab.general 0.4.0``, ``ak1ra_lab.certificate 0.1.0``, then
``ak1ra_lab.network 0.4.0``. Certificate depends on general ``>=0.4.0``; it
does not depend on network.

Next steps
----------

- :doc:`architecture` for how the roles compose.
- :doc:`playbooks` for the operational playbooks in
  ``ansible-playbooks-services``.
- :doc:`collection_index` for the generated role reference.
