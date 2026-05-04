---
domain: moneyfarm
framework: uc-domain-doc
total_deployable: 6
generated: 0
deployed: 6
failed: 0
stub_only: 0
last_generate_batch: 0
last_deploy_batch: 4
last_updated: "2026-05-04"
---

# moneyfarm — UC ALTER Deployment Index

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Domain**                         | moneyfarm |
| **Total deployable**               | 6 |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0 |
| **Deployed (UC)**                  | 6 |
| **Stub-only (no UC)**              | 0 |
| **Failed**                         | 0 |
| **Last deploy batch**              | 4          |
| **Last updated**                   | 2026-05-04       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER/COMMENT, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## How to deploy

```
python tools/deploy_alter_batch.py \
    --wiki-root knowledge/uc_domains/moneyfarm/schemas \
    --deploy-index knowledge/uc_domains/moneyfarm/_deploy-index.md \
    --schema <schema-name> \
    --batch-size 5 --deploy-batch 1
```

Authenticate via `DATABRICKS_TOKEN` (PAT) or `DATABRICKS_MCP_PROFILE=DEFAULT`.

## Schema: `bi_output` — 3 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [bi_output.bi_output_moneyfarm_customers](schemas/bi_output/Tables/bi_output_moneyfarm_customers.md) | Deployed (Batch 2) — 2026-05-04|
| [bi_output.bi_output_moneyfarm_fact_portfolio_snapshot](schemas/bi_output/Tables/bi_output_moneyfarm_fact_portfolio_snapshot.md) | Deployed (Batch 2) — 2026-05-04|
| [bi_output.bi_output_moneyfarm_fact_transactions](schemas/bi_output/Tables/bi_output_moneyfarm_fact_transactions.md) | Deployed (Batch 2) — 2026-05-04|

## Schema: `etoro_kpi_prep` — 3 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [etoro_kpi_prep.v_moneyfarm_aum](schemas/etoro_kpi_prep/Views/v_moneyfarm_aum.md) | Deployed (Batch 4) — 2026-05-04|
| [etoro_kpi_prep.v_moneyfarm_fees](schemas/etoro_kpi_prep/Views/v_moneyfarm_fees.md) | Deployed (Batch 4) — 2026-05-04|
| [etoro_kpi_prep.v_moneyfarm_mimo](schemas/etoro_kpi_prep/Views/v_moneyfarm_mimo.md) | Deployed (Batch 4) — 2026-05-04|
