---
object_fqn: main.bi_db.bronze_etoro_dictionary_interestrateoverride
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_dictionary_interestrateoverride
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:12:45Z'
upstreams:
- etoro.Dictionary.InterestRateOverride
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md
  source_database: etoro
  source_schema: Dictionary
  source_table: InterestRateOverride
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Dictionary/InterestRateOverride
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

# bronze_etoro_dictionary_interestrateoverride

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Dictionary.InterestRateOverride`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_dictionary_interestrateoverride` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Nov 17 08:17:45 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Dictionary.InterestRateOverride` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md`.

- Lake path: `Bronze/etoro/Dictionary/InterestRateOverride`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Dictionary.InterestRateOverride`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InterestRateOverrideID | INT | YES | Auto-incrementing primary key. Uniquely identifies each override rule. Referenced by Trade.UpdateInterestRateOverride and Trade.DeleteInterestRateOverride (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 1 | InstrumentID | INT | YES | Specific instrument to override (most specific level). NULL when override targets an exchange or type. FK to Dictionary.Currency.InstrumentID (Tier 2 — inherited from etoro.Dictionary.InterestRateOverride). |
| 2 | ExchangeID | INT | YES | Exchange to override (mid-level specificity). NULL when override targets a specific instrument or type. FK to Dictionary.ExchangeInfo (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 3 | InstrumentTypeID | INT | YES | Instrument type to override (broadest level). NULL when override targets a specific instrument or exchange. FK to Dictionary.CurrencyType. 1=Forex, 2=Commodities, 3=Indices, 4=Indices, 5=Stocks, 10=Crypto (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 4 | UpdatedByUser | STRING | YES | Username of the operations staff member who created or last modified this override. Used for audit trail and accountability (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 5 | InterestRateBuy | DECIMAL | YES | Base overnight interest rate for long (buy) positions. Positive = customer pays, negative = customer receives. Combined with MarkupBuy for final rate (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 6 | InterestRateSell | DECIMAL | YES | Base overnight interest rate for short (sell) positions. Positive = customer pays, negative = customer receives. Combined with MarkupSell for final rate (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 7 | MarkupBuy | DECIMAL | YES | eToro's markup percentage on the buy (long) overnight rate. Added to InterestRateBuy to determine the customer-facing rate. Represents eToro's revenue component (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 8 | MarkupSell | DECIMAL | YES | eToro's markup percentage on the sell (short) overnight rate. Added to InterestRateSell to determine the customer-facing rate (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 9 | BeginTime | TIMESTAMP | YES | System-versioned row start time. Generated automatically by SQL Server. Indicates when this version of the override became active (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 10 | EndTime | TIMESTAMP | YES | System-versioned row end time. Generated automatically. Current rows have 9999-12-31 23:59:59.999. Historical rows have the timestamp of the next modification (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 11 | OverNightFeePatternID | INT | YES | Fee charging pattern for this override. FK to Dictionary.OverNightFeePattern. Determines on which days/how fees are charged (e.g., daily, triple Wednesday, weekday-only). NULL = use default pattern (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |
| 12 | SettlementTypeID | INT | YES | Settlement model for this override. FK to Dictionary.SettlementTypes. 0=default/any, 1=CFD, 2=Real, 3=DMA, 4=Indices, 5=TRS. Allows different rates per settlement type. Default: 0 (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Dictionary.InterestRateOverride` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Dictionary.InterestRateOverride
        │
        ▼
main.bi_db.bronze_etoro_dictionary_interestrateoverride   ←── this object
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
| InterestRateOverrideID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| ExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| InstrumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| UpdatedByUser | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| InterestRateBuy | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| InterestRateSell | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| MarkupBuy | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| MarkupSell | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| BeginTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| EndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| OverNightFeePatternID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |
| SettlementTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Dictionary.InterestRateOverride) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
