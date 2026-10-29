# Roles

Each page below is the canonical `roles/<role>/README.md`, included in the
docs site from the role directory. Edit the role README, not this index, when
the contract changes.

| Role | Description |
| --- | --- |
| [`acme_dns`](acme_dns.md) | Deploy an acme-dns server with the Go binary built on the controller and a systemd service. |
| [`acme_dns_register`](acme_dns_register.md) | Register one acme-dns account per validation domain and create `_acme-challenge` CNAMEs. |
| [`certbot`](certbot.md) | Obtain and renew certificates with certbot from apt, PyPI, or an external binary. |
| [`cert_manager`](cert_manager.md) | Install cert-manager and declare ACME `ClusterIssuer` resources with per-issuer solvers. |
