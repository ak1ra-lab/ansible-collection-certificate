# certbot

> The canonical variable reference is generated from
> [`meta/argument_specs.yml`](meta/argument_specs.yml) in the collection documentation.

Obtain and renew TLS certificates with [certbot](https://certbot.eff.org/) on a
systemd host. DNS-01 is the primary challenge type; HTTP-01 is available for
hosts without DNS API access.

The role only obtains certificates. Services that consume them (nginx, ...) are
configured by their own roles and reload after a renewal through the global
`certbot_deploy_hooks` or a certificate's own `deploy_hooks`.

## Installation sources

| Source | Behavior |
| --- | --- |
| `apt` (default) | Installs `certbot` and `python3-certbot-dns-<provider>` from the distribution. Debian 12 ships certbot 2.1 and Debian 13 ships 4.0. The role writes its own systemd units under `/etc/systemd/system`, shadowing the distribution units. |
| `pypi` | Installs `certbot` and `certbot-dns-<provider>` into an isolated virtualenv through `ak1ra_lab.general.pyproject_install` (`/var/lib/certbot/venv` by default). Useful for a newer certbot than the distribution provides. |
| `none` | Uses an externally provided certbot (snap, image, ...); set `certbot_bin`. The role does not manage units or the timer by default; set `certbot_manage_timer: true` to opt in. |

The role never mixes binaries: the systemd unit, issuance command and renewal
timer all use `certbot_bin`. A leftover `/usr/bin/certbot` is reported as a
warning when `pypi` is selected. For `apt` and `pypi` the role always renders
its own marked `/etc/systemd/system/certbot.service` and `certbot.timer`, so
the binary, directories, renewal arguments and `certbot_no_verify_ssl` stay
consistent across sources.

`cli.ini` and logrotate are optional: the role writes them for `pypi` by
default and removes its own marked copies when the corresponding management
flag is disabled. It does not delete DNS credentials, the acme-dns registry or
the acme-dns auth hook automatically, because existing lineages may still
reference them.

## Certificates

`certbot_certificates` is a list of lineages. Each entry sets `domains` and may
set a lineage `name`, `force`, per-certificate `deploy_hooks`, and
`extra_args`. The name defaults to the first domain with a leading `*.`
stripped, matching certbot.

On every run the role compares existing SANs with the requested domains. A
missing lineage, a changed domain set, or `force: true` triggers
`certbot certonly --cert-name ...`; unchanged lineages are left alone, avoiding
ACME rate-limit consumption. `--cert-name` with the full domain list replaces
`--expand` and can also remove domains, so the role does not pass `--expand`.

```yaml
certbot_email: admin@example.com
certbot_certificates:
  - name: example.com
    domains:
      - example.com
      - "*.example.com"
```

`certbot_key_type` defaults to `ecdsa` (certbot's own default since 2.0). Set
it to `rsa` to use `certbot_rsa_key_size` (4096) instead. For ECDSA,
`certbot_elliptic_curve` defaults to `secp256r1`.

## ACME CA and EAB

`certbot_acme_ca` selects `letsencrypt` (default), `zerossl`, `google`, or
`buypass`; `certbot_acme_server` overrides it with an explicit directory URL
(private CA, test server). `certbot_staging: true` selects Let's Encrypt
staging through `--test-cert` and requires the `letsencrypt` preset; it cannot
be combined with `certbot_acme_server`.

Some CAs require external account binding (ZeroSSL, Google Trust Services,
SSL.com). EAB is part of certbot's ACME client, not a plugin:

```yaml
certbot_acme_ca: zerossl
certbot_eab:
  key_id: "..."
  hmac_key: "{{ vault_eab_hmac }}"
```

`hmac_key` is the base64url-encoded key from the CA; pass it verbatim. HS256
requires at least 32 bytes (RFC 7518). EAB is passed to `certonly`, not
`renew`; certbot does not store it in the renewal configuration, so back up
`/etc/letsencrypt/accounts` and re-run the role if the account is recreated.
`certbot_eab` requires a non-default CA or explicit `certbot_acme_server` and
cannot be combined with `certbot_staging`.

## DNS-01

`certbot_dns_provider` selects the `certbot-dns-<provider>` plugin
(`cloudflare` by default). `certbot_dns_credentials` is a plain mapping of the
plugin's INI keys, rendered verbatim to
`/etc/letsencrypt/credentials/<provider>.ini` (mode `0600`; directory `0700`):

```yaml
certbot_dns_credentials:
  dns_cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
```

Common plugins use `dns_cloudflare_api_token` (Cloudflare),
`dns_digitalocean_token` (DigitalOcean), or rfc2136 server/name/secret/algorithm
keys. Route53 and Google use the cloud credential chain and need no INI file.
Credentials are additive: the role does not delete files for other providers,
the acme-dns registry or the acme-dns auth hook. Remove those manually only
after deleting or reissuing the lineages that use them.

### Cloudflare

Use a scoped API token with `Zone:Read` and `DNS:Edit` for the zones being
validated, not the legacy global API key.

### acme-dns

`certbot_dns_provider: acmedns` uses certbot's manual plugin with the bundled
auth hook. The role stores **one acme-dns account per validation domain** in a
JSON registry (`/etc/letsencrypt/credentials/acmedns.json` by default); the
hook reads `CERTBOT_DOMAIN`, strips a leading `*.`, selects that domain's
account, and calls `/update` with only the Python standard library.

```json
{"server_url": "https://auth.example.com",
 "accounts": {"example.com": {"username": "...", "password": "...",
                              "subdomain": "...", "fulldomain": "..."}}}
```

`example.com` and `*.example.com` share the `example.com` account because both
use `_acme-challenge.example.com`; `www.example.com` gets its own account.
Each acme-dns account has two TXT slots, so the base + wildcard pair fits
exactly. Accounts can come from the persisted registry written by
`ak1ra_lab.certificate.acme_dns_register`, from the role's explicit account
input, or be registered automatically. The registry is read from
`acme_dns_credentials.yml`; an existing `acme_dns_credentials.yaml` is accepted
as a migration fallback, and `.yml` wins when both exist:

```yaml
certbot_dns_provider: acmedns
certbot_acmedns_register: true
certbot_acmedns_server_url: https://auth.example.com
certbot_acmedns_cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
certbot_certificates:
  - domains:
      - example.com
      - "*.example.com"
      - www.example.com
```

The zone-scoped Cloudflare token is the least-privilege alternative and takes
precedence when both are set. With registration enabled, the role registers
one account per validation domain and creates the corresponding CNAME records;
global and per-domain zone overrides cover public suffixes and multi-zone
certificates. Without a Cloudflare token, the role displays the required CNAME
records and pauses after a fresh registration (disable the manual prompt for
non-interactive runs). Each domain's CNAME points at its own fulldomain, for
example `_acme-challenge.example.com. CNAME <account>.auth.example.com.`.

## HTTP-01

Set `certbot_challenge: http-01` when DNS-01 is not an option:

```yaml
certbot_challenge: http-01
certbot_http01_method: standalone   # or webroot
certbot_http01_port: 80
certbot_webroot_path: /var/www/html
```

`standalone` starts a temporary web server and binds the configured port
itself, so no other process may listen on that port. It is unrelated to the
third-party `siilike/certbot-dns-standalone` plugin (a DNS-01 authenticator).
Public ACME CAs always send the HTTP-01 request to **port 80**; a non-80 local
port works only with a private/test ACME server or external port forwarding.

`webroot` only writes the challenge file to
`<certbot_webroot_path>/.well-known/acme-challenge/`; an already running web
server must serve that path for every requested domain on port 80 (or on a
forwarded local port). The role checks that the webroot exists and is absolute,
but does not modify the web server configuration. All names in
`certbot_certificates` must share one webroot. The `--nginx` and `--apache`
plugins are deliberately not supported; this role stays web-server-neutral.
HTTP-01 cannot issue wildcard certificates.

For both methods the DNS A/AAAA records for every requested name must already
point at this host. The role does not check DNS: split-horizon, CDN/proxy and
multi-address setups make a local lookup unreliable.

## Renewal and hooks

The role enables `certbot.timer` (twice daily with a randomized delay and
`Persistent=true`). `certbot_manage_timer` defaults to true for apt/pypi and
false for `none`; the unit runs `certbot -q renew --no-random-sleep-on-renew`
with the same binary and directories as issuance.

The role only reissues a lineage when it does not exist, when `force: true` is
set, or when the requested SAN set differs. Changing the ACME CA/server,
challenge type, DNS provider, or key type/curve does **not** modify an existing
lineage; its renewal configuration keeps the old parameters, avoiding
unexpected reissuance and rate-limit consumption. Set `force: true` (or delete
and re-run) to apply new renewal parameters.

`certbot_deploy_hooks` is global and runs after **any** successful renewal for
shared consumers such as a web server:

```yaml
certbot_deploy_hooks:
  - nginx -t && systemctl reload nginx
```

A certificate's own `deploy_hooks` run only when that lineage renews:

```yaml
certbot_certificates:
  - name: app.example.com
    domains: [app.example.com]
    deploy_hooks:
      - install -d -m 0750 -o root -g app /etc/app/tls
      - >-
        install -m 0640 -o root -g app
        /etc/letsencrypt/live/app.example.com/fullchain.pem
        /etc/app/tls/fullchain.pem
      - systemctl reload app
```

The role renders one dispatcher in
`/etc/letsencrypt/renewal-hooks/deploy/`; it runs the global commands, then
uses `RENEWED_LINEAGE` to select the certificate's hooks. Renewal granularity
is the lineage, not an individual SAN.

certbot creates `/etc/letsencrypt/live` and `archive` as `0700` with `0600`
`root:root` private keys. Root-run services (nginx, haproxy) can read them
directly. For a process that drops privileges, copy the certificate and key in
a deploy hook to a service-owned location and create that group/directory
first. The hook runs only after a renewal (and on certbot 3.2+, after
`certonly`); deploy the initial files after first issuance. Debian 12
(certbot 2.1) does not run hooks after the initial `certonly`. ACLs work for
in-place reads, but must be re-applied on every renewal and need execute
permission on the directory chain.

Renewal notes:

- The initial issuance is not an "auto reload" moment; the consumer role must
  deploy its TLS configuration after certbot creates the lineage.
- A failing deploy hook is logged but does not make the timer unit fail.
  Monitor the service and certificates.
- Back up `/etc/letsencrypt` (account key, renewal config, lineages); use
  `certbot delete --cert-name ...` instead of deleting the directory.
- Staging and production share the lineage name, so switching CA on an
  existing lineage requires a forced re-issuance.
- `certbot_no_verify_ssl: true` is for test/private endpoints; the managed unit
  passes it to `renew` for apt/pypi. For `none`, configure the external timer.
- Drift detection needs the `openssl` CLI; the role fails clearly when it is
  missing.

## Paths and composition

`certbot_config_dir`, `certbot_work_dir`, `certbot_log_dir`, and the
credential/registry paths are configurable; commands receive the directories
explicitly. Point nginx at `/etc/letsencrypt/live/<name>/fullchain.pem` and
`privkey.pem`; its root master process can read the default `0700` live
directory. The role-managed units, `cli.ini` and logrotate snippets are
independently written equivalents of the Debian 13 package files.

## Testing

Molecule scenarios cover apt/PyPI installation, Pebble HTTP-01 issuance with
EAB, renewal and timer units, deploy-hook dispatch, and acme-dns per-domain
account selection on Debian 12/13 without real Let's Encrypt rate limits.
