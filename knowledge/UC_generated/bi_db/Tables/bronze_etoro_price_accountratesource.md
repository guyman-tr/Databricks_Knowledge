---
object_fqn: main.bi_db.bronze_etoro_price_accountratesource
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_price_accountratesource
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:12:49Z'
upstreams:
- etoro.Price.AccountRateSource
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md
  source_database: etoro
  source_schema: Price
  source_table: AccountRateSource
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Price/AccountRateSource
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 6
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_price_accountratesource

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Price.AccountRateSource`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_price_accountratesource` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 22 15:12:03 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Price.AccountRateSource` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md`.

- Lake path: `Bronze/etoro/Price/AccountRateSource`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Price.AccountRateSource`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountRateSourceID | INT | YES | Primary key. Integer identifier for a price data source. Negative values (-1) are valid special cases. ID 0 = deprecated. IDs 1-6 = simulation feeds. IDs 9001-9006 = FIX protocol connections. IDs 100000+ = large-numbered OMS/institutional feeds (Tier 1 — inherited from etoro.Price.AccountRateSource). |
| 1 | Name | STRING | YES | Human-readable name of the price source. Used in operations tooling, configuration UIs, and monitoring dashboards. Naming conventions reveal type: "Simulation" = demo feed, "FIX_" prefix = FIX protocol, "Bloomberg" = Bloomberg variants, provider names (ZBFX, Xignite, QuantHouse, etc.) = external vendors (Tier 1 — inherited from etoro.Price.AccountRateSource). |
| 2 | DbLoginName | STRING | YES | Computed column: captures the SQL Server login name of the user/service account that last modified this row. Set automatically by SQL Server on every DML operation; cannot be overridden by callers. Used for DB-level audit tracking (Tier 1 — inherited from etoro.Price.AccountRateSource). |
| 3 | AppLoginName | STRING | YES | Computed column: captures the application-level identity via SQL Server context_info(). Populated when the calling application sets context_info before executing DML (e.g., the pricing management service sets its service name). NULL when context_info is not set. Used for app-level audit tracking alongside DbLoginName (Tier 1 — inherited from etoro.Price.AccountRateSource). |
| 4 | SysStartTime | TIMESTAMP | YES | Temporal row validity start: timestamp when this version of the row became current. Auto-managed by SQL Server temporal table mechanism. Used with SysEndTime to query point-in-time states of the table via FOR SYSTEM_TIME AS OF (Tier 1 — inherited from etoro.Price.AccountRateSource). |
| 5 | SysEndTime | TIMESTAMP | YES | Temporal row validity end: '9999-12-31...' = currently active row. When a row is updated, its current version's SysEndTime is set to now, and a new version starts. Historical versions are in History.AccountRateSource (Tier 1 — inherited from etoro.Price.AccountRateSource). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Price.AccountRateSource` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Price.AccountRateSource
        │
        ▼
main.bi_db.bronze_etoro_price_accountratesource   ←── this object
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
| AccountRateSourceID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.AccountRateSource) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
