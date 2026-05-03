# EXW_Wallet.ReceivedTransactions

> 2.5M-row staging table tracking every incoming cryptocurrency transaction received by eToroX wallets from September 2018 to present — capturing sender/receiver blockchain addresses, amounts, fees, crypto asset type, and transaction classification. Loaded via CopyFromLake Generic Pipeline (Append, 60-min) from WalletDB.Wallet.ReceivedTransactions. Production source: WalletDB (eToroX Wallet service).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.ReceivedTransactions (CopyFromLake Generic Pipeline) |
| **Refresh** | Every 60 minutes (Append strategy) |
| **Synapse Distribution** | HASH([Id]) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_receivedtransactions` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.ReceivedTransactions is a bronze-layer staging table that stores every incoming cryptocurrency transaction detected on eToroX wallet blockchain addresses. Each row represents a single received transaction — money arriving at a customer's or internal wallet from an external or internal sender.

The table contains 2,519,368 rows spanning from September 2018 to April 2026. It is loaded directly from the production WalletDB.Wallet.ReceivedTransactions table via the CopyFromLake Generic Pipeline with an Append strategy every 60 minutes. No writer stored procedure transforms this data — it is a direct replica of the production source.

This table is consumed downstream by:
- **SP_EXW_Fact_Transactions** — uses ReceivedTransactions to look up `ReceivedTransactionTypeId` and `Id` when building the unified EXW_FactTransactions fact table (ActionTypeId = 2 / received side).
- **SP_EXW_FactRedeemTransactions** — matches received transactions to sent transactions via `BlockchainTransactionId` to reconcile redeem flows, computing received amounts and blockchain fee allocations.
- **EXW_TransactionsView** — the `received_transactions` CTE reads this table to build a unified view of all wallet transactions (sent + received), filtering out self-receives where `NormalizedSenderAddress` belongs to the same wallet.

The `ReceivedTransactionTypeId` classifies transactions into 8 types: MoneyIn (48%), Redeem (44%), Funding, ConversionFromUser, ConversionFromEtoro, Payment, RedeemAsic, and StakeAndRewardsRefund. CryptoId 21 (Stellar-based) is the most common at 37% of all rows.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: Each received transaction is classified by its purpose via `ReceivedTransactionTypeId`.
**Columns Involved**: `ReceivedTransactionTypeId`
**Rules**:
- 1 = MoneyIn — external deposit into a wallet (48% of rows)
- 2 = Redeem — crypto redeemed back from a position (44% of rows)
- 3 = Funding — wallet funding operation
- 4 = ConversionFromUser — received crypto from a user-initiated conversion
- 5 = ConversionFromEtoro — received crypto from an eToro-initiated conversion
- 6 = Payment — received payment transaction
- 7 = RedeemAsic — ASIC-specific redemption
- 8 = StakeAndRewardsRefund — refund from staking/rewards operations

### 2.2 Self-Receive Filtering

**What**: Downstream consumers (EXW_TransactionsView) exclude self-receives where the sender and receiver belong to the same wallet.
**Columns Involved**: `NormalizedSenderAddress`, `NormalizedReceiverAddress`, `WalletId`
**Rules**:
- The view filters out rows where `NormalizedSenderAddress` is in the wallet's own address list (`EXW_Wallet.WalletAddresses`)
- SP_EXW_FactRedeemTransactions also filters `WHERE SenderAddress <> ReceiverAddress`

### 2.3 Blockchain Fee Allocation in Redeems

**What**: When multiple received transactions share the same `BlockchainTransactionId`, the blockchain fee is split across them.
**Columns Involved**: `BlockchainFee`, `BlockchainTransactionId`
**Rules**:
- SP_EXW_FactRedeemTransactions computes `BlockchainFee / COUNT(BlockchainTransactionId)` to allocate fees proportionally
- This handles UTXO-model blockchains where a single on-chain transaction can have multiple outputs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH([Id]) — queries filtering on `Id` are co-located on a single distribution
- HEAP storage (no clustered index) — full scans are common for this staging table
- For large analytical queries, filter by `partition_date` to limit scan scope

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| All received transactions for a wallet | `WHERE WalletId = '<guid>'` |
| Transactions by crypto type | `JOIN EXW_Wallet.CryptoTypes ON CryptoId` |
| Transactions by type (e.g., redeems) | `WHERE ReceivedTransactionTypeId = 2` |
| Recent transactions | `WHERE partition_date >= '2026-01-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Dictionary.ReceivedTransactionTypes | ReceivedTransactionTypeId = Id | Resolve transaction type name |
| EXW_Wallet.CryptoTypes | CryptoId = CryptoID | Resolve crypto asset name and metadata |
| EXW_Wallet.SentTransactions | BlockchainTransactionId = BlockchainTransactionId | Match sent-to-received for redeem reconciliation |
| EXW_Wallet.CustomerWalletsView | WalletId = Id | Resolve wallet owner (GCID) |
| EXW_Wallet.ReceivedTransactionStatuses | Id = ReceivedTransactionId | Get transaction status history |

