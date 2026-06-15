---
object_fqn: main.bi_db.bronze_walletconversiondb_c2f_conversions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletconversiondb_c2f_conversions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:13:08Z'
upstreams:
- WalletConversionDB.C2F.Conversions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md
  source_database: WalletConversionDB
  source_schema: C2F
  source_table: Conversions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletConversionDB/C2F/Conversions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletconversiondb_c2f_conversions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletConversionDB.C2F.Conversions`). 9 of 12 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletconversiondb_c2f_conversions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Mar 21 13:14:09 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletConversionDB.C2F.Conversions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md`.

- Lake path: `Bronze/WalletConversionDB/C2F/Conversions`
- Copy strategy: `Append`
- Source database: `WalletConversionDB` (`CryptoDBs`)
- Source schema/table: `C2F.Conversions`
- 9 of 12 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK (Tier 3 — inherited from WalletConversionDB.C2F.Conversions). |
| 1 | Gcid | LONG | YES | Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum) (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 2 | TargetPlatformId | INT | YES | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount (77%), 2=EtoroPlatform (6%), 3=EtoroPosition (17%). See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 3 | CryptoId | INT | YES | Crypto asset identifier (external reference). Identifies which cryptocurrency is being sold. Values observed: 4, 64, 107 (likely mapped to assets like BTC, ETH, etc. in an external system) (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 4 | FiatId | INT | YES | Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR) (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 5 | CryptoAmount | DECIMAL | YES | Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 6 | ConversionFeePercentage | DECIMAL | YES | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions (Tier 1 — inherited from WalletConversionDB.C2F.Conversions). |
| 7 | CorrelationId | STRING | YES | Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id (Tier 3 — inherited from WalletConversionDB.C2F.Conversions). |
| 8 | Occurred | TIMESTAMP | YES | UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter (Tier 3 — inherited from WalletConversionDB.C2F.Conversions). |
| 9 | etr_y | INT | YES | Source: WalletConversionDB.C2F.Conversions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ym | STRING | YES | Source: WalletConversionDB.C2F.Conversions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | etr_ymd | DATE | YES | Source: WalletConversionDB.C2F.Conversions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletConversionDB.C2F.Conversions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletConversionDB.C2F.Conversions
        │
        ▼
main.bi_db.bronze_walletconversiondb_c2f_conversions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| TargetPlatformId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| FiatId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| CryptoAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| ConversionFeePercentage | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.Conversions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
