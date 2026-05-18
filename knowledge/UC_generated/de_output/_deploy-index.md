---
schema: de_output
framework: uc-pipeline-doc
total_deployable: 1
generated: 1
deployed: 0
failed: 0
stub_only: 0
last_generate_batch: 0
last_deploy_batch: 0
last_updated: "2026-05-17"
---

# de_output — UC-Pipeline ALTER Deployment Index

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | `main.de_output` |
| **Total deployable**               | 1  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 1    |
| **Deployed (UC)**                  | 0          |
| **Stub-only (no UC)**              | 0   |
| **Failed**                         | 0          |
| **Last deploy batch**              | 0          |
| **Last updated**                   | 2026-05-17       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER/COMMENT, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## How to deploy

```
python tools/deploy_alter_batch.py \
    --wiki-root knowledge/UC_generated/de_output \
    --deploy-index knowledge/UC_generated/de_output/_deploy-index.md \
    --schema de_output \
    --batch-size 5 --deploy-batch 1
```

Authenticate via `DATABRICKS_TOKEN` (PAT) or `DATABRICKS_MCP_PROFILE=DEFAULT`.

## Schema: `de_output` — 1 deployable, 0 stubs

| Object | Deploy status |
|--------|---------------|
| [de_output.de_output_etoro_kpi_fact_customeraction_w_metrics](Tables/de_output_etoro_kpi_fact_customeraction_w_metrics.md) | Generated |
