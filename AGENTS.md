# AGENTS.md

This repo **is** the `ak1ra_lab.certificate` Ansible collection (`galaxy.yml`
namespace/name), not a consumer of it. Content: reusable certificate lifecycle
roles under `roles/` (`acme_dns`, `acme_dns_register`, `certbot`,
`cert_manager`). There are no collection-owned Python plugins or modules yet;
the roles delegate generic build helpers to `ak1ra_lab.general`
(`go_build`, `pyproject_install`, `github_releases_info`).
See `README.md` for the consume/deploy workflow and `CONTRIBUTING.md` for the
human contributor workflow.

## Tooling - use these, not the defaults

- Env/deps: **uv** (`uv sync --group dev`). Never `pip`/`poetry`.
- Lint+format: **ruff** (`uv run ruff check --fix .` and
  `uv run ruff format .`). Never `black`/`isort`/`flake8`.
- Typecheck: **mypy** with the pragmatic config in `pyproject.toml`.
  `ansible-test sanity` remains the authoritative gate; `ty` is not used.
- Ansible lint: `uv run ansible-lint` (production profile).
- Tests: **tox-ansible** (`uv run tox list --ansible`, then
  `uv run tox -e sanity-py3.13-2.21 --ansible` or
  `unit-py3.13-2.21`). Molecule stays separate. Never add `pytest-ansible`.

## Ansible layout

`ansible.cfg` pins `roles_path=./roles` and
`collections_path=./.ansible/collections` and does not reach user-level or
parent paths. The certificate roles reference `ak1ra_lab.general` helpers, so
install both collections into the project-local path before linting or
running playbooks:

```shell
mkdir -p .ansible/collections
uv run ansible-galaxy collection install --force --no-deps -p .ansible/collections .
uv run ansible-galaxy collection install --no-deps -p .ansible/collections ak1ra_lab.general community.general kubernetes.core
```

`--no-deps` keeps the local checkout from resolving the not-yet-published
`ak1ra_lab.general >=0.4.0` dependency from Galaxy; install the general
collection separately from its checkout until that release exists.

`requirements.yml` lists the collections needed by the roles and the Molecule
container lifecycle. `requirements.txt` lists the controller-side Python
packages (`kubernetes`); `meta/execution-environment.yml` feeds both to
ansible-builder. `tests/molecule/requirements.yml` holds only the additional
test collections and is installed by tox-ansible/ade.

Tox-ansible cannot resolve the unpublished general dependency through ADE.
The temporary local bridge is documented in `CONTRIBUTING.md`: use a real
collection-layout copy and run `ansible-test` directly, or a temporary copy
with the dependency removed. Never publish or commit that modification.

## Role contracts

- Role variables use the `<role>_*` prefix; see each
  `roles/<role>/README.md`.
- Migrated roles keep their behavior; do not rewrite role internals during
  packaging or namespace changes.
- FQCNs inside this repository must be `ak1ra_lab.certificate.<role>` for the
  certificate roles. References to `ak1ra_lab.general.go_build`,
  `ak1ra_lab.general.pyproject_install` and
  `ak1ra_lab.general.github_releases_info` are intentional.
- Role metadata uses `license: GPL-3.0-or-later` and
  `min_ansible_version: "2.19"`.

## Testing (Molecule)

Scenarios are flat under `extensions/molecule/`:
`acme_dns_register_basic`, `certbot_apt`, `certbot_pypi`, `certbot_acmedns`,
and `cert_manager_render`. Each container-backed scenario owns its containers
through the shared `create.yml`/`destroy.yml` playbooks; container names
include the scenario name and a checkout hash. `acme_dns_register_basic` and
`cert_manager_render` are controller-only and create none. There is no shared
`default` lifecycle scenario, no `shared_state`, and no `MOLECULE_GLOB`.

Molecule's dependency action installs `tests/molecule/requirements.yml` and
ansible-compat's prerun installs the collection under test. Do not pre-install
the test collections or the collection under test for Molecule. The
`just ansible-collection-install` recipe remains for lint/mypy/docs and copies
the unpublished general checkout as a temporary resolver bridge.

Molecule caches scenario state, so a changed `molecule.yml` needs
`molecule reset` (or `destroy`).

## Packaging

`galaxy.yml` uses `build_ignore` (not `manifest`). Keep local state out of the
artifact: `.agents`, `.ansible`, `.venv`, `site`, `tests/output`,
`playbooks/host_vars`, `playbooks/group_vars`, `config`, plus repository-only
tooling (`.github`, `.pre-commit-config.yaml`, `ansible.cfg`, `pyproject.toml`,
`ruff.toml`, `importer_result.json`). `requirements.yml` stays because
`meta/execution-environment.yml` references it. `meta/runtime.yml`,
`README.md`, `LICENSE`, and `CHANGELOG.rst` must remain in the tarball; CI
checks them after `ansible-galaxy collection build` and runs
`galaxy-importer`.
