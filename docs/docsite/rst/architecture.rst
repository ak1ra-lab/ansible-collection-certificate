.. _ansible_collections.ak1ra_lab.certificate.docsite.architecture:

Architecture
============

The collection separates certificate issuance from certificate consumption.
Roles expose narrow variable contracts; consumer playbooks compose them in the
order their infrastructure requires.

Role families
-------------

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Role
     - Responsibility
   * - ``acme_dns``
     - Deploy an acme-dns server (Go binary built on the controller, config,
       systemd unit, service account).
   * - ``acme_dns_register``
     - Register one acme-dns account per validation domain, persist the
       registry, and publish ``_acme-challenge`` CNAMEs.
   * - ``certbot``
     - Obtain and renew certificates with certbot from apt, PyPI, or an
       external binary.
   * - ``cert_manager``
     - Install cert-manager and declare ACME ``ClusterIssuer`` resources with
       solver or EAB credentials.

acme-dns flow
-------------

``acme_dns`` owns the server side: it builds acme-dns with
``ak1ra_lab.general.go_build`` on the controller, installs the binary and
configuration, and runs the service. Parent-zone NS/glue delegation is outside
the role.

``acme_dns_register`` owns the client registration side. It runs registration
on the managed host (which needs access to the acme-dns API), writes the
domain-to-account registry on the controller, and creates CNAME records through
Cloudflare or a manual prompt.

certbot flow
------------

``certbot`` only obtains certificates. Services that consume them (nginx,
mihomo, ...) are configured by their own roles and reload after renewal through
``certbot_deploy_hooks`` or a certificate's own ``deploy_hooks``. DNS-01 is the
primary challenge type; HTTP-01 is available for hosts without DNS API access.

cert-manager flow
-----------------

``cert_manager`` deliberately does not create ``Ingress`` or ``Certificate``
resources. Applications or their Helm/GitOps owners create those, usually by
annotating an Ingress with ``cert-manager.io/cluster-issuer``. The role can
install or upgrade the controller, then declares ``ClusterIssuer`` resources
and only the solver/EAB secrets that carry credentials.

Composition
-----------

A consumer playbook might apply ``acme_dns`` on the DNS host,
``acme_dns_register`` on the controller, then ``certbot`` on an application
host. A Kubernetes consumer instead applies ``cert_manager`` once against the
cluster and leaves per-application certificates to the application manifests.
