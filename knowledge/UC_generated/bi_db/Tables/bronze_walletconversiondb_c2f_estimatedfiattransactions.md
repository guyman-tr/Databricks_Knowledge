---
object_fqn: main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T12:13:09Z'
upstreams:
- WalletConversionDB.C2F.EstimatedFiatTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md
  source_database: WalletConversionDB
  source_schema: C2F
  source_table: EstimatedFiatTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletConversionDB/C2F/EstimatedFiatTransactions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletconversiondb_c2f_estimatedfiattransactions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletConversionDB.C2F.EstimatedFiatTransactions`). 8 of 11 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Mar 21 13:14:30 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletConversionDB.C2F.EstimatedFiatTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md`.

- Lake path: `Bronze/WalletConversionDB/C2F/EstimatedFiatTransactions`
- Copy strategy: `Append`
- Source database: `WalletConversionDB` (`CryptoDBs`)
- Source schema/table: `C2F.EstimatedFiatTransactions`
- 8 of 11 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate PK (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 1 | ConversionId | LONG | YES | FK to C2F.Conversions.Id. 1:1 relationship - every conversion gets exactly one estimated fiat record. Created atomically by InsertConversion (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 2 | FiatAmount | DECIMAL | YES | Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments) (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 3 | UsdAmount | DECIMAL | YES | Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 4 | CryptoToUsdRate | DECIMAL | YES | Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 5 | FiatToUsdRate | DECIMAL | YES | Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 6 | CryptoToFiatRate | DECIMAL | YES | Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 7 | Occurred | TIMESTAMP | YES | UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions). |
| 8 | etr_y | INT | YES | Source: WalletConversionDB.C2F.EstimatedFiatTransactions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ym | STRING | YES | Source: WalletConversionDB.C2F.EstimatedFiatTransactions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ymd | DATE | YES | Source: WalletConversionDB.C2F.EstimatedFiatTransactions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletConversionDB.C2F.EstimatedFiatTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletConversionDB.C2F.EstimatedFiatTransactions
        │
        ▼
main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| ConversionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| FiatAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| UsdAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| CryptoToUsdRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| FiatToUsdRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| CryptoToFiatRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.EstimatedFiatTransactions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
