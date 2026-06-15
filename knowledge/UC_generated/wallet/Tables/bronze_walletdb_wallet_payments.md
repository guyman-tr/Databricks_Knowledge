---
object_fqn: main.wallet.bronze_walletdb_wallet_payments
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_payments
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 14
row_count: null
generated_at: '2026-05-19T12:08:05Z'
upstreams:
- WalletDB.Wallet.Payments
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: Payments
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/Payments
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 6
  unverified_columns: 0
---

# bronze_walletdb_wallet_payments

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.Payments`). 8 of 14 columns inherited from Tier 1 source wiki; 6 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_payments` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 14 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 01 12:19:51 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.Payments` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md`.

- Lake path: `Bronze/WalletDB/Wallet/Payments`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.Payments`
- 8 of 14 columns inherited; 6 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key. FK target for Wallet.PaymentStatuses, Wallet.PaymentTransactions, and Wallet.Chargebacks (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 1 | WalletId | STRING | YES | The customer's wallet receiving the purchased crypto. FK to Wallet.Wallets.WalletId (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 2 | ProviderPaymentId | STRING | YES | Payment identifier assigned by the external payment provider. Used for reconciliation and provider API calls (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 3 | Amount | DECIMAL | YES | Fiat amount of the payment. Denominated in the currency specified by FiatId (e.g., 125 EUR) (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 4 | FiatId | INT | YES | The fiat currency used for payment: 1=USD, 2=EUR, 3=GBP, 5=AUD. FK to Wallet.FiatTypes.Id (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 5 | CorrelationId | STRING | YES | Links to the parent request in Wallet.Requests.CorrelationId (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 6 | Occurred | TIMESTAMP | YES | Timestamp when the payment was initiated (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 7 | CryptoId | INT | YES | The cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID (Tier 3 — inherited from WalletDB.Wallet.Payments). |
| 8 | etr_y2 | STRING | YES | Source: WalletDB.Wallet.Payments.etr_y2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ym2 | STRING | YES | Source: WalletDB.Wallet.Payments.etr_ym2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ymd2 | STRING | YES | Source: WalletDB.Wallet.Payments.etr_ymd2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | etr_y | INT | YES | Source: WalletDB.Wallet.Payments.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | etr_ym | STRING | YES | Source: WalletDB.Wallet.Payments.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.Payments.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.Payments` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.Payments
        │
        ▼
main.wallet.bronze_walletdb_wallet_payments   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| ProviderPaymentId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| FiatId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Payments) |
| etr_y2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_y2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_ym2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_ymd2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 6 TN, 0 U | Elements: 14/14 | Source: bronze_tier1_inheritance*
