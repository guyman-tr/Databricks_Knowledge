---
object_fqn: main.wallet.bronze_walletdb_wallet_redemptions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_redemptions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 20
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.Redemptions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: Redemptions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/Redemptions
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 17
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_redemptions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.Redemptions`). 17 of 20 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_redemptions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 20 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:18:40 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.Redemptions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md`.

- Lake path: `Bronze/WalletDB/Wallet/Redemptions`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.Redemptions`
- 17 of 20 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 1 | OriginalRequestGuid | STRING | YES | GUID of the original redemption request from the trading platform. Used for idempotency and cross-system correlation (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 2 | SendRequestCorrelationId | STRING | YES | Links to the send transaction request in Wallet.Requests.CorrelationId created when the blockchain transfer is initiated. NULL until the redemption reaches the execution stage (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 3 | PositionId | LONG | YES | Trading platform position being redeemed. Unique constraint - each position can only be redeemed once. NULL only for legacy records (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 4 | RequestingGcid | LONG | YES | Global Customer ID of the customer requesting the redemption (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 5 | CryptoId | INT | YES | The cryptocurrency being redeemed. Implicit reference to Wallet.CryptoTypes.CryptoID (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 6 | RequestedAmount | DECIMAL | YES | Gross amount of crypto requested for redemption. In native units of CryptoId (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 7 | eToroFeeAmount | DECIMAL | YES | eToro's service fee deducted from the redemption. Typically ~2% of RequestedAmount (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 8 | RedemptionStatus | INT | YES | Lifecycle status: 0=Persisted, 1=Retrieved, 2=SentToExecuter, 3=SuccessReported, 4=FailureReported. See [Redemption Status](../../_glossary.md#redemption-status). FK to Dictionary.RedemptionStatus (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 9 | BillingTransId | LONG | YES | Transaction ID in the billing/accounting system for the fee charge (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 10 | BillingRedeemId | LONG | YES | Redemption ID in the billing/accounting system (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 11 | BeginDate | TIMESTAMP | YES | System-versioned temporal column (ROW START) (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 12 | EndDate | TIMESTAMP | YES | System-versioned temporal column (ROW END) (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 13 | EstimatedBlockchainFee | DECIMAL | YES | Estimated network fee for the blockchain transfer. Calculated before execution based on current network conditions (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 14 | InitialFeeAmount | DECIMAL | YES | Fixed base fee charged regardless of amount. Defaults to 0 for most cryptos (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 15 | SourceWalletId | STRING | YES | The omnibus/system wallet from which the crypto is sent to the customer. FK to Wallet.Wallets.WalletId. NULL for legacy records (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 16 | TransactionTypeId | INT | YES | Type of sent transaction created: typically 0 (Redeem) or 8 (RedeemAsic). FK to Dictionary.TransactionTypes. See [Transaction Type](../../_glossary.md#transaction-type) (Tier 3 — inherited from WalletDB.Wallet.Redemptions). |
| 17 | etr_y | INT | YES | Source: WalletDB.Wallet.Redemptions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 18 | etr_ym | STRING | YES | Source: WalletDB.Wallet.Redemptions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 19 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.Redemptions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.Redemptions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.Redemptions
        │
        ▼
main.wallet.bronze_walletdb_wallet_redemptions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| OriginalRequestGuid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| SendRequestCorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| PositionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| RequestingGcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| RequestedAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| eToroFeeAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| RedemptionStatus | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| BillingTransId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| BillingRedeemId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| BeginDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| EndDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| EstimatedBlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| InitialFeeAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| SourceWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| TransactionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Redemptions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 17 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 20/20 | Source: bronze_tier1_inheritance*
