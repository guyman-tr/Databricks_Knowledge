---
object_fqn: main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:12:45Z'
upstreams:
- etoro.Hedge.AccountInstrumentConfiguration
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md
  source_database: etoro
  source_schema: Hedge
  source_table: AccountInstrumentConfiguration
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/AccountInstrumentConfiguration
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_hedge_accountinstrumentconfiguration

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.AccountInstrumentConfiguration`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Fri Mar 14 04:16:15 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.AccountInstrumentConfiguration` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md`.

- Lake path: `Bronze/etoro/Hedge/AccountInstrumentConfiguration`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.AccountInstrumentConfiguration`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountID | INT | YES | The hedge account this configuration applies to. Part of composite PK. Implicit reference to Hedge.Accounts.ID (no FK constraint). Values present: 1, 10 (ZBFX Price2), 308 (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 1 | InstrumentID | INT | YES | The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). InstrumentIDs range into the 1,000,000+ range (OMS/platform instruments) (Tier 2 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 2 | MaxExecutionUnitsThreshold | INT | YES | Maximum single hedge order size (in execution units) before band-based sizing logic applies. Currently NULL for all rows - feature designed but not active (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 3 | MaxExecutionUnitsUpperBound | INT | YES | Upper bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 4 | MaxExecutionUnitsLowerBound | INT | YES | Lower bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 5 | ExecutionUnitsStep | INT | YES | Step granularity for execution unit sizing increments. Currently NULL (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 6 | MaxRequestedPerInterval | INT | YES | Rate limit: maximum number of orders allowed within IntervalPeriodSeconds. Currently NULL for all rows - rate limiting not active (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 7 | IntervalPeriodSeconds | INT | YES | Time window in seconds for the MaxRequestedPerInterval rate limit. Currently NULL (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 8 | LimitRoundPrecision | INT | YES | Number of decimal places for limit order price rounding for this account/instrument pair. -1=no override (use default). Active values: 1, 2, 4. Determines tick-size compliance for limit orders submitted to providers (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 9 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 10 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for current rows. History in History.AccountInstrumentConfiguration (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 11 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |
| 12 | AppLoginName | STRING | YES | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.AccountInstrumentConfiguration` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.AccountInstrumentConfiguration
        │
        ▼
main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration   ←── this object
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
| AccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| MaxExecutionUnitsThreshold | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| MaxExecutionUnitsUpperBound | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| MaxExecutionUnitsLowerBound | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| ExecutionUnitsStep | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| MaxRequestedPerInterval | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| IntervalPeriodSeconds | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| LimitRoundPrecision | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.AccountInstrumentConfiguration) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
