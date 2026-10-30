# cert_manager

> The canonical variable reference is generated from
> [`meta/argument_specs.yml`](meta/argument_specs.yml) in the collection documentation.

Manage [cert-manager](https://cert-manager.io/) in a Kubernetes cluster:

- optionally install or upgrade the controller from the official release
  manifest;
- declare ACME `ClusterIssuer` resources and their solver credentials.

The role does **not** create `Ingress` or `Certificate` resources. Applications
and their Helm/GitOps owners own those, usually by annotating an Ingress with
`cert-manager.io/cluster-issuer`; the role stays ingress-controller-neutral
(Traefik, HAProxy, Envoy Gateway, Cilium, ... all work through the same
annotations). An Ansible role is a poor owner for per-application resources.

## Requirements

Install the Kubernetes Python client (`kubernetes >= 24.2.0`) in the
environment that runs Ansible (for example `uv add kubernetes`). The k8s tasks
are delegated to `cert_manager_delegate_to` (default `localhost`); kubeconfig
and context default to `KUBECONFIG` / `~/.kube/config`. Run the role once
against the cluster, not on every node.

## Installation

```yaml
cert_manager_install: true
# Empty resolves the latest stable release. Pin a version for reproducible
# installs, for example v1.21.2.
cert_manager_version: ""
```

The role resolves the release with
`ak1ra_lab.general.github_releases_info` (latest stable when the version is
empty), downloads the `cert-manager.yaml` asset with its GitHub digest, applies
it server-side, and waits for the `cert-manager-webhook` deployment and the
`clusterissuers.cert-manager.io` CRD. Upgrade by changing the version; CRDs are
included in the manifest. URL/checksum overrides support mirrors and
air-gapped installs; a GitHub token avoids anonymous API rate limits.

If Helm or GitOps owns the cluster, set `cert_manager_install: false` and let
that tool own the controller and CRDs; do not apply the same objects from two
owners. The role intentionally does not use Helm: that would require a `helm`
binary on the delegate, chart version/values handling and a separate CRD
upgrade path, and Helm is better left to the tool that already owns the
cluster's releases. The role's value is the ClusterIssuer and solver-secret
layer, which works regardless of how the controller was installed.

## ClusterIssuers

```yaml
cert_manager_acme_email: admin@example.com

cert_manager_cluster_issuers:
  - name: letsencrypt-prod
    server: https://acme-v02.api.letsencrypt.org/directory
    solver:
      cloudflare:
        api_token: "{{ vault_cloudflare_api_token }}"
        secret_name: cloudflare-main
        dns_zones:
          - example.com

  - name: letsencrypt-http01
    server: https://acme-v02.api.letsencrypt.org/directory
    solver:
      http01:
        ingress_class: traefik
```

Each issuer needs a unique `name`, an ACME `server`, and exactly one solver:
`cloudflare` (DNS-01) or `http01`. Issuers can override the default ACME email,
scope DNS validation with `dns_zones`, select the HTTP-01 ingress class,
configure an optional ACME `profile`, and set EAB or account-key Secret names.
A `secret_name` without `api_token`/`hmac_key` references an externally owned
Secret; several issuers may share it if the values match. The role writes only
Secrets that carry a credential value.

Managed solver/EAB Secrets are created in
`cert_manager_cluster_resource_namespace` (default: the cert-manager
namespace); reference-only Secrets must already exist there. For a
`ClusterIssuer`, cert-manager resolves secret references in its cluster
resource namespace, not in the namespace of the Ingress. Match the role
variable to a custom `--cluster-resource-namespace`. The official manifest
always deploys the controller into `cert-manager`; if you pre-install it
elsewhere, set `cert_manager_install: false` and the namespace explicitly.

### Cloudflare

`solver.cloudflare.api_token` is rendered into a Secret under the `api-token`
key. Use a scoped token with `Zone:Read` and `DNS:Edit` for the zones.
`solver.cloudflare.dns_zones` becomes that issuer's `selector.dnsZones` (omit it
to select all zones the token can edit). Use the apex zone (`example.com`), not
`*.example.com`. The default Secret name is `<name>-cloudflare`; set
`secret_name` explicitly when several issuers share one token or the Secret is
managed outside this role. A `secret_name` without `api_token` is reference-only.

### External account binding (EAB)

EAB is a CA feature; ZeroSSL is the common public CA that requires it. It
belongs to the ACME account, so it is configured per issuer:

```yaml
cert_manager_cluster_issuers:
  - name: zerossl-prod
    server: https://acme.zerossl.com/v2/DV90
    solver:
      cloudflare:
        secret_name: cloudflare-main
    eab:
      key_id: "..."
      hmac_key: "{{ vault_eab_hmac }}"
      # Optional; defaults to zerossl-prod-eab.
      secret_name: zerossl-eab
```

`hmac_key` is the **base64url-encoded** key from the CA (the same string
certbot accepts); cert-manager decodes it with `base64.RawURLEncoding`, so do
not pass raw bytes. HS256 requires at least 32 bytes (RFC 7518). When
`hmac_key` is empty and `secret_name` is set, the role only references an
existing Secret. EAB credentials are tied to the ACME account: re-creating the
account requires a new key/HMAC from the CA.

### Why only Cloudflare for DNS-01?

cert-manager supports many `dns01` providers, but each has a different solver
schema and credential keys. This role implements the Cloudflare solver and the
provider-neutral `http01` solver. For another DNS provider, manage that
ClusterIssuer yourself or extend the template with its schema and Secret.

### HTTP-01

The HTTP-01 solver creates a temporary Ingress per challenge, so it needs an
ingress controller that serves the challenge path. Set
`solver.http01.ingress_class` explicitly when the cluster has more than one
`IngressClass` or no default.

## Rendering manifests

Set `cert_manager_manifest_dir` to an absolute path on the delegate host to
write every managed Secret and ClusterIssuer as YAML (reference-only Secrets
are not rendered):

```yaml
cert_manager_apply: false
cert_manager_manifest_dir: /tmp/cert-manager
```

This hands the resources to review or a GitOps repository. Secret files contain
base64-encoded credentials (not encrypted); the directory is `0700`, Secret
files are `0600`, and the manifests should be vaulted or deleted after use.
With `cert_manager_apply: true` (the default) the definitions are also applied.

## Ownership and lifecycle

- Pick one owner for the cert-manager controller and for each ClusterIssuer.
  Running this role next to Flux/ArgoCD against the same objects is a conflict.
- The role is additive-only: removing an issuer or credential does not delete
  the ClusterIssuer or Secret, and does not remove old manifest files. Delete
  those deliberately.
- cert-manager creates the ACME account key and certificates; the role only
  manages issuers and solver/EAB Secrets. Do not delete account-key or
  certificate Secrets to "reset" something.
- Deleting the cert-manager CRDs deletes every `Certificate` and `Order`
  resource with them. Uninstall deliberately.
- Secret rotation is an apply: change `api_token`/`hmac_key` and re-run; new
  orders use the new credential, existing certificates renew later. Monitor
  the certificate expiration/ready metrics; an issuer alone does not guarantee
  renewal.

## Testing

`cert_manager_render` verifies Secret/ClusterIssuer rendering, shared and
reference-only Secrets, solver references and permissions. The apply path is
covered against a real cluster.
