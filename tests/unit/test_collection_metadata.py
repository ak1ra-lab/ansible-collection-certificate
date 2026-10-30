# Copyright: (c) 2026, ak1ra <ak1ra.komj@gmail.com>
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

"""Packaging contract tests for the certificate collection.

The collection has no Python plugins yet, but the Galaxy metadata and the
runtime requirement are part of the public contract and are easy to break
during a release. These tests run in the standard tox-ansible unit env.
"""

from __future__ import annotations

from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]


def load_yaml(path: str) -> dict:
    return yaml.safe_load((REPO_ROOT / path).read_text(encoding="utf-8"))


def test_galaxy_metadata() -> None:
    galaxy = load_yaml("galaxy.yml")

    assert galaxy["namespace"] == "ak1ra_lab"
    assert galaxy["name"] == "certificate"
    assert galaxy["version"] == "0.1.0"
    assert galaxy["license"] == ["GPL-3.0-or-later"]
    assert galaxy["dependencies"] == {
        "ak1ra_lab.general": ">=0.4.0",
        "community.general": ">=8.0.0",
        "kubernetes.core": ">=6.0.0",
    }
    assert "build_ignore" in galaxy
    assert "manifest" not in galaxy


def test_runtime_requires_supported_ansible_core() -> None:
    runtime = load_yaml("meta/runtime.yml")

    assert runtime["requires_ansible"] == ">=2.19.0"


def test_every_role_requires_supported_ansible_core() -> None:
    roles = sorted(path.parent.parent.name for path in (REPO_ROOT / "roles").glob("*/meta/main.yml"))

    assert roles == ["acme_dns", "acme_dns_register", "cert_manager", "certbot"]
    for role in roles:
        meta = load_yaml(f"roles/{role}/meta/main.yml")
        assert meta["galaxy_info"]["min_ansible_version"] == "2.19"
        assert meta["galaxy_info"]["license"] == "GPL-3.0-or-later"
