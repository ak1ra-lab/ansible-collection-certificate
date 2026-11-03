===============================================
ak1ra\_lab.certificate Collection Release Notes
===============================================

.. contents:: Topics

v0.1.0
======

Release Summary
---------------

Initial Galaxy release of the certificate lifecycle collection. It contains
the acme-dns, certbot and cert-manager roles migrated with history from
``ak1ra_lab.general``, their Molecule scenarios, playbooks and role
documentation.

The collection depends on ``ak1ra_lab.general >= 0.4.0``.

Major Changes
-------------

- New collection with the ``acme_dns``, ``acme_dns_register``, ``certbot`` and ``cert_manager`` roles, migrated with Git history from ``ak1ra_lab.general``. The certificate FQCNs are now ``ak1ra_lab.certificate.*``.

Minor Changes
-------------

- A local-only ``just collections-install-local`` overlay installs the unpublished sibling ``ak1ra_lab.general`` checkout for lint, mypy, docs and Molecule. tox-ansible and CI continue to resolve the published general from Galaxy.
- Added a protected release workflow that builds, imports and publishes the collection from the ``vX.Y.Z`` GitHub release tag matching ``galaxy.yml``.
- Added role argument specs and migrated the documentation site to Sphinx and antsibull-docs. Role reference pages are generated from ``meta/argument_specs.yml``; the role READMEs keep narrative and deployed artifact details.
- Added the certificate Molecule scenarios as flat, isolated scenarios (``acme_dns_register_basic``, ``certbot_apt``, ``certbot_pypi``, ``certbot_acmedns`` and ``cert_manager_render``), with controller-only coverage where no container is needed.
- Added the tox-ansible matrix for ansible-core 2.19/2.20/2.21 and the weekly devel/milestone environments, plus mypy alongside ruff and ansible-lint.
- CI and the release workflow now run ``galaxy-importer`` against the tarball produced by the build step instead of rebuilding the collection, so the artifact that is tested is the artifact that is published.
- Isolated the Molecule scenarios so each one owns its containers and the shared lifecycle and ``shared_state`` are gone.
- Migrated release notes to antsibull-changelog. ``CHANGELOG.rst`` is the canonical generated changelog.
- Moved the ``acme-dns.yaml`` and ``certbot.yaml`` playbooks and the role documentation to this collection. Certificate issuance is no longer orchestrated from ``ak1ra_lab.network.mihomo_server``; consumer playbooks compose the two collections explicitly.
- Moved the operational certificate playbooks to the separate ``ansible-playbooks-services`` repository. The collection remains the certificate role library and ships no playbooks or scripts.
- Moved the shared test-only collection requirements from ``tests/molecule/requirements.yml`` to ``tests/requirements.yml`` so ansible-lint and every tox-ansible test environment use the same file.
- Prepared the collection for Galaxy with GPL-3.0-or-later licensing, ``meta/runtime.yml`` (ansible-core >= 2.19.0), ``requirements.txt``/``meta/execution-environment.yml``, a ``build_ignore`` artifact and a build-import CI gate that checks the tarball and runs ``galaxy-importer``.
- Removed the hard-coded collection version, license and dependency assertions from CI. The release workflow already checks the release tag against ``galaxy.yml``, and ``galaxy-importer`` validates the metadata.
- Role READMEs now point to the generated variable reference instead of duplicating the ``meta/argument_specs.yml`` tables, and keep only purpose, deployed artifacts, operational notes, and examples.
- The ``just ansible-collection-install`` recipe now also installs the shared test-only collections, and the lint and Molecule recipes keep Ansible data under the repository's ``.ansible/`` directory.
- The build step now asserts that exactly one collection artifact exists and exposes its path to the importer, smoke test and publish steps.
- The collection metadata unit test no longer pins the current release version; it only checks the semantic version format.
- The collection, its roles and its Python sources are licensed under GPL-3.0-or-later. ``galaxy.yml`` and the role metadata declare that license.

Bugfixes
--------

- Excluded ``AGENTS.md``, ``justfile`` and the generated ``dist`` directory from the Galaxy artifact.
- Fixed the clean-install smoke test to look up the ``certbot`` role directly instead of matching the YAML output of ``ansible-doc --list``.
- Removed the unused ``distlib`` development dependency. It is only required by the legacy ``manifest`` key in ``galaxy.yml``, which this collection does not use.
