---
object_fqn: main.wallet.bronze_walletdb_wallet_paymenttransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_paymenttransactions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 17
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.PaymentTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: PaymentTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/PaymentTransactions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 6
  unverified_columns: 0
---

# bronze_walletdb_wallet_paymenttransactions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.PaymentTransactions`). 11 of 17 columns inherited from Tier 1 source wiki; 6 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_paymenttransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 17 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 01 12:12:02 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.PaymentTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`.

- Lake path: `Bronze/WalletDB/Wallet/PaymentTransactions`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.PaymentTransactions`
- 11 of 17 columns inherited; 6 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 1 | PaymentId | LONG | YES | Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 2 | ExchangeRate | DECIMAL | YES | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 3 | ToAddress | STRING | YES | Blockchain destination address for the purchased crypto (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 4 | Amount | DECIMAL | YES | Amount of crypto being purchased/transferred (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 5 | EtoroFeePercentage | DECIMAL | YES | eToro service fee as a percentage (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 6 | EtoroFeeCalculated | DECIMAL | YES | Calculated eToro fee in crypto units (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 7 | ProviderFeePercentage | DECIMAL | YES | Payment provider's fee as a percentage (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 8 | ProviderFeeCalculated | DECIMAL | YES | Calculated provider fee in crypto units (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 9 | EstimatedBlockChainFee | DECIMAL | YES | Estimated blockchain network fee (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 10 | Occurred | TIMESTAMP | YES | Timestamp of record creation (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions). |
| 11 | etr_y2 | STRING | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_y2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | etr_ym2 | STRING | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_ym2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | etr_ymd2 | STRING | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_ymd2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 14 | etr_y | INT | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 15 | etr_ym | STRING | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 16 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.PaymentTransactions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.PaymentTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.PaymentTransactions
        │
        ▼
main.wallet.bronze_walletdb_wallet_paymenttransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| PaymentId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| ToAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| EtoroFeePercentage | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| EtoroFeeCalculated | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| ProviderFeePercentage | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| ProviderFeeCalculated | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| EstimatedBlockChainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.PaymentTransactions) |
| etr_y2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_y2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_ym2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_ymd2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 6 TN, 0 U | Elements: 17/17 | Source: bronze_tier1_inheritance*
