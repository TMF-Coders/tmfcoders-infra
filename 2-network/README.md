# Layer: 2-network

Per-tenant network foundation. Deployed once per *(tenant, environment)*.

## Purpose

- One regional **VPC v2**.
- Two **private networks** with dedicated IPv4 subnets:
  - `tmf`  — `10.10.10.0/24` (Matriz / OpenClaw)
  - `apps` — `10.10.20.0/24` (Filial / Odoo + PostgreSQL)
- One **Public Gateway** providing NAT egress and an SSH bastion (port 61000).

No workload is exposed directly to the internet. Each tenant gets its own VPC —
networks are never shared across tenants.

## Dependencies

- `0-bootstrap` (state bucket).
- A tenant project.

## Deploy

```bash
make tenant-apply TENANT=<t> ENV=<env> LAYER=2-network
```

## Key inputs

| Name | Description | Default |
|------|-------------|---------|
| `environment`, `tenant`, `cost_center`, `billing_mode`, `project_id` | Tenant dimensions | — |
| `public_gateway_type` | Public Gateway commercial type | `"VPC-GW-S"` |

## Outputs (consumed by 3-apps)

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `tmf_network_id` / `apps_network_id` | Private network IDs |
| `tmf_subnet` / `apps_subnet` | Subnet CIDRs |
| `public_gateway_id` / `public_gateway_ip` | Gateway ID and public IP |
| `bastion_port` | SSH bastion port |