### 3.4 Gotchas

- `etr_y`, `etr_ym`, `etr_ymd` are all NULL in current data — these ETL partition columns are not populated for this table
- `ProviderTransactionId` and `ReceiveRequestCorrelationId` are empty/NULL in most rows
- `Amount` uses `numeric(36, 18)` precision — very small amounts (e.g., 1e-7) exist for dust/test transactions
- `BlockchainFee` can be 0 (0E-18) for certain crypto networks or internal transfers
- Blockchain addresses vary in format by crypto network: Bitcoin (base58/bech32), Ethereum (0x-prefixed), XRP (r-prefixed), Stellar (G-prefixed)
- `WalletId` is a GUID (varchar 4000), not a numeric identifier

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | ETL-computed or pipeline-added column, described from CopyFromLake/Generic Pipeline logic |
| Tier 3 | No upstream wiki available; description grounded in DDL, sample data, and downstream SP usage |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the received transaction record in WalletDB. Distribution key for this table. Used as join key by SP_EXW_Fact_Transactions (TranID) and SP_EXW_FactRedeemTransactions (ReceivedTransactionID). (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 2 | Occurred | datetime2(7) | YES | Timestamp when the received transaction was recorded in the wallet service. Used by EXW_TransactionsView as the transaction occurrence time. Distinct from BlockchainTransactionDate which reflects on-chain confirmation. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 3 | WalletId | varchar(4000) | YES | GUID identifier of the receiving wallet. FK to EXW_Wallet.Wallets and EXW_Wallet.CustomerWalletsView. Used by EXW_TransactionsView to resolve wallet owner GCID and by SP_EXW_FactRedeemTransactions for AML matching. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 4 | SenderAddress | varchar(max) | YES | Blockchain address of the sending party. Format varies by blockchain network (Bitcoin base58/bech32, Ethereum 0x-prefixed, XRP r-prefixed, Stellar G-prefixed). May include tags for tag-based blockchains (e.g., XRP `?dt=0`). (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 5 | ReceiverAddress | varchar(max) | YES | Blockchain address of the receiving party (the eToroX wallet address). Format varies by blockchain network. Used by SP_EXW_FactRedeemTransactions to match sent transaction outputs to received transactions. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 6 | Amount | numeric(36,18) | YES | Transaction amount in the native cryptocurrency unit. High precision (18 decimals) to support sub-unit amounts. Used downstream by SP_EXW_Fact_Transactions for ReceivedAmount and by SP_EXW_FactRedeemTransactions for fee reconciliation. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 7 | BlockchainFee | numeric(36,18) | YES | Blockchain network fee associated with this received transaction. Can be 0 (0E-18) for networks with no receive-side fee or internal transfers. SP_EXW_FactRedeemTransactions divides this by the count of received transactions sharing the same BlockchainTransactionId to allocate fees. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 8 | CorrelationId | varchar(4000) | YES | Correlation identifier (GUID) linking this received transaction to related wallet operations (sends, conversions, redemptions). Used by SP_EXW_Fact_Transactions for AML validation matching via EXW_Wallet.AmlValidations. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 9 | BlockchainTransactionId | varchar(max) | YES | On-chain transaction hash uniquely identifying the blockchain transaction. Multiple received transactions can share the same hash (UTXO outputs). Used as the primary join key between SentTransactions and ReceivedTransactions in SP_EXW_FactRedeemTransactions. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 10 | BlockchainTransactionDate | datetime2(7) | YES | Timestamp of the blockchain transaction confirmation on-chain. Typically slightly before `Occurred` (wallet service detection lag). Used by EXW_TransactionsView as `TransDate` for the received transaction. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 11 | CryptoId | int | YES | FK to EXW_Wallet.CryptoTypes (CryptoID). Identifies the cryptocurrency asset. 128+ distinct values; top 5: CryptoId 21 (37%), 4 (25%), 1 (15%), 2 (11%), 18 (4%). Joined by SP_EXW_Fact_Transactions to resolve CryptoName and InstrumentId. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 12 | ReceivedTransactionTypeId | int | YES | FK to EXW_Dictionary.ReceivedTransactionTypes. 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. Used by SP_EXW_Fact_Transactions to classify received-side transactions in the fact table (CASE logic for IsRedeem, IsConversion, IsPayment, IsFunding flags). (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 13 | NormalizedSenderAddress | varchar(max) | YES | Case-normalized form of SenderAddress for consistent matching. Used by EXW_TransactionsView to filter out self-receives by checking against EXW_Wallet.WalletAddresses for the same WalletId. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 14 | NormalizedReceiverAddress | varchar(max) | YES | Case-normalized form of ReceiverAddress for consistent matching. Strips blockchain-specific tags (e.g., XRP destination tags). (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 15 | ProviderTransactionId | varchar(max) | YES | External blockchain provider's internal transaction identifier. Empty/NULL in most sampled rows. Used for provider-side reconciliation. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |
| 16 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column: year. Currently NULL for all rows in this table. (Tier 2 — Generic Pipeline) |
| 17 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column: year-month. Currently NULL for all rows in this table. (Tier 2 — Generic Pipeline) |
| 18 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column: year-month-day. Currently NULL for all rows in this table. (Tier 2 — Generic Pipeline) |
| 19 | SynapseUpdateDate | datetime | YES | Timestamp of the last CopyFromLake data refresh into Synapse. Set to GETDATE() at load time. All sampled rows show the same value (2026-04-26 13:01:57), indicating the most recent full reload. (Tier 2 — Generic Pipeline) |
| 20 | partition_date | date | YES | Date-based partition key derived from the source record. Matches the date portion of `Occurred`. Used for efficient date-range filtering in downstream queries. (Tier 2 — Generic Pipeline) |
| 21 | ReceiveRequestCorrelationId | varchar(max) | YES | Correlation identifier linking this received transaction to the originating receive request. NULL/empty in all sampled rows. Present in the main table DDL but absent from the CopyFromLake staging DDL, suggesting it was added to the production source after initial pipeline setup. (Tier 3 — WalletDB.Wallet.ReceivedTransactions) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.ReceivedTransactions | Id | Passthrough |
| Occurred | WalletDB.Wallet.ReceivedTransactions | Occurred | Passthrough |
| WalletId | WalletDB.Wallet.ReceivedTransactions | WalletId | Passthrough |
| SenderAddress | WalletDB.Wallet.ReceivedTransactions | SenderAddress | Passthrough |
| ReceiverAddress | WalletDB.Wallet.ReceivedTransactions | ReceiverAddress | Passthrough |
| Amount | WalletDB.Wallet.ReceivedTransactions | Amount | Passthrough |
| BlockchainFee | WalletDB.Wallet.ReceivedTransactions | BlockchainFee | Passthrough |
| CorrelationId | WalletDB.Wallet.ReceivedTransactions | CorrelationId | Passthrough |
| BlockchainTransactionId | WalletDB.Wallet.ReceivedTransactions | BlockchainTransactionId | Passthrough |
| BlockchainTransactionDate | WalletDB.Wallet.ReceivedTransactions | BlockchainTransactionDate | Passthrough |
| CryptoId | WalletDB.Wallet.ReceivedTransactions | CryptoId | Passthrough |
| ReceivedTransactionTypeId | WalletDB.Wallet.ReceivedTransactions | ReceivedTransactionTypeId | Passthrough |
| NormalizedSenderAddress | WalletDB.Wallet.ReceivedTransactions | NormalizedSenderAddress | Passthrough |
| NormalizedReceiverAddress | WalletDB.Wallet.ReceivedTransactions | NormalizedReceiverAddress | Passthrough |
| ProviderTransactionId | WalletDB.Wallet.ReceivedTransactions | ProviderTransactionId | Passthrough |
| etr_y | Generic Pipeline | — | ETL year partition |
| etr_ym | Generic Pipeline | — | ETL year-month partition |
| etr_ymd | Generic Pipeline | — | ETL year-month-day partition |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load |
| partition_date | Generic Pipeline | — | Date partition key |
| ReceiveRequestCorrelationId | WalletDB.Wallet.ReceivedTransactions | ReceiveRequestCorrelationId | Passthrough |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.ReceivedTransactions (production, eToroX Wallet service)
  |-- Generic Pipeline (Bronze export, Append, 60 min, parquet) --|
  v
Bronze/WalletDB/Wallet/ReceivedTransactions/ (Data Lake)
  |-- CopyFromLake (staging load) --|
  v
CopyFromLake_staging.[EXW_Wallet.ReceivedTransactions] (15 cols, ROUND_ROBIN)
  |-- CopyFromLake (final load, adds ETL columns) --|
  v
EXW_Wallet.ReceivedTransactions (2.5M rows, HASH(Id))
  |-- Consumed by --|
  v
EXW_Wallet.EXW_TransactionsView (received_transactions CTE)
EXW_dbo.SP_EXW_Fact_Transactions → EXW_dbo.EXW_FactTransactions
EXW_dbo.SP_EXW_FactRedeemTransactions → EXW_dbo.EXW_FactRedeemTransactions
  |-- Generic Pipeline (Bronze UC export) --|
  v
wallet.bronze_walletdb_wallet_receivedtransactions (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CryptoId | EXW_Wallet.CryptoTypes | FK to CryptoID. Resolves cryptocurrency name, blockchain, instrument mapping. |
| ReceivedTransactionTypeId | EXW_Dictionary.ReceivedTransactionTypes | FK to Id. 8 transaction types (MoneyIn, Redeem, Funding, etc.). |
| WalletId | EXW_Wallet.Wallets | FK to WalletId. Resolves wallet ownership. |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| Id | EXW_dbo.SP_EXW_Fact_Transactions | LEFT JOIN on Id = TranID (ActionTypeId = 2) to get ReceivedTransactionTypeId. |
| BlockchainTransactionId, ReceiverAddress | EXW_dbo.SP_EXW_FactRedeemTransactions | JOIN to match received transactions to sent transactions for redeem reconciliation. |
| Id, SenderAddress, ReceiverAddress, etc. | EXW_Wallet.EXW_TransactionsView | received_transactions CTE reads all core columns for unified transaction view. |

---

## 7. Sample Queries

### 7.1 Received Transactions by Type and Month

```sql
SELECT
    rtt.Name AS TransactionType,
    FORMAT(rt.Occurred, 'yyyy-MM') AS Month,
    COUNT(*) AS TxCount,
    SUM(rt.Amount) AS TotalAmount
FROM EXW_Wallet.ReceivedTransactions rt
JOIN EXW_Dictionary.ReceivedTransactionTypes rtt
    ON rt.ReceivedTransactionTypeId = rtt.Id
WHERE rt.partition_date >= '2026-01-01'
GROUP BY rtt.Name, FORMAT(rt.Occurred, 'yyyy-MM')
ORDER BY Month DESC, TxCount DESC
```

### 7.2 Top Receiving Wallets by Volume

```sql
SELECT TOP 20
    rt.WalletId,
    ct.Name AS CryptoName,
    COUNT(*) AS TxCount,
    SUM(rt.Amount) AS TotalReceived
FROM EXW_Wallet.ReceivedTransactions rt
JOIN EXW_Wallet.CryptoTypes ct ON rt.CryptoId = ct.CryptoID
WHERE rt.partition_date >= '2026-01-01'
GROUP BY rt.WalletId, ct.Name
ORDER BY TotalReceived DESC
```

### 7.3 Match Received to Sent for Redeem Reconciliation

```sql
SELECT
    st.Id AS SentTxId,
    rt.Id AS ReceivedTxId,
    rt.Amount AS ReceivedAmount,
    rt.BlockchainFee AS ReceivedFee,
    st.BlockchainTransactionId
FROM EXW_Wallet.ReceivedTransactions rt
JOIN EXW_Wallet.SentTransactions st
    ON rt.BlockchainTransactionId = st.BlockchainTransactionId
WHERE rt.partition_date >= '2026-04-01'
    AND rt.NormalizedSenderAddress <> rt.NormalizedReceiverAddress
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen-harness mode).

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 12/14*
*Tiers: 0 T1, 5 T2, 16 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.ReceivedTransactions | Type: Table | Production Source: WalletDB.Wallet.ReceivedTransactions (CopyFromLake)*
