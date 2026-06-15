---
object_fqn: main.wallet.bronze_walletdb_wallet_fiattypes
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_fiattypes
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:08:05Z'
upstreams:
- WalletDB.Wallet.FiatTypes
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: FiatTypes
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/FiatTypes
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_fiattypes

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.FiatTypes`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_fiattypes` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:21:28 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.FiatTypes` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md`.

- Lake path: `Bronze/WalletDB/Wallet/FiatTypes`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.FiatTypes`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Auto-incrementing surrogate primary key within WalletDB. Used as FK target by Wallet.Payments (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 1 | FiatId | INT | YES | Business identifier for the fiat currency used across eToro platform systems. Unique constraint (UQ_Wallet_FiatTypes_FiatId). Values: 1=USD, 2=EUR, 3=GBP, 5=AUD. Referenced by Wallet.FiatMarketRatesMappings as FK (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 2 | FiatName | STRING | YES | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP, AUD). Unique constraint enforced. Used for display and API parameter matching (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 3 | IsActive | BOOLEAN | YES | Whether this fiat currency is currently available for crypto operations. All current entries are active (1). Setting to 0 would disable conversions and payments in this currency (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 4 | AvatarUrl | STRING | YES | URL to the currency's display icon hosted on S3. Used in the eToro wallet UI for visual identification of fiat currencies (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 5 | Precision | INT | YES | Number of decimal places used when displaying and calculating amounts in this currency. All current currencies use 5 decimal places for precision in conversion calculations (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 6 | InstrumentId | INT | YES | Links to the eToro trading platform instrument representing the exchange rate for this fiat vs USD. NULL for USD (base currency). EUR=1, GBP=2, AUD=7. Used to fetch real-time exchange rates for crypto-to-fiat conversions. Implicit reference to Wallet.Instruments (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |
| 7 | NumericCode | INT | YES | ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR, 826=GBP, 36=AUD). Used for standardized integrations with payment providers and regulatory reporting (Tier 3 — inherited from WalletDB.Wallet.FiatTypes). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.FiatTypes` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.FiatTypes
        │
        ▼
main.wallet.bronze_walletdb_wallet_fiattypes   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| FiatId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| FiatName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| AvatarUrl | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| Precision | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| InstrumentId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |
| NumericCode | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.FiatTypes) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
