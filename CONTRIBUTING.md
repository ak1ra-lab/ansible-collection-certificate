# Contributing

## Setup

Prerequisites: `uv`, a Podman daemon (rootless is enough locally; CI uses rootful),
and `go` on the controller for the `acme_dns` role's `go_build` dependency.

```shell
just sync
just ansible-collection-install
```

The collection under test depends on `ak1ra_lab.general`, which is not on
Galaxy before the `0.4.0` release. The install recipe copies it from the
sibling checkout (`GENERAL_COLLECTION`, default
`../ansible-collection-general`) into `.ansible/collections` with `--no-deps`
so lint, mypy, docs, and standalone Molecule can resolve it. This copy is a
temporary bridge until general is published; tox-ansible/ade still cannot
resolve the dependency from Galaxy.

The repository's `ansible.cfg` pins `roles_path=./roles` and
`collections_path=./.ansible/collections`; it does not read user-level or
parent paths.

## Checks

```shell
uv run ruff check --fix .
uv run ruff format .
uv run mypy .
uv run ansible-lint
uv run tox list --ansible
uv run tox -e sanity-py3.13-2.21 --ansible
uv run tox -e unit-py3.13-2.21 --ansible
ansible-galaxy collection build --output-path /tmp/collection-build
uv run python -m galaxy_importer.main \
  --git-clone-path . --output-path /tmp/collection-import --print-result
```

`ansible-test sanity` is the authoritative Python/Ansible gate and runs
through tox-ansible. `[tool.tox]`/`[tool.tox-ansible]` in `pyproject.toml`
define the ansible-core 2.19/2.20/2.21 plus weekly devel/milestone matrix;
there is no hand-maintained skip list.

### Temporary local bridge for the unpublished general collection

ADE (used by tox-ansible) resolves the `ak1ra_lab.general >=0.4.0` dependency
declared in `galaxy.yml` from Galaxy, so certificate tox-ansible environments
fail before the first general 0.4.0 release:

```text
[ERROR]: Failed to resolve the requested dependencies map. Could not satisfy
the following requirements: * ak1ra_lab.general:>=0.4.0 (direct request)
```

Until general 0.4.0 is published, validate locally with a temporary
collection-layout copy that has the general dependency removed, or run
`ansible-test` directly in a real (not symlinked) collection-layout copy:

```shell
work=$(mktemp -d)
mkdir -p "$work/ansible_collections/ak1ra_lab"
cp -a . "$work/ansible_collections/ak1ra_lab/certificate"
cp -a ../ansible-collection-general \
  "$work/ansible_collections/ak1ra_lab/general"
cd "$work/ansible_collections/ak1ra_lab/certificate"
uv run ansible-test sanity --python 3.13
uv run ansible-test units --python 3.13
```

Do not publish a modified `galaxy.yml`; the real dependency stays in place.

Python changes must pass ruff, ruff format and mypy. Ansible changes must pass
ansible-lint, `ansible-test sanity` and the relevant Molecule scenarios.

## Testing with Molecule

Molecule scenarios live flat under `extensions/molecule/<name>/`. Each
container-backed scenario owns its containers: the shared
`create.yml`/`destroy.yml` playbooks build names from the scenario name and a
checkout hash, so scenarios and parallel checkouts cannot collide. There is no
shared `default` lifecycle scenario and no `shared_state`.
`acme_dns_register_basic` and `cert_manager_render` run entirely on the
controller and create no containers.

| Scenario | Coverage |
| --- | --- |
| `acme_dns_register_basic` | per-validation-domain acme-dns registration, mapping persistence and idempotence against a fake `/register` API |
| `certbot_apt` | apt install, Pebble ACME issuance via HTTP-01 with EAB, renewal configuration, role-managed unit, per-lineage deploy hook dispatch and timer |
| `certbot_pypi` | PyPI install into the managed venv, Cloudflare plugin, credentials, hook, cli.ini, logrotate and systemd units |
| `certbot_acmedns` | per-validation-domain acme-dns auth hook selection against a fake `/update` API |
| `cert_manager_render` | ClusterIssuer/Secret rendering, per-issuer Cloudflare and HTTP-01 solvers, EAB, shared/reference-only Secrets, manifest permissions (no cluster required) |

The managed nodes are the Debian 12/13 systemd images from
[ak1ra-lab/docker-systemd](https://github.com/ak1ra-lab/docker-systemd).

```shell
just sync
just ansible-collection-install   # lint/mypy/docs only, not Molecule
just molecule-test                # every scenario
just molecule-test-one certbot_pypi
just molecule-syntax
just molecule-list
```

Molecule's dependency action installs `tests/molecule/requirements.yml`;
ansible-compat's prerun installs the collection under test and its `galaxy.yml`
dependencies. Do not pre-install the collection or test collections into
`.ansible/collections` for Molecule.

Until `ak1ra_lab.general 0.4.0` is published, the prerun resolver needs a
local copy of general. `just ansible-collection-install` installs it from the
sibling checkout (`GENERAL_COLLECTION`, default `../ansible-collection-general`)
into `.ansible/collections`; CI checks out the branch instead. Once general is
on Galaxy this bootstrap goes away.

Podman is required. Rootless Podman works for the certificate scenarios; CI
uses rootful Podman for a uniform systemd container runtime. A Docker daemon
is supported as an alternative; set `MOLECULE_CONTAINER_RUNTIME=docker` for
every molecule invocation. The controller additionally needs `go` (the
`acme_dns` role builds its binary through `ak1ra_lab.general.go_build`) and
`uv` (the `certbot_pypi` scenario composes `pyproject_install`).

Molecule caches scenario state, so a changed `molecule.yml` needs
`molecule reset` (or `destroy`).

## Changelog

`CHANGELOG.rst` is generated by `antsibull-changelog`. Add a fragment under
`changelogs/fragments/` (for example `fix-certbot-renewal.yml`) instead of
editing the generated file. The first release starts at `0.1.0`.

## Documentation

The Sphinx site is generated from the role argument specs in
`roles/<role>/meta/argument_specs.yml`; role READMEs keep narrative and
deployed-artifact details. The collection must be installed in
`.ansible/collections` first (the just recipes do that).

```shell
just docs-lint    # antsibull-docs lint-collection-docs
just docs-build   # regenerate reference pages + sphinx-build -W
just docs-serve   # http://127.0.0.1:8000
```
