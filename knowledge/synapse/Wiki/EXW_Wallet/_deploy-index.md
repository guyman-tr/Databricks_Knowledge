---
schema: EXW_Wallet
database: Synapse DWH
total_deployable: 2
generated: 0
deployed: 2
failed: 0
stub_only: 0
last_generate_batch: 0
last_deploy_batch: 2
last_updated: "2026-05-05"
---

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | EXW_Wallet   |
| **Total deployable**               | 2  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 2         |
| **Stub-only (no UC)**              | 0   |
| **Failed**                         | 0         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 2          |
| **Last updated**                   | 2026-05-03       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## Tables (2)

| Object | Deploy status |
|--------|---------------|
| [EXW_Wallet.EXW_Price](Tables/EXW_Price.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_Wallet.EXW_PriceDaily](Tables/EXW_PriceDaily.md) | Deployed (Batch 2) — 2026-05-05|
