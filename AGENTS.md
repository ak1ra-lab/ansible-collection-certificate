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
- Typecheck: **mypy** (configured in `pyproject.toml`). `ty` is not used.
- Ansible lint: `uv run ansible-lint` (production profile).
- Tests: `ansible-test sanity` and Molecule. Never add `pytest-ansible`.

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
packages (`kubernetes`).

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
and `cert_manager_render`. The current layout still uses the shared
`default` lifecycle scenario (`shared_state: true`); WP-6 replaces it with
per-scenario isolation. Do not add `MOLECULE_GLOB` to new tooling.

Molecule caches scenario state, so a changed `molecule.yml` needs
`molecule reset` (or `destroy`). After editing a role, reinstall the
collection into `.ansible/collections` before running a scenario.

## Packaging

`galaxy.yml` uses `build_ignore` (not `manifest`). Keep local state out of the
artifact: `.agents`, `.ansible`, `.venv`, `site`, `tests/output`,
`playbooks/host_vars`, `playbooks/group_vars`, `config`. `meta/runtime.yml`
must remain in the tarball; CI checks it after `ansible-galaxy collection
build`.
