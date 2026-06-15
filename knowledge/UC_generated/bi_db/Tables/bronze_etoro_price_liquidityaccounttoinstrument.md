---
object_fqn: main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:49Z'
upstreams:
- etoro.Price.LiquidityAccountToInstrument
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md
  source_database: etoro
  source_schema: Price
  source_table: LiquidityAccountToInstrument
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Price/LiquidityAccountToInstrument
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

# bronze_etoro_price_liquidityaccounttoinstrument

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Price.LiquidityAccountToInstrument`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Feb 14 14:14:46 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Price.LiquidityAccountToInstrument` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md`.

- Lake path: `Bronze/etoro/Price/LiquidityAccountToInstrument`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Price.LiquidityAccountToInstrument`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LiquidityAccountID | INT | YES | Liquidity account identifier. Part of the composite PK (primary sort key). FK to Trade.LiquidityAccounts. Represents a price feed connection (e.g., a specific Bloomberg feed, FIX session, or internal price source). Clustered PK sorts by account first, enabling fast "all instruments for this account" lookups (Tier 2 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 1 | InstrumentID | INT | YES | eToro instrument identifier. Part of the composite PK. FK to Trade.Instrument. NC index on InstrumentID alone enables fast reverse lookup: "all eligible accounts for this instrument." (Tier 2 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 2 | DbLoginName | STRING | YES | Computed: SQL Server login of last row modifier. Auto-set by SQL Server on every DML. Used for DB-level audit tracking (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 3 | AppLoginName | STRING | YES | Computed: application identity from context_info(). Populated when the calling service sets context_info before DML. NULL when not set (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 4 | SysStartTime | TIMESTAMP | YES | Temporal row validity start. Auto-managed by SQL Server system versioning. Enables point-in-time configuration queries (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 5 | SysEndTime | TIMESTAMP | YES | Temporal row validity end. Historical versions in History.LiquidityAccountToInstrument (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument). |
| 6 | HostName | STRING | YES | Computed: DB server hostname that processed the last DML on this row. Unusual column - captures the server host rather than user. Relevant in distributed/replicated environments to trace which server wrote a given mapping (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Price.LiquidityAccountToInstrument` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Price.LiquidityAccountToInstrument
        │
        ▼
main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument   ←── this object
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
| LiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |
| HostName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.LiquidityAccountToInstrument) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
