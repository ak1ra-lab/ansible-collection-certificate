# Path to the ak1ra_lab.general collection checkout.  The collection is not
# on Galaxy yet (install it from git, see README.md), and local lint/test
# bootstrap uses this sibling checkout; override it from worktrees or other
# layouts:
#   just GENERAL_COLLECTION=/path/to/ansible-collection-general \
#     ansible-collection-install
GENERAL_COLLECTION := env_var_or_default('GENERAL_COLLECTION', '../ansible-collection-general')

# Show available recipes
default:
    @just --list --unsorted

# Run all available recipes
all: lint typecheck unit-test ansible-lint

# Sync development dependencies (may update uv.lock if pyproject.toml changed)
sync *ARGS:
    uv sync {{ARGS}} --group dev

# Lint and format collection Python code and tests
lint:
    uv run ruff check --fix .
    uv run ruff format .

# Run static type checks with mypy
typecheck:
    uv run mypy .

# Show the tox-ansible environment matrix
tox-list:
    uv run tox list --ansible

# Run one tox-ansible environment, e.g. `just tox sanity-py3.13-2.21`
tox env='sanity-py3.13-2.21':
    uv run tox -e {{env}} --ansible

# Run the unit tests in an isolated tox-ansible environment
unit-test:
    uv run tox -e unit-py3.13-2.21 --ansible

# Install the collections into the project-local path for lint, mypy and docs
# only.  Molecule installs the collection under test and its test
# requirements itself.
ansible-collection-install:
    mkdir -p .ansible/collections
    uv run ansible-galaxy collection install --force --no-deps -p .ansible/collections .
    uv run ansible-galaxy collection install --no-deps -p .ansible/collections "{{GENERAL_COLLECTION}}"

# Lint all Ansible content with ansible-lint (production profile)
ansible-lint:
    uv run ansible-lint

# Build the Galaxy artifact into dist/
build:
    uv run ansible-galaxy collection build --force --output-path dist

# Run every Molecule scenario.  Scenarios are flat and each one owns its
# containers; controller-only scenarios create none.
molecule-test:
    uv run molecule test --all

# Run one Molecule scenario, e.g. `just molecule-test-one certbot_pypi`
molecule-test-one scenario:
    uv run molecule test -s {{scenario}}

# Syntax-check every scenario's converge playbook
molecule-syntax:
    uv run molecule syntax --all

# List the Molecule scenarios
molecule-list:
    uv run molecule list

# Remove build artifacts
clean:
    rm -rf .ansible/ .molecule/ .cache/ .pytest_cache/ .ruff_cache/ dist/ site/
    find . -type f -name "*.pyc" -delete
    find . -type d -name "__pycache__" -delete
