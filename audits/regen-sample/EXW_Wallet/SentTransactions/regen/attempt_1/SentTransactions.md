# EXW_Wallet.SentTransactions

> 1.86M-row bronze staging table storing outbound blockchain transactions from the eToro Wallet platform (WalletDB), covering crypto sends, redemptions, conversions, payments, staking, and funding operations from April 2018 to present. Loaded hourly via Generic Pipeline (Append) from WalletDB.Wallet.SentTransactions.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.SentTransactions (Generic Pipeline, Append) |
| **Refresh** | Hourly (every 60 minutes), Append strategy |
| **Synapse Distribution** | HASH(Id) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_senttransactions` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

This table is a direct bronze copy of the `WalletDB.Wallet.SentTransactions` production table, recording every outbound blockchain transaction initiated from the eToro Wallet platform. Each row represents a single sent transaction — whether a crypto redemption (position cashout to external wallet), customer withdrawal, AML money-back, funding transfer, crypto-to-fiat/crypto-to-position conversion, payment, staking operation, or blockchain activation.

The table contains 1,860,740 rows spanning from 2018-04-23 to 2026-04-27. The dominant transaction types are CustomerMoneyOut (829K rows, 44.6%) and Redeem (772K rows, 41.5%). The top three cryptocurrencies by volume are XRP (689K), ETH (452K), and BTC (366K).

No stored procedure writes to this table. It is populated exclusively by the Generic Pipeline hourly append from WalletDB production. Downstream SPs — `SP_EXW_Fact_Transactions`, `SP_EXW_C2F_E2E`, and `SP_EXW_FactRedeemTransactions` — read from this table to build fact tables and reconciliation reports.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: Each sent transaction is categorized by `TransactionTypeId`, which determines how the transaction is processed by downstream ETL.
**Columns Involved**: `TransactionTypeId`
**Rules**:
- Types 0 and 8 (Redeem, RedeemAsic) are processed as redemptions in the EXW_TransactionsView and SP_EXW_FactRedeemTransactions
- Types 5 and 6 (ConversionMoneyIn, ConversionMoneyOut) are processed as conversion transactions
- Type 7 (Payment) is processed as a payment transaction
- Type 9 (Staking) is processed as a staking transaction
- Types 1, 2, 4, 10, 11, 12, 13 are grouped as "other" transactions in EXW_TransactionsView
- Type 12 (ConversionToFiat) is used specifically in SP_EXW_C2F_E2E for crypto-to-fiat reconciliation

### 2.2 Correlation-Based Transaction Linking

**What**: The `CorrelationId` column links this table to related subsystem tables for end-to-end transaction tracking.
**Columns Involved**: `CorrelationId`, `TransactionTypeId`
**Rules**:
- For redemptions: `CorrelationId` joins to `EXW_Wallet.Redemptions.SendRequestCorrelationId`
- For conversions: `CorrelationId` joins to `EXW_Wallet.Conversions.CorrelationId`
- For payments: `CorrelationId` joins to `EXW_Wallet.Payments.CorrelationId`
- For staking: `CorrelationId` joins to `EXW_Staking.Staking.CorrelationId`
- For C2F/C2P flows: `CorrelationId` joins to `EXW_Wallet.Requests.CorrelationId` and `WalletConversionDB_C2F_Conversions.CorrelationId`

### 2.3 Blockchain Fee Allocation

**What**: The `BlockchainFee` is the total fee for the blockchain transaction and is split across outputs in views.
**Columns Involved**: `BlockchainFee`, `Id`
**Rules**:
- In EXW_TransactionsView, the fee is attributed to the first output only (using ROW_NUMBER PARTITION BY Id)
- In SP_EXW_FactRedeemTransactions, the fee is divided equally across all outputs: `BlockchainFee / COUNT(outputs)`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH(Id), which aligns with the primary key and the most common join pattern (SentTransactionId = Id)
- HEAP storage (no clustered index); NCI on partition_date supports date-range filtering
- JOINs to SentTransactionOutputs and SentTransactionStatuses (both join on Id) are co-located if those tables are also HASH(SentTransactionId)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Find all transactions for a wallet | `WHERE WalletId = '<guid>'` — full scan needed (no index on WalletId) |
| Get transactions by date range | `WHERE partition_date BETWEEN '2025-01-01' AND '2025-12-31'` — uses NCI |
| Filter by transaction type | `WHERE TransactionTypeId = 0` — combine with date filter for performance |
| Trace a specific blockchain tx | `WHERE BlockchainTransactionId = '<hash>'` — full scan, consider narrowing with partition_date |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.SentTransactionOutputs | SentTransactionId = Id | Get output details (amounts, addresses) |
| EXW_Wallet.SentTransactionStatuses | SentTransactionId = Id | Get status history |
| EXW_Wallet.Redemptions | SendRequestCorrelationId = CorrelationId | Link to redemption details |
| EXW_Wallet.Conversions | CorrelationId = CorrelationId | Link to conversion details |
| EXW_Dictionary.TransactionTypes | Id = TransactionTypeId | Resolve transaction type name |
| EXW_Wallet.CryptoTypes | CryptoID = CryptoId | Resolve cryptocurrency name |
| EXW_Wallet.CustomerWalletsView | Id = WalletId | Resolve wallet owner (GCID) |

### 3.4 Gotchas

- `BlockchainTransactionId` format varies: some have `0x` prefix (ETH-style), others are bare hex strings (XRP/TRX-style). Use case-insensitive comparison or normalize when matching
- `etr_y`, `etr_ym`, `etr_ymd` are NULL for many recent rows — these legacy ETL columns were phased out in favor of `partition_date` and `SynapseUpdateDate`
- `SynapseUpdateDate` is NULL for older rows (pre-2020 roughly) — it was added to the pipeline after initial load
- `WalletId` is a GUID string, not a uniqueidentifier type — store as varchar when extracting
- TransactionTypeId 15 exists in the data (141 rows) but has no entry in EXW_Dictionary.TransactionTypes — likely a newer type not yet added to the dictionary

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or pipeline-generated column |
| Tier 3 | Inferred from DDL, SP code, sample data, and downstream usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the sent transaction record in WalletDB. Used as distribution key and join target for SentTransactionOutputs and SentTransactionStatuses. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 2 | BlockchainTransactionId | varchar(4000) | YES | Blockchain transaction hash identifying the on-chain transaction. Format varies by blockchain: 0x-prefixed hex for ETH, bare hex for XRP/TRX. Used for cross-referencing with ReceivedTransactions and reconciliation. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 3 | WalletId | varchar(4000) | YES | GUID identifying the sending wallet. Joins to EXW_Wallet.CustomerWalletsView and EXW_Wallet.WalletPool to resolve the wallet owner (GCID) and public address. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 4 | Occurred | datetime2(7) | YES | Timestamp when the sent transaction was initiated. Used as the primary event time for date-based filtering in downstream SPs (SP_EXW_Fact_Transactions, SP_EXW_FactRedeemTransactions). (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 5 | CorrelationId | uniqueidentifier | YES | Correlation identifier linking this sent transaction to its originating business operation across subsystems: Redemptions (SendRequestCorrelationId), Requests, Conversions, Payments, and Staking tables. Central join key for end-to-end transaction tracking in SP_EXW_C2F_E2E. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 6 | TransactionTypeId | int | YES | FK to EXW_Dictionary.TransactionTypes. 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund. Determines downstream processing path in EXW_TransactionsView. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 7 | BlockchainFee | numeric(36,18) | YES | Blockchain network fee charged for the transaction, in the native cryptocurrency unit. Split across outputs in downstream views: first-output-only in EXW_TransactionsView, equally divided in SP_EXW_FactRedeemTransactions. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 8 | CryptoId | int | YES | FK to EXW_Wallet.CryptoTypes. Identifies the cryptocurrency of the transaction. Top values: 4=XRP (689K rows), 2=ETH (452K), 1=BTC (366K), 21=XLM (119K), 6=LTC (73K), 27=TRX (50K). 121 distinct values. (Tier 3 — WalletDB.Wallet.SentTransactions) |
| 9 | etr_y | varchar(max) | YES | ETL-generated partition column containing the four-digit year of the transaction (e.g., '2020'). Legacy column; NULL for many recent rows where partition_date is used instead. (Tier 2 — Generic Pipeline) |
| 10 | etr_ym | varchar(max) | YES | ETL-generated partition column containing year-month (e.g., '2020-06'). Legacy column; NULL for many recent rows where partition_date is used instead. (Tier 2 — Generic Pipeline) |
| 11 | etr_ymd | varchar(max) | YES | ETL-generated partition column containing full date (e.g., '2020-06-17'). Legacy column; NULL for many recent rows where partition_date is used instead. (Tier 2 — Generic Pipeline) |
| 12 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded or last updated in Synapse by the Generic Pipeline. NULL for older rows loaded before this column was introduced. (Tier 2 — Generic Pipeline) |
| 13 | partition_date | date | YES | Date-based partition column derived from the transaction's Occurred date, used for incremental load management and indexed (NCI) for efficient date-range queries. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.SentTransactions | Id | Passthrough |
| BlockchainTransactionId | WalletDB.Wallet.SentTransactions | BlockchainTransactionId | Passthrough |
| WalletId | WalletDB.Wallet.SentTransactions | WalletId | Passthrough |
| Occurred | WalletDB.Wallet.SentTransactions | Occurred | Passthrough |
| CorrelationId | WalletDB.Wallet.SentTransactions | CorrelationId | Passthrough |
| TransactionTypeId | WalletDB.Wallet.SentTransactions | TransactionTypeId | Passthrough |
| BlockchainFee | WalletDB.Wallet.SentTransactions | BlockchainFee | Passthrough |
| CryptoId | WalletDB.Wallet.SentTransactions | CryptoId | Passthrough |
| etr_y | — | — | ETL-generated year partition |
| etr_ym | — | — | ETL-generated year-month partition |
| etr_ymd | — | — | ETL-generated year-month-day partition |
| SynapseUpdateDate | — | — | ETL-generated load timestamp |
| partition_date | — | — | ETL-generated partition date |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.SentTransactions (production, WalletDB server)
  |-- Generic Pipeline (Append, hourly, parquet) ---|
  v
Bronze/WalletDB/Wallet/SentTransactions/ (Data Lake)
  |-- CopyFromLake / Synapse load ---|
  v
EXW_Wallet.SentTransactions (1.86M rows, Synapse)
  |-- Read by SP_EXW_Fact_Transactions ---|
  v
EXW_dbo.EXW_FactTransactions
  |-- Read by SP_EXW_FactRedeemTransactions ---|
  v
EXW_dbo.EXW_FactRedeemTransactions
  |-- Read by SP_EXW_C2F_E2E ---|
  v
EXW_dbo.EXW_C2F_E2E / EXW_dbo.EXW_C2P_E2E
  |-- Generic Pipeline (Bronze export) ---|
  v
wallet.bronze_walletdb_wallet_senttransactions (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| TransactionTypeId | EXW_Dictionary.TransactionTypes | Resolves transaction type name |
| CryptoId | EXW_Wallet.CryptoTypes | Resolves cryptocurrency name and blockchain mapping |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| Id | EXW_Wallet.SentTransactionOutputs.SentTransactionId | Output details (amounts, addresses) per sent transaction |
| Id | EXW_Wallet.SentTransactionStatuses.SentTransactionId | Status history per sent transaction |
| Id | EXW_Wallet.SentTransactionReplaces | Blockchain transaction replacements (BitGo rebroad) |
| CorrelationId | EXW_Wallet.Redemptions.SendRequestCorrelationId | Redemption flow linkage |
| CorrelationId | EXW_Wallet.Requests.CorrelationId | Request flow linkage |
| CorrelationId | EXW_Wallet.Conversions.CorrelationId | Conversion flow linkage |
| — | EXW_Wallet.EXW_TransactionsView | View unions sent + received transactions |
| — | EXW_dbo.SP_EXW_Fact_Transactions | Reads for fact table build |
| — | EXW_dbo.SP_EXW_C2F_E2E | Reads for C2F/C2P reconciliation |
| — | EXW_dbo.SP_EXW_FactRedeemTransactions | Reads for redeem fact build |

---

## 7. Sample Queries

### 7.1 Daily Transaction Summary by Type

```sql
SELECT
    partition_date,
    tt.Name AS TransactionType,
    COUNT(*) AS TxCount,
    COUNT(DISTINCT WalletId) AS UniqueWallets
