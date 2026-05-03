# EXW_Wallet.Redemptions

> 1.1M-row crypto wallet redemption table tracking every cryptocurrency withdrawal request from the eToroX Wallet platform since July 2019. Sourced from WalletDB.Wallet.Redemptions via Generic Pipeline (Override, daily). Each row represents one redemption request with its requested amount, fees, status, and associated billing/position references.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Redemptions (Generic Pipeline Override, daily) |
| **Refresh** | Daily (every 1440 minutes), Override strategy |
| **Synapse Distribution** | HASH(SendRequestCorrelationId) |
| **Synapse Index** | HEAP; nonclustered index on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_redemptions` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.Redemptions is a Bronze-layer copy of the WalletDB production table `Wallet.Redemptions`. It stores every cryptocurrency redemption request made by eToro customers through the eToroX Wallet platform. A redemption is the process of withdrawing crypto assets from the eToro platform to an external blockchain address.

The table contains ~1.1M rows spanning from 2019-07-14 to present. Each row captures the redemption request details including the requesting customer (RequestingGcid), the crypto position being redeemed (PositionId), the cryptocurrency type (CryptoId — 57 distinct cryptos), the requested amount, associated fees (eToro fee + estimated blockchain fee), and the redemption lifecycle status.

The table is loaded daily via Generic Pipeline using Override strategy (full table replacement). It serves as a source for:
- **SP_EXW_FactRedeemTransactions**: joins Redemptions with SentTransactions, SentTransactionOutputs, ReceivedTransactions, and CryptoTypes to build the full redemption transaction fact table.
- **EXW_TransactionsView**: uses Redemptions in the `redeem_transactions` CTE for unified wallet transaction reporting.

The `EndDate` field uses a sentinel value of `9999-12-31 23:59:59.999999` for all sampled rows, indicating open/ongoing redemptions. The `RedemptionStatus` is overwhelmingly 3 (99.997% of rows), with only 34 rows at status 4 and 4 rows at status 2.

---

## 2. Business Logic

### 2.1 Redemption Lifecycle

**What**: Each redemption request transitions through statuses tracked by RedemptionStatus, with a final status derived downstream from RequestStatuses.
**Columns Involved**: RedemptionStatus, BeginDate, EndDate, SendRequestCorrelationId
**Rules**:
- RedemptionStatus has 3 observed values: 2 (4 rows), 3 (1,129,868 rows), 4 (34 rows)
- EndDate = 9999-12-31 is a sentinel indicating the redemption is still tracked
- The downstream SP_EXW_FactRedeemTransactions derives FinalRedeemStatus ('Completed', 'Error', 'Pending') from RequestStatuses.RequestStatusId, not from this RedemptionStatus column

### 2.2 Fee Structure

**What**: Multiple fee components are tracked for each redemption.
**Columns Involved**: eToroFeeAmount, EstimatedBlockchainFee, InitialFeeAmount
**Rules**:
- eToroFeeAmount: the eToro platform fee charged for processing the redemption
- EstimatedBlockchainFee: estimated network fee for the blockchain transaction
- InitialFeeAmount: initial fee at redemption creation (0 in all sampled rows)
- EXW_TransactionsView computes EffectiveBlockchainFee = EstimatedBlockchainFee + InitialFeeAmount

### 2.3 Correlation and Deduplication

**What**: SendRequestCorrelationId is the primary correlation key linking a redemption to its sent transaction.
**Columns Involved**: SendRequestCorrelationId, BillingRedeemId, OriginalRequestGuid
**Rules**:
- SendRequestCorrelationId is the HASH distribution key and the primary join key to EXW_Wallet.Requests and EXW_Wallet.SentTransactions
- BillingRedeemId is used as a ROW_NUMBER() PARTITION BY key in SP_EXW_FactRedeemTransactions for deduplication (latest BeginDate per BillingRedeemId wins)
- OriginalRequestGuid is commented out in the SP and appears unused in downstream processing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `SendRequestCorrelationId` — optimizes joins to EXW_Wallet.Requests and EXW_Wallet.SentTransactions which also use CorrelationId-based joins
- **Index**: HEAP (no clustered index); nonclustered index on `partition_date`
- **Note**: `partition_date` is NULL across all sampled rows despite having an index, suggesting the column may not be populated for this table

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many redemptions per crypto? | `SELECT CryptoId, COUNT(*) FROM EXW_Wallet.Redemptions GROUP BY CryptoId` |
| Redemptions for a specific customer? | `SELECT * FROM EXW_Wallet.Redemptions WHERE RequestingGcid = @gcid` |
| Daily redemption volume? | `SELECT CAST(BeginDate AS DATE), COUNT(*), SUM(RequestedAmount) FROM EXW_Wallet.Redemptions GROUP BY CAST(BeginDate AS DATE)` |
| Full redemption transaction details? | Query EXW_dbo.EXW_FactRedeemTransactions instead — it enriches Redemptions with sent/received blockchain data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.CryptoTypes | CryptoTypes.CryptoID = Redemptions.CryptoId | Resolve cryptocurrency name and metadata |
| EXW_Wallet.Requests | Requests.CorrelationId = Redemptions.SendRequestCorrelationId | Get request statuses and timestamps |
| EXW_Wallet.SentTransactions | SentTransactions.CorrelationId = Redemptions.SendRequestCorrelationId | Get blockchain transaction details |
| EXW_dbo.EXW_FactRedeemTransactions | FactRedeemTransactions.RedeemID = Redemptions.Id | Access enriched fact table with sent/received data |

### 3.4 Gotchas

- `partition_date` is NULL in all sampled rows — do not rely on it for filtering
- `SourceWalletId` and `TransactionTypeId` are NULL in many rows (~10% for TransactionTypeId, potentially all for SourceWalletId)
- `EndDate` = 9999-12-31 is a sentinel, not a real date — exclude from date range calculations
- `RedemptionStatus` is NOT the final status used downstream; the SP derives FinalRedeemStatus from RequestStatuses
- `RequestedAmount` and fee columns use numeric(36,18) precision — be mindful of floating-point display issues
- `eToroFeeAmount` shows very small values (e.g., 1E-8) for some cryptos — this is valid, not zero

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP code with transform |
| Tier 3 | Inferred from DDL, data sampling, and downstream SP usage; no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary identifier for the redemption record. Used as RedeemID in downstream SP_EXW_FactRedeemTransactions. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 2 | OriginalRequestGuid | uniqueidentifier | YES | GUID of the original redemption request. Not referenced in downstream SP processing (commented out in SP_EXW_FactRedeemTransactions). (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 3 | SendRequestCorrelationId | uniqueidentifier | YES | Correlation ID linking this redemption to its sent transaction request. Distribution key. Used as the primary join key to EXW_Wallet.Requests (via CorrelationId) and EXW_Wallet.SentTransactions (via CorrelationId). (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 4 | PositionId | bigint | YES | eToro trading position ID associated with this crypto redemption. Joined to EXW_Wallet.SentTransactionOutputs.SourceId in the downstream SP. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 5 | RequestingGcid | bigint | YES | Global customer ID (GCID) of the user requesting the redemption. Also used as ReceivingGCID in EXW_FactRedeemTransactions. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 6 | CryptoId | int | YES | Cryptocurrency identifier. FK to EXW_Wallet.CryptoTypes. 57 distinct values observed; top by volume: 4 (464,978 rows), 1 (261,640), 2 (142,210), 18 (106,275). (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 7 | RequestedAmount | numeric(36,18) | YES | Amount of cryptocurrency requested for redemption, in the cryptocurrency's native unit. High-precision decimal to accommodate crypto fractional amounts. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 8 | eToroFeeAmount | numeric(36,18) | YES | eToro platform fee charged for processing this redemption. Used as EtoroFees in EXW_TransactionsView. Very small values (e.g., 1E-8) observed for some cryptos. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 9 | RedemptionStatus | int | YES | Status code of the redemption request. 3 observed values: 2 (4 rows), 3 (1,129,868 rows, dominant), 4 (34 rows). Note: this is NOT the final status — the downstream SP derives FinalRedeemStatus from RequestStatuses. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 10 | BillingTransId | bigint | YES | Billing transaction ID associated with this redemption. Links to the billing system for financial reconciliation. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 11 | BillingRedeemId | bigint | YES | Billing redemption ID. Used as ROW_NUMBER() PARTITION BY key in SP_EXW_FactRedeemTransactions for deduplication — latest BeginDate per BillingRedeemId is retained. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 12 | BeginDate | datetime2(7) | YES | Start date/time of the redemption process. Used for date-based filtering in the SP (WHERE CONVERT(DATE, BeginDate) = @d) and for ordering within deduplication windows. Range: 2019-07-14 to 2026-04-27. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 13 | EndDate | datetime2(7) | YES | End date/time of the redemption process. Sentinel value 9999-12-31 23:59:59.999999 observed in all sample rows, indicating open/ongoing redemptions. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 14 | EstimatedBlockchainFee | numeric(36,18) | YES | Estimated blockchain network fee for the transaction. Combined with InitialFeeAmount in EXW_TransactionsView to compute EffectiveBlockchainFee. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 15 | InitialFeeAmount | numeric(36,18) | YES | Initial fee amount set at redemption creation time. Sample data shows 0 values (0E-18). Added to EstimatedBlockchainFee in EXW_TransactionsView. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 16 | SourceWalletId | uniqueidentifier | YES | Source wallet identifier from which the crypto is being redeemed. NULL in all sampled rows, suggesting this field may be unpopulated or deprecated. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 17 | TransactionTypeId | int | YES | Transaction type identifier. 2 observed values: 0 (1,020,228 rows), NULL (109,678 rows). In EXW_TransactionsView, redemptions are filtered where TransactionTypeId IN (0, 8) for Redeem type. (Tier 3 — WalletDB.Wallet.Redemptions; no upstream wiki) |
| 18 | etr_y | varchar(max) | YES | ETL-generated partition column: year extracted from the source record's timestamp (e.g., '2019', '2020'). Added by the Generic Pipeline during Bronze export. (Tier 2 — Generic Pipeline) |
| 19 | etr_ym | varchar(max) | YES | ETL-generated partition column: year-month string (e.g., '2019-09'). Added by the Generic Pipeline during Bronze export. (Tier 2 — Generic Pipeline) |
| 20 | etr_ymd | varchar(max) | YES | ETL-generated partition column: year-month-day string (e.g., '2019-09-18'). Added by the Generic Pipeline during Bronze export. (Tier 2 — Generic Pipeline) |
| 21 | SynapseUpdateDate | datetime | YES | Timestamp of the last Synapse data refresh for this row. Set by the Generic Pipeline during the Override load. All sampled rows show 2026-04-27, consistent with recent full refresh. (Tier 2 — Generic Pipeline) |
| 22 | partition_date | date | YES | Partition date column with a nonclustered index. NULL in all sampled rows, suggesting this column is not populated for this table despite the index. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.Redemptions | Id | Passthrough |
| OriginalRequestGuid | WalletDB.Wallet.Redemptions | OriginalRequestGuid | Passthrough |
| SendRequestCorrelationId | WalletDB.Wallet.Redemptions | SendRequestCorrelationId | Passthrough |
| PositionId | WalletDB.Wallet.Redemptions | PositionId | Passthrough |
| RequestingGcid | WalletDB.Wallet.Redemptions | RequestingGcid | Passthrough |
| CryptoId | WalletDB.Wallet.Redemptions | CryptoId | Passthrough |
| RequestedAmount | WalletDB.Wallet.Redemptions | RequestedAmount | Passthrough |
| eToroFeeAmount | WalletDB.Wallet.Redemptions | eToroFeeAmount | Passthrough |
| RedemptionStatus | WalletDB.Wallet.Redemptions | RedemptionStatus | Passthrough |
| BillingTransId | WalletDB.Wallet.Redemptions | BillingTransId | Passthrough |
| BillingRedeemId | WalletDB.Wallet.Redemptions | BillingRedeemId | Passthrough |
| BeginDate | WalletDB.Wallet.Redemptions | BeginDate | Passthrough |
| EndDate | WalletDB.Wallet.Redemptions | EndDate | Passthrough |
| EstimatedBlockchainFee | WalletDB.Wallet.Redemptions | EstimatedBlockchainFee | Passthrough |
| InitialFeeAmount | WalletDB.Wallet.Redemptions | InitialFeeAmount | Passthrough |
| SourceWalletId | WalletDB.Wallet.Redemptions | SourceWalletId | Passthrough |
| TransactionTypeId | WalletDB.Wallet.Redemptions | TransactionTypeId | Passthrough |
| etr_y | — | — | Generic Pipeline ETL partition (year) |
| etr_ym | — | — | Generic Pipeline ETL partition (year-month) |
| etr_ymd | — | — | Generic Pipeline ETL partition (year-month-day) |
| SynapseUpdateDate | — | — | Generic Pipeline ETL timestamp |
| partition_date | — | — | Generic Pipeline ETL partition date |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Redemptions (production, WalletDB server)
  |-- Generic Pipeline (Bronze export, Override, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/Redemptions/ (Data Lake)
  |-- Generic Pipeline (Synapse load) ---|
  v
EXW_Wallet.Redemptions (1.1M rows, Synapse DWH)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_redemptions (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CryptoId | EXW_Wallet.CryptoTypes | FK to cryptocurrency reference table (CryptoTypes.CryptoID) |
| PositionId | Trade position tables | References an eToro trading position |
| RequestingGcid | Customer tables | Global customer ID of the requesting user |
| BillingTransId | Billing system | Links to billing transaction record |
| BillingRedeemId | Billing system | Links to billing redemption record |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.SP_EXW_FactRedeemTransactions | Redemptions.SendRequestCorrelationId, PositionId, BeginDate | Builds fact table for full redemption transaction lifecycle |
| EXW_Wallet.EXW_TransactionsView | Redemptions.SendRequestCorrelationId = SentTransactions.CorrelationId AND PositionId = SentTransactionOutputs.SourceId | Unified wallet transaction view (redeem_transactions CTE) |

---

## 7. Sample Queries

### 7.1 Daily Redemption Volume by Cryptocurrency

```sql
SELECT
    CAST(r.BeginDate AS DATE) AS RedemptionDate,
    ct.Name AS CryptoName,
    COUNT(*) AS RedemptionCount,
    SUM(r.RequestedAmount) AS TotalRequestedAmount
