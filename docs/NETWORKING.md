# Networking - TMF Coders Infrastructure

Per-tenant VPC v2 topology on Scaleway.

## Topology (per tenant/environment)

```
Tenant Project
└── VPC: <tenant>-<env>-vpc            (regional, fr-par)
    │
    ├── Private Network: <tenant>-<env>-tmf      10.10.10.0/24
    │     └── OpenClaw VM (Matriz)
    │
    ├── Private Network: <tenant>-<env>-apps     10.10.20.0/24
    │     ├── Odoo 17 VM (Filial)
    │     └── Managed PostgreSQL (IPAM-attached)
    │
    └── Public Gateway: <tenant>-<env>-gateway
          ├── NAT masquerade + default route   (egress for both PNs)
          └── SSH bastion  :61000              (only public VM ingress)

Internet ──HTTPS:443──> Load Balancer (LB-S) ──HTTP:8069──> Odoo VM
```

## Address plan

| Network | CIDR | Workload |
|---------|------|----------|
| VPC supernet | `10.10.0.0/16` | reference range for firewall rules |
| `tmf` subnet | `10.10.10.0/24` | OpenClaw |
| `apps` subnet | `10.10.20.0/24` | Odoo + PostgreSQL |

Each tenant has its own VPC and its own copy of this plan. Networks are never
shared or peered across tenants — isolation is total.

## Egress

The Public Gateway provides NAT masquerade. `scaleway_vpc_gateway_network`
pushes a default route into each private network (`ipam_config.push_default_route`).
VMs reach the internet for updates without holding a public IP.

## Ingress

| Path | Allowed | Mechanism |
|------|---------|-----------|
| SSH to a VM | operators only | Public Gateway bastion, port 61000 |
| HTTP(S) to Odoo | public | Load Balancer → backend `:8069` |
| Anything else inbound | denied | security group default-deny |

### Bastion access

```bash
make tenant-init TENANT=<t> ENV=<env> LAYER=2-network
GW_IP=$(terraform -chdir=2-network output -raw public_gateway_ip)
ssh -J bastion@${GW_IP}:61000 root@<vm-private-ip>
```

## Firewall (security groups)

`1-org` defines two stateful security groups, default-deny inbound:

| Group | Allowed inbound |
|-------|-----------------|
| `<tenant>-<env>-main` | TCP 22 from `10.10.0.0/16` |
| `<tenant>-<env>-apps` | TCP 22 from `10.10.0.0/16`; TCP 8069/8072 from `10.10.20.0/24` |

Outbound default-accept (egress via NAT). Odoo HTTP/longpolling ports are
reachable only from the apps subnet — public traffic arrives through the LB.

## Load Balancer

`scaleway_lb` (LB-S) attached to the `apps` private network. Backend targets
the Odoo VM's IPAM IP (`scaleway_ipam_ip` data source). Frontend on 443 with a
Let's Encrypt certificate when `odoo_domain` is set, otherwise HTTP on 80.