FROM EXW_Wallet.SentTransactions st
JOIN EXW_Dictionary.TransactionTypes tt ON tt.Id = st.TransactionTypeId
WHERE st.partition_date >= '2026-01-01'
GROUP BY partition_date, tt.Name
ORDER BY partition_date DESC, TxCount DESC;
```

### 7.2 Top Cryptocurrencies by Blockchain Fee Spend

```sql
SELECT
    ct.Name AS Crypto,
    COUNT(*) AS TxCount,
    SUM(st.BlockchainFee) AS TotalBlockchainFee,
    AVG(st.BlockchainFee) AS AvgBlockchainFee
FROM EXW_Wallet.SentTransactions st
JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = st.CryptoId
WHERE st.partition_date >= '2025-01-01'
GROUP BY ct.Name
ORDER BY TotalBlockchainFee DESC;
```

### 7.3 Trace End-to-End Redemption for a Position

```sql
SELECT
    st.Id AS SentTxId,
    st.BlockchainTransactionId,
    st.Occurred,
    st.BlockchainFee,
    r.PositionId,
    r.RequestedAmount,
    r.RedemptionStatus,
    so.ToAddress,
    so.Amount AS OutputAmount
FROM EXW_Wallet.SentTransactions st
JOIN EXW_Wallet.Redemptions r ON r.SendRequestCorrelationId = st.CorrelationId
JOIN EXW_Wallet.SentTransactionOutputs so ON so.SentTransactionId = st.Id AND so.IsEtoroFee = 0
WHERE st.TransactionTypeId IN (0, 8)
  AND st.partition_date >= '2026-01-01'
ORDER BY st.Occurred DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 8 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.SentTransactions | Type: Table | Production Source: WalletDB.Wallet.SentTransactions (Generic Pipeline)*