FROM EXW_Wallet.Redemptions r
JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = r.CryptoId
WHERE r.BeginDate >= '2026-01-01'
GROUP BY CAST(r.BeginDate AS DATE), ct.Name
ORDER BY RedemptionDate DESC, TotalRequestedAmount DESC;
```

### 7.2 Redemption Status Breakdown

```sql
SELECT
    RedemptionStatus,
    COUNT(*) AS Cnt,
    MIN(BeginDate) AS EarliestRedemption,
    MAX(BeginDate) AS LatestRedemption
FROM EXW_Wallet.Redemptions
GROUP BY RedemptionStatus
ORDER BY Cnt DESC;
```

### 7.3 Top Customers by Redemption Count

```sql
SELECT TOP 20
    RequestingGcid,
    COUNT(*) AS RedemptionCount,
    COUNT(DISTINCT CryptoId) AS DistinctCryptos,
    SUM(RequestedAmount) AS TotalRequested
FROM EXW_Wallet.Redemptions
GROUP BY RequestingGcid
ORDER BY RedemptionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen-harness mode — Phase 10 skipped).

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 12/14*
*Tiers: 0 T1, 5 T2, 17 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 6/10, Lineage: 8/10*
*Object: EXW_Wallet.Redemptions | Type: Table | Production Source: WalletDB.Wallet.Redemptions (Generic Pipeline)*
