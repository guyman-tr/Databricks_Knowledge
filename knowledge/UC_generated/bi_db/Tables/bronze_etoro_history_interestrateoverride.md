---
object_fqn: main.bi_db.bronze_etoro_history_interestrateoverride
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_interestrateoverride
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.InterestRateOverride
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md
  source_database: etoro
  source_schema: History
  source_table: InterestRateOverride
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/InterestRateOverride
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

# bronze_etoro_history_interestrateoverride

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.InterestRateOverride`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_interestrateoverride` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Nov 17 08:18:11 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.InterestRateOverride` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md`.

- Lake path: `Bronze/etoro/History/InterestRateOverride`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.InterestRateOverride`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InterestRateOverrideID | INT | YES | Surrogate PK for the override record. IDENTITY(1,1) in the live table. Uniquely identifies each override rule (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 1 | InstrumentID | INT | YES | Specific instrument this override applies to. NULL = override is not instrument-specific. FK to Trade.Instrument in the live table. When NOT NULL, this is the highest-priority override scope (Tier 2 — inherited from etoro.History.InterestRateOverride). |
| 2 | ExchangeID | INT | YES | Specific exchange this override applies to. NULL = not exchange-specific. When InstrumentID is NULL but ExchangeID is NOT NULL, applies to all instruments on that exchange (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 3 | InstrumentTypeID | INT | YES | Instrument type this override applies to. NULL = not type-specific (would be a catch-all). When both InstrumentID and ExchangeID are NULL, applies to all instruments of this type (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 4 | UpdatedByUser | STRING | YES | Username of operator or service that set this override. NOT NULL - always attributed to a user or automated process (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 5 | InterestRateBuy | DECIMAL | YES | Override market benchmark rate for long buy positions. Replaces the default InterestRate.InterestRateBuy for matched instruments. Negative values mean customer receives overnight credit on long positions (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 6 | InterestRateSell | DECIMAL | YES | Override market benchmark rate for short sell positions. Replaces the default rate for matched instruments (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 7 | MarkupBuy | DECIMAL | YES | eToro markup applied on top of InterestRateBuy for buy positions in this override (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 8 | MarkupSell | DECIMAL | YES | eToro markup applied on top of InterestRateSell for sell positions in this override. Negative values reduce the effective sell rate (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 9 | BeginTime | TIMESTAMP | YES | UTC timestamp when this override became active in Dictionary.InterestRateOverride (non-standard name for SysStartTime) (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 10 | EndTime | TIMESTAMP | YES | UTC timestamp when this override was superseded (non-standard name for SysEndTime) (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 11 | OverNightFeePatternID | INT | YES | Fee pattern for this override: 0=Regular, 1=WithNonLeverageFee, 2=Manual. Nullable - when NULL, inherits pattern from the base InterestRate table (Tier 1 — inherited from etoro.History.InterestRateOverride). |
| 12 | SettlementTypeID | INT | YES | Settlement type this override applies to: 0=CFD, 1=REAL, 2=TRS, etc. DEFAULT 0 = CFD. (Dictionary.SettlementTypes) (Tier 1 — inherited from etoro.History.InterestRateOverride). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.InterestRateOverride` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.InterestRateOverride
        │
        ▼
main.bi_db.bronze_etoro_history_interestrateoverride   ←── this object
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
| InterestRateOverrideID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| ExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| InstrumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| UpdatedByUser | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| InterestRateBuy | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| InterestRateSell | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| MarkupBuy | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| MarkupSell | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| BeginTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| EndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| OverNightFeePatternID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |
| SettlementTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InterestRateOverride) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
