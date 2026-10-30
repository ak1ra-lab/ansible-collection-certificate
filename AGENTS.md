# AGENTS.md

## Project type

This repository is the `ak1ra_lab.certificate` Ansible collection: a library
of reusable certificate lifecycle roles, not a consumer or a playbook project.
Operational playbooks and inventories live in the separate
`ansible-playbooks-services` repository; this collection ships no runnable
playbooks or scripts.

## Skills

Actively use the `developing-ansible` skill for Ansible work; load it before
writing or reviewing playbooks, roles, plugins, inventory, Molecule, or
collection metadata.

Prefer a user-level installation of the skill. Agents that do not have it
installed may bootstrap from
`https://raw.githubusercontent.com/ak1ra-komj/agents-skills/refs/heads/master/skills/developing-ansible/SKILL.md`;
the URL is a fallback, not the normal workflow.

## Layout

- Roles: `acme_dns`, `acme_dns_register`, `certbot`, and `cert_manager` under
  `roles/`.
- The roles depend on `ak1ra_lab.general` helpers such as `go_build`,
  `pyproject_install`, and `github_releases_info`; references to that
  collection are intentional.
- There are no collection-owned Python plugins or modules yet. Molecule
  scenarios are flat under `extensions/molecule/`; docs source is
  `docs/docsite/`.
- Role metadata uses `license: GPL-3.0-or-later` and
  `min_ansible_version: "2.19"`.

## YAML and documentation

Use `.yml` for Ansible and repository YAML files. Unavoidable exceptions:

- `galaxy.yml` already uses `.yml`.
- `changelogs/config.yaml` is hardcoded by antsibull-changelog.
- `.pre-commit-config.yaml` stays `.yaml` because pre-commit 4.7 discovers only
  that name.
- Generated or upstream filenames such as `*.proxies.yaml`, `host_vars/*.yaml`,
  `50-cloud-init.yaml`, netplan files, and downloaded manifests keep their
  existing names.

`roles/<role>/meta/argument_specs.yml` is the canonical role variable
reference. Generated role docs come from argument specs; role READMEs are
concise narrative (purpose, requirements, artifacts, examples, teardown) and
must not duplicate variable tables. Never edit generated `*_role.rst` pages by
hand.

## Tooling and validation

- Use **uv** and **just**; never `pip` or `poetry`. `just sync` installs the
  `dev` group.
- Python: **ruff** and **mypy** via `just lint` and `just typecheck`.
  `ansible-test sanity` remains the authoritative gate.
- Ansible: `just ansible-lint` (production profile) and **tox-ansible**
  (`just tox <env>`, `just unit-test`).
- Molecule: `just molecule-test` or `just molecule-test-one <scenario>`.
  Scenarios include `acme_dns_register_basic`, `certbot_apt`, `certbot_pypi`,
  `certbot_acmedns`, and `cert_manager_render`; the first and last are
  controller-only.
- Docs and changelog: `just docs-lint`, `just docs-build`, and
  `just changelog-lint`, using antsibull-docs/antsibull-changelog.
  `CHANGELOG.rst` is generated and must not be edited by hand.
- `just ansible-collection-install` is for lint, mypy, and docs only; Molecule
  installs the collection and test requirements itself. Build the artifact and
  run `galaxy-importer` before release.

## Workflow and safety

- Run `just all` plus the release-scope Molecule scenarios before commit.
- Preserve public behavior unless the task explicitly changes it; keep changes
  consistent with the existing layout and naming.
- Do not add unpublished-dependency workarounds to CI, tests, docs, or release.
- Do not edit installed copies under `.ansible/`, `.tox/`, or `.venv/`.
- Release order: `general 0.4.0`, `certificate 0.1.0`, `network 0.4.0`; the tag
  `vX.Y.Z` matches `galaxy.yml`, and publishing uses the protected workflow only.
