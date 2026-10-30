# ak1ra_lab.certificate

Ansible collection for TLS certificate lifecycle management: acme-dns, certbot
and cert-manager. It is consumed alongside
[`ak1ra_lab.general`](https://github.com/ak1ra-lab/ansible-collection-general),
which provides the generic build and release helpers used by these roles.

Documentation: <https://ak1ra-lab.github.io/ansible-collection-certificate/>
Release notes: [CHANGELOG.rst](CHANGELOG.rst)

## Roles

| Role | Description |
| --- | --- |
| [`acme_dns`](roles/acme_dns/README.md) | Deploy an acme-dns server with the Go binary built on the controller and a systemd service. |
| [`acme_dns_register`](roles/acme_dns_register/README.md) | Register one acme-dns account per validation domain and create `_acme-challenge` CNAMEs. |
| [`certbot`](roles/certbot/README.md) | Obtain and renew certificates with certbot from apt, PyPI, or an external binary. |
| [`cert_manager`](roles/cert_manager/README.md) | Install cert-manager and declare ACME `ClusterIssuer` resources with per-issuer solvers. |

The role argument specs (`roles/<role>/meta/argument_specs.yml`) are the
canonical variable contracts, and the docs site renders them as the generated
role reference. Role READMEs keep purpose, deployed artifacts, and examples;
they do not duplicate the variable reference.

## Playbooks

This collection is a role library and does not ship runnable playbooks or
scripts. The operational certificate playbooks live in
[`ansible-playbooks-services`](https://github.com/ak1ra-lab/ansible-playbooks-services).
Use that repository for inventories and site playbooks that apply these roles.

## Requirements

- Controller: `ansible-core >= 2.19.0`; tested with ansible-core 2.19, 2.20,
  and 2.21 (plus the weekly `devel`/`milestone` builds).
- Controller Python: `>= 3.11`; tested with Python 3.11, 3.12, and 3.13.
  ansible-core 2.20 and 2.21 additionally support Python 3.12-3.14.
- Managed nodes: Debian 12 (target Python 3.11) and Debian 13 (target Python
  3.13). The certificate roles and their Molecule scenarios are tested on
  those images and use the managed node's `/usr/bin/python3`.
- Controller Python package: `kubernetes` for `cert_manager` (see
  [`requirements.txt`](requirements.txt)).
- Collections: `ak1ra_lab.general >= 0.4.0`, `community.general >= 8.0.0`,
  `kubernetes.core >= 6.0.0` (resolved from [`galaxy.yml`](galaxy.yml)).

`ak1ra_lab.certificate` depends on `ak1ra_lab.general` for `go_build`,
`pyproject_install`, and `github_releases_info`. Galaxy resolves that
dependency automatically.

## Install

Install the released collection from Ansible Galaxy:

```shell
ansible-galaxy collection install ak1ra_lab.certificate
```

Or pin it in a consumer `requirements.yml`:

```yaml
---
collections:
  - name: ak1ra_lab.certificate
    version: ">=0.1.0"
```

```shell
ansible-galaxy collection install -r requirements.yml
```

Galaxy also installs `ak1ra_lab.general >= 0.4.0`, `community.general`, and
`kubernetes.core`. The `0.1.0` release is the first Galaxy release.

See [Getting started](docs/docsite/rst/getting-started.rst) for control-node
requirements.

## Versioning and deprecation

The collection follows semantic versioning once it reaches `1.0.0`. Before
`1.0.0`, a minor release may contain a documented breaking change; patch
releases are limited to compatible fixes.

- Breaking changes are listed under **Breaking Changes / Porting Guide** in
  [CHANGELOG.rst](CHANGELOG.rst).
- Deprecated role variables and features are documented in the changelog and
  the role reference, and remain available for at least one minor release
  before removal. Before `1.0.0`, removal may happen in a minor release.
- Raising the minimum ansible-core or Python version is treated as a breaking
  change.
- The `galaxy.yml` version, the Git tag (`vX.Y.Z`), and the changelog release
  must match for every release.

Release order for the `ak1ra_lab` collections:

1. `ak1ra_lab.general 0.4.0`
2. `ak1ra_lab.certificate 0.1.0` (depends on general `>=0.4.0`)
3. `ak1ra_lab.network 0.4.0` (depends on general `>=0.4.0`)

## Communication

- Ansible Forum: use the [`ak1ra-lab` tag](https://forum.ansible.com/tag/ak1ra-lab)
  for questions and usage discussions.
- Bug reports and feature requests:
  <https://github.com/ak1ra-lab/ansible-collection-certificate/issues>
- Code of Conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), which points to
  the [Ansible Community Code of Conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html).

## Development

```shell
uv sync --group dev
uv run ansible-lint
uv run tox list --ansible
uv run tox -e sanity-py3.13-2.21 --ansible
uv run tox -e unit-py3.13-2.21 --ansible
just changelog-lint
just docs-lint
just docs-build
```

`ansible-test sanity` runs through tox-ansible for ansible-core
2.19/2.20/2.21 plus the weekly devel/milestone environments. Tox-ansible
resolves the `galaxy.yml` dependencies, including `ak1ra_lab.general`, from
Galaxy.

Molecule scenarios are flat under `extensions/molecule/`, each one owns its
containers, and the suite needs Podman (rootless locally; CI uses rootful) or
Docker. They are run separately from the lint/sanity gates. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, scenario list, and
release checklist.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
