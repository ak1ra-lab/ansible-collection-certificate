# acme_dns

> The canonical variable reference is generated from
> [`meta/argument_specs.yml`](meta/argument_specs.yml) in the collection documentation.

Deploys an [acme-dns](https://github.com/acme-dns/acme-dns) server: a limited DNS
server with a RESTful HTTP API for handling ACME DNS-01 challenges.

## How It Works

1. `ak1ra_lab.general.go_build` clones and builds the acme-dns binary on
   `localhost` (the Ansible controller).
2. A dedicated system user, group, and directories are created on the target.
3. The binary, the rendered `config.cfg`, and the systemd unit are deployed.
4. `acme-dns.service` is started and enabled.

The role manages only the acme-dns server. Parent-zone delegation records
(NS/glue) and client `_acme-challenge` CNAMEs are outside its scope; see
[DNS Delegation](#dns-delegation).

## Naming

`acme_dns_zone` maps to acme-dns's `general.domain`. It is the zone that holds
the `_acme-challenge` TXT records and, with `acme_dns_api_tls: letsencrypt`,
the hostname for which acme-dns obtains its own API certificate. It is not the
deprecated `[api] api_domain` option.

`acme_dns_nsname` has no default on purpose. It is a separate name from the
zone and needs its own address record in the parent zone. Defaulting it to
`acme_dns_zone` would hide that requirement and turn a separate-nameserver
setup into a self-delegation.

## DNS Delegation

Records are needed in two different places. This role renders only the second
group; the first group must be created at the DNS provider for the parent zone.

### 1. Parent zone (e.g. Cloudflare for `example.com`)

With `acme_dns_zone: auth.acme-dns.example.com`,
`acme_dns_nsname: ns1.acme-dns.example.com`, and
`acme_dns_server_ip: 198.51.100.1`:

| Type | Name | Value | Purpose |
| --- | --- | --- | --- |
| NS | `auth.acme-dns.example.com` | `ns1.acme-dns.example.com` | delegate the zone to acme-dns |
| A | `ns1.acme-dns.example.com` | `198.51.100.1` | address of the nameserver target |

`ns1.acme-dns.example.com` is a normal authoritative record in the parent
zone; many DNS providers call it a glue record. It is required: without it a
resolver cannot reach the delegated nameserver. If `acme_dns_nsname` is in a
different zone, put the A record in that zone instead. If `acme_dns_nsname` is
inside `acme_dns_zone`, the A record in the parent zone is true glue and is
mandatory, because resolving the NS name would otherwise depend on the zone it
serves.

Self-delegation is still possible: set `acme_dns_nsname` explicitly to
`acme_dns_zone`. In that case the parent zone needs both the NS record and an
A record for the zone (true glue). The role no longer chooses this for you,
because it hides the extra parent-side A record.

Add these records before starting the role with
`acme_dns_api_tls: letsencrypt` (or `letsencryptstaging`): acme-dns obtains its
own API certificate through a DNS-01 challenge that the CA must be able to
resolve through this delegation. If the delegation is not live yet, the
service starts but cannot obtain a certificate until it is.

### 2. acme-dns `config.cfg` `records` (rendered by this role)

For the same values:

| Type | Name | Value | Purpose |
| --- | --- | --- | --- |
| A | `auth.acme-dns.example.com` | `198.51.100.1` | zone apex / API hostname |
| NS | `auth.acme-dns.example.com` | `ns1.acme-dns.example.com` | apex NS RRset |

Both are rendered. The apex A record makes the API hostname resolve through
the parent delegation (and is optional for the DNS-01 flow itself). The apex
NS record is recommended for a consistent zone, but it is not required for
ACME: a resolver follows the parent NS delegation and asks acme-dns for
`_acme-challenge.<zone>` TXT records, which are served from the database.
Without the static NS record, `dig NS <zone> @<server>` returns `NOERROR` with
an empty answer, and zone-checking tools report a missing apex NS RRset.

The role adds an A record for `acme_dns_nsname` only when that name is inside
`acme_dns_zone`. Do not add an out-of-zone `nsname` to acme-dns's `records`:
acme-dns is not authoritative for the parent zone, so resolvers will not ask
it for that name. The address record belongs in the parent zone as shown
above.

### 3. Client CNAMEs

Each certificate domain needs a `_acme-challenge` CNAME pointing at the
`fulldomain` returned by the acme-dns registration API, for example:

```text
_acme-challenge.example.com. CNAME <subdomain>.auth.acme-dns.example.com.
```

This is handled by `ak1ra_lab.certificate.acme_dns_register` when Cloudflare
credentials are supplied; otherwise the role prompts for the records.

## Requirements

- `go` must be available on the controller (`go_build` fails immediately if not).
- The target must be able to bind the configured DNS and API addresses; when TLS
  is handled by a reverse proxy, use `acme_dns_api_tls: none`.
- The parent-zone delegation must exist before clients (and, with
  `letsencrypt`, before acme-dns itself) can use the service.

## Migration Notes

- `acme_dns_domain` was renamed to `acme_dns_zone`. The old name is no longer
  read, to keep "the zone served" distinct from the deprecated `[api]
  api_domain` option.
- `acme_dns_nsname` is now required. It no longer defaults to the zone name.
- `acme_dns_home_dir` / `acme_dns_config_dir` now default to paths derived from
  `acme_dns_user`; `acme_dns_group` remains a separate variable and defaults to
  `acme-dns`.
- Trailing dots in `acme_dns_zone` and `acme_dns_nsname` are accepted and
  stripped before rendering; acme-dns itself appends the root label.
