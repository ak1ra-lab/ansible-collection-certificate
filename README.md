# ak1ra_lab.certificate

Ansible collection for TLS certificate lifecycle management: acme-dns, certbot
and cert-manager. It is consumed alongside
[`ak1ra_lab.general`](https://github.com/ak1ra-lab/ansible-collection-general),
which provides the generic build and release helpers used by these roles.

Documentation: <https://ak1ra-lab.github.io/ansible-collection-certificate/>

## Roles

| Role | Description |
| --- | --- |
| [`acme_dns`](roles/acme_dns/README.md) | Deploy an acme-dns server with the Go binary built on the controller and a systemd service. |
| [`acme_dns_register`](roles/acme_dns_register/README.md) | Register one acme-dns account per validation domain and create `_acme-challenge` CNAMEs. |
| [`certbot`](roles/certbot/README.md) | Obtain and renew certificates with certbot from apt, PyPI, or an external binary. |
| [`cert_manager`](roles/cert_manager/README.md) | Install cert-manager and declare ACME `ClusterIssuer` resources with per-issuer solvers. |

The role READMEs are the canonical variable contracts. The docs site renders
them as the role reference.

## Requirements

- Controller: `ansible-core >= 2.19.0`, Python `>= 3.11`.
- Managed nodes: Debian 12/13 (the certificate roles and their Molecule
  scenarios are tested on those images).
- Controller Python: `kubernetes` for `cert_manager` (see
  [`requirements.txt`](requirements.txt)).
- Collections: `ak1ra_lab.general >= 0.4.0`, `community.general >= 8.0.0`,
  `kubernetes.core >= 6.0.0`. `ansible-galaxy` resolves them from
  [`galaxy.yml`](galaxy.yml).

## Install

Create a `requirements.yaml` in the consuming repository:

```yaml
---
collections:
  - name: ak1ra_lab.certificate
    version: ">=0.1.0"
```

Install into the project-local collections path:

```shell
ansible-galaxy collection install -r requirements.yaml -p ./.ansible/collections
```

Until the first Galaxy release, install the collection from Git:

```yaml
---
collections:
  - name: git+https://github.com/ak1ra-lab/ansible-collection-certificate.git
    version: main
```

`ak1ra_lab.general` must be available from Galaxy or installed from its
repository first. This collection is intended to be consumed from
`./.ansible/collections`, with the consumer repository's `ansible.cfg`
including that path at the front of `collections_path`.

## Development

```shell
uv sync --group dev
uv run ansible-lint
uv run tox list --ansible
uv run tox -e sanity-py3.13-2.21 --ansible
uv run tox -e unit-py3.13-2.21 --ansible
```

`ansible-test sanity` runs through tox-ansible for ansible-core
2.19/2.20/2.21 plus the weekly devel/milestone environments. Until
`ak1ra_lab.general 0.4.0` is published, ADE cannot resolve the dependency and
the temporary local-checkout bridge in
[CONTRIBUTING.md](CONTRIBUTING.md#temporary-local-bridge-for-the-unpublished-general-collection)
applies.

Molecule scenarios are flat under `extensions/molecule/`, each one owns its
containers, and the suite needs Podman (rootless locally; CI uses rootful) or
Docker. They are run separately from the lint/sanity gates. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow and scenario list.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
