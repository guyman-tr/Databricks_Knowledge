---
object_fqn: main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:46Z'
upstreams:
- etoro.Hedge.HedgeServerToLiquidityAccount
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md
  source_database: etoro
  source_schema: Hedge
  source_table: HedgeServerToLiquidityAccount
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/HedgeServerToLiquidityAccount
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_hedge_hedgeservertoliquidityaccount

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.HedgeServerToLiquidityAccount`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jun 09 12:14:53 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.HedgeServerToLiquidityAccount` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md`.

- Lake path: `Bronze/etoro/Hedge/HedgeServerToLiquidityAccount`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.HedgeServerToLiquidityAccount`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HedgeServerID | INT | YES | FK to Trade.HedgeServer(HedgeServerID). The hedge server that owns this liquidity account. Non-unique (a server can have multiple account rows, e.g., HedgeServerID=8 has 2 accounts). Indexed via IXHedgeServerID for per-server account lookups (Tier 2 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 1 | LiquidityAccountID | INT | YES | PK and FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account assigned to the hedge server. Each account belongs to exactly one server (PK enforces this) (Tier 2 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 2 | AltRatesLiquidityAccountID | INT | YES | FK to Trade.LiquidityAccounts(LiquidityAccountID). Optional second account used for alternative rate/price discovery. Currently NULL for all 11 rows - feature defined but not yet configured (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 3 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 4 | AppLoginName | STRING | YES | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 5 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |
| 6 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerToLiquidityAccount (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.HedgeServerToLiquidityAccount` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.HedgeServerToLiquidityAccount
        │
        ▼
main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| HedgeServerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| LiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| AltRatesLiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HedgeServerToLiquidityAccount) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
