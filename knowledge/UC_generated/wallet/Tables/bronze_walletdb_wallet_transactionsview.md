---
object_fqn: main.wallet.bronze_walletdb_wallet_transactionsview
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_transactionsview
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 22
row_count: null
generated_at: '2026-05-19T12:08:07Z'
upstreams:
- WalletDB.Wallet.TransactionsView
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: TransactionsView
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/TransactionsView
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 22
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_transactionsview

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.TransactionsView`). 22 of 22 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_transactionsview` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 22 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jan 12 11:15:24 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.TransactionsView` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md`.

- Lake path: `Bronze/WalletDB/Wallet/TransactionsView`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.TransactionsView`
- 22 of 22 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | gcid | LONG | YES | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 1 | CryptoId | INT | YES | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 2 | WalletId | STRING | YES | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 3 | TranID | LONG | YES | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 4 | TransStatusId | INT | YES | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 5 | TransStatus | STRING | YES | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 6 | TransDate | TIMESTAMP | YES | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 7 | Amount | DECIMAL | YES | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 8 | EtoroFees | DECIMAL | YES | eToro platform fees. Source varies: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, Staking -> EtoroFee, Other -> SentTransactionOutputs.EtoroFees. NULL for receives (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 9 | ProviderFees | DECIMAL | YES | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 10 | FeeExchangeRate | DECIMAL | YES | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 11 | BlockchainFee | DECIMAL | YES | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 12 | EffectiveBlockchainFee | DECIMAL | YES | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 13 | ActionTypeId | INT | YES | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 14 | ActionTypeName | STRING | YES | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility) (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 15 | SenderAddress | STRING | YES | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender) (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 16 | ReciverAddress | STRING | YES | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 17 | BlockchainTransactionId | STRING | YES | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 18 | TransactionTypeId | INT | YES | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 19 | TransactionType | STRING | YES | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 20 | Occurred | TIMESTAMP | YES | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |
| 21 | LastStatusUpdateOccurred | TIMESTAMP | YES | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld) (Tier 1 — inherited from WalletDB.Wallet.TransactionsView). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.TransactionsView` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.TransactionsView
        │
        ▼
main.wallet.bronze_walletdb_wallet_transactionsview   ←── this object
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
| gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TranID | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TransStatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TransStatus | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TransDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| EtoroFees | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| ProviderFees | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| FeeExchangeRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| BlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| EffectiveBlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| ActionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| ActionTypeName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| SenderAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| ReciverAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| BlockchainTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TransactionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| TransactionType | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |
| LastStatusUpdateOccurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionsView) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 22 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 22/22 | Source: bronze_tier1_inheritance*
