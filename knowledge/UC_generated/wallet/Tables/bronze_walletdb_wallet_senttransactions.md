---
object_fqn: main.wallet.bronze_walletdb_wallet_senttransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_senttransactions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T12:08:07Z'
upstreams:
- WalletDB.Wallet.SentTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: SentTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/SentTransactions
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

# bronze_walletdb_wallet_senttransactions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.SentTransactions`). 8 of 11 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_senttransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:17:58 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.SentTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md`.

- Lake path: `Bronze/WalletDB/Wallet/SentTransactions`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.SentTransactions`
- 8 of 11 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 1 | BlockchainTransactionId | STRING | YES | The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP) (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 2 | WalletId | STRING | YES | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 3 | Occurred | TIMESTAMP | YES | Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 4 | CorrelationId | STRING | YES | Links to the parent request in Wallet.Requests.CorrelationId. Enables tracing from business request to on-chain transaction. NULL for pre-correlation-era transactions (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 5 | TransactionTypeId | INT | YES | Business purpose: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. See [Transaction Type](../../_glossary.md#transaction-type). FK to Dictionary.TransactionTypes (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 6 | BlockchainFee | DECIMAL | YES | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 7 | CryptoId | INT | YES | The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId for per-wallet per-crypto transaction history queries (Tier 3 — inherited from WalletDB.Wallet.SentTransactions). |
| 8 | etr_y | INT | YES | Source: WalletDB.Wallet.SentTransactions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ym | STRING | YES | Source: WalletDB.Wallet.SentTransactions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.SentTransactions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.SentTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.SentTransactions
        │
        ▼
main.wallet.bronze_walletdb_wallet_senttransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| BlockchainTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| TransactionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| BlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
