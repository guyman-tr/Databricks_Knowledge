---
object_fqn: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:12:46Z'
upstreams:
- etoro.Hedge.HBCAccountConfiguration
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md
  source_database: etoro
  source_schema: Hedge
  source_table: HBCAccountConfiguration
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/HBCAccountConfiguration
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 4
  unverified_columns: 0
---

# bronze_etoro_hedge_hbcaccountconfiguration

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.HBCAccountConfiguration`). 9 of 13 columns inherited from Tier 1 source wiki; 4 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 07 04:21:26 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.HBCAccountConfiguration` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md`.

- Lake path: `Bronze/etoro/Hedge/HBCAccountConfiguration`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.HBCAccountConfiguration`
- 9 of 13 columns inherited; 4 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LiquidityAccountID | INT | YES | FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account these execution parameters apply to. Part of 3-column composite PK. 14 distinct accounts configured (Tier 2 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 1 | InstrumentID | INT | YES | FK to Trade.Instrument(InstrumentID). The instrument these execution parameters apply to. Part of 3-column composite PK. 10,458 distinct instruments configured (Tier 2 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 2 | ThresholdInEToroUnits | INT | YES | Order size tier boundary (in eToro units). Part of 3-column composite PK enabling tiered config. The HBC selects the row for orders at or below this threshold. 5 distinct values: 0, 5,271, 110,462, 1,137,139, 200,000,000. Most rows (97%) use 200,000,000 (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 3 | MaxTimeMS | INT | YES | Maximum milliseconds to wait for an order to fill before timeout. Range: 0-25,000 in current data. Applied per-tier, per-instrument, per-account (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 4 | MaxRejectRetries | INT | YES | Maximum number of retry attempts when an order is rejected. Range: 0-10 in current data. Higher values = more persistent execution attempts (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 5 | MinOrderSizeInEToroUnits | DECIMAL | YES | Minimum order size in eToro units for this account/instrument/tier. Orders below this floor are not routed. NULL = no minimum applied (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 6 | MaxOrderSizeInEToroUnits | INT | YES | Maximum single-order execution size in eToro units. Orders exceeding this must be split. Controls individual order impact on the market (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 7 | UseExecutionRateWithSpread | BOOLEAN | YES | Whether the execution rate calculation includes the bid-ask spread. 1=include spread (12,723 rows), 0=exclude spread (20,982 rows). Affects pricing calculation for execution rate benchmarking (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 8 | MinOrderSizeUSDForHBC | DECIMAL | YES | Minimum order size in USD for HBC routing. DEFAULT 0 = no USD minimum. Provides a USD-denominated floor in addition to the eToro units floor (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration). |
| 9 | SysStartTime | TIMESTAMP | YES | Source: etoro.Hedge.HBCAccountConfiguration.SysStartTime. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | SysEndTime | TIMESTAMP | YES | Source: etoro.Hedge.HBCAccountConfiguration.SysEndTime. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | DbLoginName | STRING | YES | Source: etoro.Hedge.HBCAccountConfiguration.DbLoginName. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | AppLoginName | STRING | YES | Source: etoro.Hedge.HBCAccountConfiguration.AppLoginName. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.HBCAccountConfiguration` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.HBCAccountConfiguration
        │
        ▼
main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration   ←── this object
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
| LiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| ThresholdInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| MaxTimeMS | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| MaxRejectRetries | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| MinOrderSizeInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| MaxOrderSizeInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| UseExecutionRateWithSpread | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| MinOrderSizeUSDForHBC | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.HBCAccountConfiguration) |
| SysStartTime | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` but column `SysStartTime` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SysEndTime | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` but column `SysEndTime` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| DbLoginName | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` but column `DbLoginName` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AppLoginName | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md` but column `AppLoginName` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 4 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
