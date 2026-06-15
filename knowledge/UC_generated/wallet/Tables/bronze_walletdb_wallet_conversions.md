---
object_fqn: main.wallet.bronze_walletdb_wallet_conversions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_conversions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 16
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Wallet.Conversions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: Conversions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/Conversions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 6
  unverified_columns: 0
---

# bronze_walletdb_wallet_conversions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.Conversions`). 10 of 16 columns inherited from Tier 1 source wiki; 6 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_conversions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 16 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 01 10:53:41 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.Conversions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md`.

- Lake path: `Bronze/WalletDB/Wallet/Conversions`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.Conversions`
- 10 of 16 columns inherited; 6 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 1 | FromWalletId | STRING | YES | The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 2 | ToWalletId | STRING | YES | The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 3 | ConversionTypeId | INT | YES | Determines pricing direction: 1=FixedFrom (sell amount fixed), 2=FixedTo (buy amount fixed). See [Conversion Type](../../_glossary.md#conversion-type). FK to Dictionary.ConversionTypes (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 4 | FromAmount | DECIMAL | YES | Amount of source crypto being sold. In native units of FromCryptoId (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 5 | ToAmount | DECIMAL | YES | Amount of destination crypto being purchased. In native units of ToCryptoId (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 6 | CorrelationId | STRING | YES | Links to the parent request in Wallet.Requests.CorrelationId (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 7 | Occurred | TIMESTAMP | YES | Timestamp when the conversion was initiated (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 8 | FromCryptoId | INT | YES | Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 9 | ToCryptoId | INT | YES | Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID (Tier 3 — inherited from WalletDB.Wallet.Conversions). |
| 10 | etr_y2 | STRING | YES | Source: WalletDB.Wallet.Conversions.etr_y2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | etr_ym2 | STRING | YES | Source: WalletDB.Wallet.Conversions.etr_ym2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | etr_ymd2 | STRING | YES | Source: WalletDB.Wallet.Conversions.etr_ymd2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | etr_y | INT | YES | Source: WalletDB.Wallet.Conversions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 14 | etr_ym | STRING | YES | Source: WalletDB.Wallet.Conversions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 15 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.Conversions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.Conversions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.Conversions
        │
        ▼
main.wallet.bronze_walletdb_wallet_conversions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| FromWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| ToWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| ConversionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| FromAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| ToAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| FromCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| ToCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Conversions) |
| etr_y2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_y2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_ym2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_ymd2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 6 TN, 0 U | Elements: 16/16 | Source: bronze_tier1_inheritance*
