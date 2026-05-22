# Migration to the Landing Zone

Moving the existing flat deployment into the bank-grade landing zone, with no
data loss. Blue/green: build new in parallel, migrate data, cut over, decommission.

## Current state (discovered via `scw`)

Project `TMFCoders-IT`, region `fr-par`, zone `fr-par-1`:

| Resource | Detail |
|----------|--------|
| VM `odoo19-production` | DEV1-M, Ubuntu 22.04, public IP `51.15.128.108`, SSH:22 open |
| └ volumes | `l_ssd` 20 GB boot + `odoo19-production-data` 20 GB (Odoo DB + filestore) |
| VM `tf-srv-eager-almeida` | PRO2-XXS, public IP `163.172.143.172`, untagged |
| Bucket | `tmfcoders-odoo-backups-prod-a2b56` |
| VPC / RDB / Gateway / LB / Cockpit / Secrets / IAM apps | none |

The landing zone is **not deployed** — it must be created as part of this migration.

## Decisions (taken)

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Target **Odoo 19** + Managed **PostgreSQL 16** | Running VM is Odoo 19 on jammy — a downgrade is impossible; `3-apps` now clones branch `19.0`. |
| 2 | `tf-srv-eager-almeida` is **out of scope** | Untagged, unknown purpose. Snapshot it and leave it running; delete only after the owner confirms. |
| 3 | **No `terraform import`** — blue/green rebuild | Old topology (flat, public IPs, local PostgreSQL) is structurally incompatible with the VPC + Managed DB landing zone. Old VM becomes an orphan, deleted post-cutover. |
| 4 | Migrated Odoo runs as tenant **`tmf-internal`** (Project-mode) | It is an internal TMF Coders workload. |
| 5 | VMs **powered off 01:00-09:00 CET** | Cost saving; implemented by `modules/scheduler` (Serverless Function + crons), enabled by default in `3-apps`. |

## Phase 0 — Safety net

```bash
# Snapshot both Odoo volumes (rollback points)
scw instance snapshot create zone=fr-par-1 name=odoo19-boot-premigration \
  volume-id=51af49be-ef20-4dee-a879-a62b43a58f7c
scw instance snapshot create zone=fr-par-1 name=odoo19-data-premigration \
  volume-id=9e62b6d6-dbf0-4b16-b3e7-29f27d87f8e3

# Full bootable image of the Odoo VM
scw instance image create zone=fr-par-1 name=odoo19-premigration-image \
  server-id=677fa144-456a-4cd8-bd5e-dc67cf16bad9

# Snapshot the unknown VM too, before anything
scw instance image create zone=fr-par-1 name=tf-srv-premigration-image \
  server-id=8801c458-588f-4ed3-9ced-7a6771053d3e
```

## Phase 1 — Deploy the landing zone

```bash
./init.sh

export SCW_ACCESS_KEY=...   SCW_SECRET_KEY=...
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"

# Landing zone (once)
make bootstrap-apply
make bootstrap-migrate            # after copying the bucket name into backend.hcl

# Tenant project
make tp-init && make tp-apply
make tp-output                    # note the tmf-internal project_id

# Tenant config
scripts/new-tenant.sh tmf-internal prod project internal \
  <project_id> <state_bucket> <suffix> ops@tmfcoders.com

# Deploy all layers
make tenant-apply-all TENANT=tmf-internal ENV=prod
```

Result: a new Odoo 19 VM in a VPC, Managed PostgreSQL 16, Load Balancer,
bastion, Cockpit — and the power scheduler.

## Phase 2 — Back up Odoo data (old VM)

```bash
ssh root@51.15.128.108

# Database (use the real DB name + PostgreSQL superuser)
sudo -u postgres pg_dump -Fc -d <ODOO_DB> -f /tmp/odoo-db.dump

# Filestore (path = data_dir in odoo.conf; typical location shown)
tar czf /tmp/odoo-filestore.tar.gz -C /opt/odoo/.local/share/Odoo/filestore .

# Upload both to the existing backup bucket
```

## Phase 3 — Migrate data (cutover window)

**Run in this exact order.**

1. On the old VM: `systemctl stop odoo` — freeze writes.
2. Take a final consistent `pg_dump` (now that writes are stopped).
3. Restore into the new Managed PostgreSQL:
   ```bash
   pg_restore --no-owner --no-privileges \
     -h <rdb_endpoint> -U odoo -d <new_db> /tmp/odoo-db.dump
   ```
4. Copy the filestore to the new Odoo VM (via the bastion, `rsync`) into its
   `data_dir`.
5. Start Odoo on the new VM; confirm the PostgreSQL target version >= source.

## Phase 4 — Cutover & verify

1. Point DNS / the `odoo_domain` of the Load Balancer at the new instance.
2. Verify: login, records, attachments (filestore), PDF reports.
3. Keep the old VM **stopped, not deleted**, for the verification window.

## Phase 5 — Decommission (after verification)

```bash
# Old Odoo VM + its volumes + IP
scw instance server delete zone=fr-par-1 with-volumes=all with-ip=true \
  677fa144-456a-4cd8-bd5e-dc67cf16bad9

# tf-srv-eager-almeida - only once its owner confirms it is disposable
```

Keep the Phase 0 snapshots and the Phase 2 dump as a cold backup.

## Risk notes

- **Odoo version**: `3-apps` now targets Odoo 19 / PostgreSQL 16 — required to
  restore the dump.
- **`l_ssd` volumes** are local to the VM; migration is dump/restore, not a
  volume move (the new VM uses `sbs_volume`).
- **Public SSH:22** on the old VM is a current exposure; the landing zone
  closes it (bastion-only).
- **Power schedule**: the new VMs are off 01:00-09:00 CET — schedule the
  cutover and any verification outside that window, or set
  `enable_power_schedule = false` until the migration is signed off.
