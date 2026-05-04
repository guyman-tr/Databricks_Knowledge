---
domain: spaceship
framework: uc-domain-doc
total_deployable: 7
generated: 0
deployed: 4
failed: 3
stub_only: 0
last_generate_batch: 0
last_deploy_batch: 4
last_updated: "2026-05-04"
---

# spaceship — UC ALTER Deployment Index

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Domain**                         | spaceship |
| **Total deployable**               | 7 |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0 |
| **Deployed (UC)**                  | 4 |
| **Stub-only (no UC)**              | 0 |
| **Failed**                         | 3 |
| **Last deploy batch**              | 4          |
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

## Schema: `bizops_output` — 3 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [bizops_output.bizops_output_spaceship_dim_customers](schemas/bizops_output/Tables/bizops_output_spaceship_dim_customers.md) | Failed (deploy Batch 2) — PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_dim_customers'.|
| [bizops_output.bizops_output_spaceship_fact_customer_products](schemas/bizops_output/Tables/bizops_output_spaceship_fact_customer_products.md) | Failed (deploy Batch 2) — PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_fact_customer_products|
| [bizops_output.bizops_output_spaceship_gold_daily_update](schemas/bizops_output/Tables/bizops_output_spaceship_gold_daily_update.md) | Failed (deploy Batch 2) — PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_gold_daily_update'.|

## Schema: `etoro_kpi` — 3 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [etoro_kpi.v_spaceship_aum](schemas/etoro_kpi/Views/v_spaceship_aum.md) | Deployed (Batch 4) — 2026-05-04|
| [etoro_kpi.v_spaceship_fees](schemas/etoro_kpi/Views/v_spaceship_fees.md) | Deployed (Batch 3) — 2026-05-04|
| [etoro_kpi.v_spaceship_mimo](schemas/etoro_kpi/Views/v_spaceship_mimo.md) | Deployed (Batch 4) — 2026-05-04|

## Schema: `etoro_kpi_prep` — 1 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [etoro_kpi_prep.v_spaceship_mimo](schemas/etoro_kpi_prep/Views/v_spaceship_mimo.md) | Deployed (Batch 4) — 2026-05-04|