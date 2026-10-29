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

Until the first Galaxy release, install the collection from Git:

.. code-block:: yaml

   ---
   collections:
     - name: git+https://github.com/ak1ra-lab/ansible-collection-certificate.git
       version: main

``ak1ra_lab.general`` must be available from Galaxy or installed from its
repository first. The collection is intended to be consumed from
``./.ansible/collections``, with the consumer repository's ``ansible.cfg``
including that path at the front of ``collections_path``.

For local development, ``just ansible-collection-install`` installs this
collection and the sibling ``../ansible-collection-general`` checkout into
``.ansible/collections``. Override the path with
``GENERAL_COLLECTION=/path/to/checkout`` when working from a worktree.

Requirements
------------

- Controller: ``ansible-core >= 2.19.0``, Python ``>= 3.11``.
- Managed nodes: Debian 12/13 (the certificate roles and their Molecule
  scenarios are tested on those images).
- Controller Python: ``kubernetes`` for ``cert_manager`` (see
  ``requirements.txt``).
- Collections: ``ak1ra_lab.general >= 0.4.0``, ``community.general >= 8.0.0``,
  ``kubernetes.core >= 6.0.0``. ``ansible-galaxy`` resolves them from
  ``galaxy.yml``.

The unpublished ``ak1ra_lab.general`` dependency blocks ADE/tox-ansible
resolution. See :doc:`contributing` for the temporary local-checkout bridge.

Next steps
----------

- :doc:`architecture` for how the roles compose.
- :doc:`playbooks` for the bundled entry points.
- :doc:`collection_index` for the generated role reference.
