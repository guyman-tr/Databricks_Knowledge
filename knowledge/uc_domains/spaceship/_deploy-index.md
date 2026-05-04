---
domain: spaceship
framework: uc-domain-doc
total_deployable: 1
generated: 1
deployed: 0
failed: 0
stub_only: 0
last_generate_batch: 0
last_deploy_batch: 0
last_updated: "2026-05-04"
---

# spaceship — UC ALTER Deployment Index

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Domain**                         | spaceship |
| **Total deployable**               | 1  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 1    |
| **Deployed (UC)**                  | 0          |
| **Stub-only (no UC)**              | 0   |
| **Failed**                         | 0          |
| **Last deploy batch**              | 0          |
| **Last updated**                   | 2026-05-04       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER/COMMENT, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## How to deploy

```
python tools/deploy_alter_batch.py \
    --wiki-root knowledge/uc_domains/spaceship/schemas \
    --deploy-index knowledge/uc_domains/spaceship/_deploy-index.md \
    --schema <schema-name> \
    --batch-size 5 --deploy-batch 1
```

Authenticate via `DATABRICKS_TOKEN` (PAT) or `DATABRICKS_MCP_PROFILE=DEFAULT`.

## Schema: `etoro_kpi` — 1 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [etoro_kpi.v_spaceship_fees](schemas/etoro_kpi/Views/v_spaceship_fees.md) | Generated |
