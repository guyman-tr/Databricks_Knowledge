---
object_fqn: main.wallet.bronze_walletdb_wallet_receivedtransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_receivedtransactions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 19
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.ReceivedTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: ReceivedTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/ReceivedTransactions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 16
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_receivedtransactions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.ReceivedTransactions`). 16 of 19 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_receivedtransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 19 |
| **Generated** | 2026-05-19 |
| **Created** | Tue May 27 04:16:16 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.ReceivedTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md`.

- Lake path: `Bronze/WalletDB/Wallet/ReceivedTransactions`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.ReceivedTransactions`
- 16 of 19 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key. FK target for Wallet.ReceivedTransactionStatuses (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 1 | Occurred | TIMESTAMP | YES | Timestamp when this received transaction was detected and recorded by the system (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 2 | WalletId | STRING | YES | The eToro wallet that received the funds. FK to Wallet.WalletPool.WalletId. Used to identify the owning customer (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 3 | SenderAddress | STRING | YES | The blockchain address that sent the funds. NULL when the sender cannot be determined (e.g., coinbase transactions). Used for AML screening (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 4 | ReceiverAddress | STRING | YES | The specific blockchain address within the wallet that received the funds. A wallet may have multiple addresses (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 5 | Amount | DECIMAL | YES | Amount of crypto received in native units. NULL for zero-value transactions (e.g., token approvals) (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 6 | BlockchainFee | DECIMAL | YES | Network fee associated with this incoming transaction. Usually the sender's fee, recorded for reference (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 7 | CorrelationId | STRING | YES | Links to the parent request in Wallet.Requests.CorrelationId for system-initiated receives (redemptions, conversions). NULL for unexpected external deposits (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 8 | BlockchainTransactionId | STRING | YES | On-chain transaction hash. Format varies by blockchain (0x-prefixed hex for ETH, base58 for SOL, uppercase hex for XRP). Used for blockchain explorer lookups (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 9 | BlockchainTransactionDate | TIMESTAMP | YES | Timestamp of the transaction on the blockchain itself (block time). May differ from Occurred which is when the system detected it (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 10 | CryptoId | INT | YES | The cryptocurrency received. FK to Wallet.CryptoTypes.CryptoID (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 11 | ReceivedTransactionTypeId | INT | YES | Business classification: 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. See [Received Transaction Type](../../_glossary.md#received-transaction-type). FK to Dictionary.ReceivedTransactionTypes. Default 1 (MoneyIn) (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 12 | NormalizedSenderAddress | STRING | YES | Computed PERSISTED column stripping protocol prefix and query parameters from SenderAddress for consistent matching (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 13 | NormalizedReceiverAddress | STRING | YES | Computed PERSISTED column stripping protocol prefix and query parameters from ReceiverAddress for consistent matching (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 14 | ProviderTransactionId | STRING | YES | Transaction identifier assigned by the custody provider (BitGo/CUG). May differ from the blockchain hash. Used for provider API reconciliation (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 15 | ReceiveRequestCorrelationId | STRING | YES | Links to a ReceiveTransaction request (RequestTypeId=8) when the incoming transaction is processed as a formal request. Distinct from CorrelationId which links to the originating request (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactions). |
| 16 | etr_y | INT | YES | Source: WalletDB.Wallet.ReceivedTransactions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 17 | etr_ym | STRING | YES | Source: WalletDB.Wallet.ReceivedTransactions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 18 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.ReceivedTransactions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.ReceivedTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.ReceivedTransactions
        │
        ▼
main.wallet.bronze_walletdb_wallet_receivedtransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| SenderAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| ReceiverAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| BlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| BlockchainTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| BlockchainTransactionDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| ReceivedTransactionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| NormalizedSenderAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| NormalizedReceiverAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| ProviderTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| ReceiveRequestCorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 16 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 19/19 | Source: bronze_tier1_inheritance*
