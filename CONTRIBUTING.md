# Contributing

## Setup

Prerequisites: `uv`, a rootful Podman daemon (or a rootful Docker daemon),
and `go` on the controller for the `acme_dns` role's `go_build` dependency.

```shell
uv sync --group dev
mkdir -p .ansible/collections
uv run ansible-galaxy collection install --force --no-deps -p .ansible/collections .
uv run ansible-galaxy collection install --no-deps -p .ansible/collections \
  ak1ra_lab.general community.general kubernetes.core
```

The collection under test depends on `ak1ra_lab.general`, which is not on
Galaxy before the `0.4.0` release. Install it from the sibling checkout into
the same project-local path until then (this is only for lint, docs, and
manual Molecule runs; the tox-ansible harness installs the collection
editable itself):

```shell
uv run ansible-galaxy collection install --no-deps -p .ansible/collections \
  ../ansible-collection-general
```

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

Molecule scenarios live under `extensions/molecule/` (collection-testing
layout). The `default` scenario owns the shared container lifecycle
(`shared_state: true`); the flat component scenarios reuse the same
containers and each run prepare, converge, idempotence, verify, the scenario
teardown, and a teardown verification.

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
# First run only: install the collection under test and its dependencies.
# --no-deps avoids resolving the not-yet-published ak1ra_lab.general 0.4.0
# from Galaxy; install general from its checkout as shown above.
uv run ansible-galaxy collection install --force --no-deps -p .ansible/collections .
uv run ansible-galaxy collection install --no-deps -p .ansible/collections \
  community.general kubernetes.core containers.podman community.docker

# The shared lifecycle scenario and the flat component scenarios.
uv run molecule test --all
uv run molecule test -s certbot_pypi
uv run molecule list
```

Podman is required. The CI runs it rootful because every container runs
privileged and systemd needs the capabilities. A rootful Docker daemon is
supported as an alternative; set `MOLECULE_CONTAINER_RUNTIME=docker` for every
molecule invocation. The controller additionally needs `go` (the `acme_dns`
role builds its binary through `ak1ra_lab.general.go_build`) and `uv` (the
`certbot_pypi` scenario composes `pyproject_install`).

When invoking `molecule` directly, reinstall the collection after editing a
role or the scenario tests the previously installed copy. Molecule caches
scenario state, so a changed `molecule.yml` needs `molecule reset` (or
`destroy`).

## Changelog

`CHANGELOG.rst` is generated by `antsibull-changelog`. Add a fragment under
`changelogs/fragments/` (for example `fix-certbot-renewal.yml`) instead of
editing the generated file. The first release starts at `0.1.0`.
