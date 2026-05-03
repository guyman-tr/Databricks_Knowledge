# EXW_Wallet.WalletPoolStatuses

> 3.24M-row event table tracking wallet pool status transitions in the eToroX crypto wallet system from 2018-04-23 to present. Each row records a status change event for a wallet pool, sourced from WalletDB.Wallet.WalletPoolStatuses via Generic Pipeline (Append, every 120 minutes). Production source: WalletDB.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.WalletPoolStatuses via Generic Pipeline (Append) |
| **Refresh** | Every 120 minutes (Append strategy) |
| **Synapse Distribution** | HASH(WalletPoolId) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_walletpoolstatuses` |
| **UC Format** | delta |
| **UC Partitioned By** | None (source-level) |
| **UC Table Type** | Bronze export |

---

## 1. Business Meaning

This table stores the complete status change history for wallet pools in the eToroX crypto wallet infrastructure. A "wallet pool" is a pre-generated set of blockchain wallets that get allocated to customers on demand. Each row represents a status transition event (e.g., from Pending to Verified, or from Verified to FundingSent).

The table contains 3.24M rows spanning 2018-04-23 to 2026-04-26, with ~561K rows in 2025 alone. There are 9 possible statuses (see Section 2.1). The data is loaded via Generic Pipeline from production WalletDB with Append strategy every 120 minutes.

Downstream SPs (SP_EXW_WalletInventory, SP_EXW_Hourly) use this table to derive the **latest status** per wallet pool via `ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC)` with `RN = 1`. This latest-status pattern is the primary consumption model.

The `Processed` column is always `False` in the current data, suggesting it may have been intended for an event processing pipeline that was never fully implemented or has been handled elsewhere.

---

## 2. Business Logic

### 2.1 Wallet Pool Status Lifecycle

**What**: Each wallet pool transitions through a defined set of statuses tracked in the dictionary `CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses`.
**Columns Involved**: `WalletPoolStatusId`
**Rules**:
- 1 = Pending — wallet pool created, awaiting verification
- 2 = Verified — wallet pool address verified on blockchain (88% of 2025 records)
- 3 = Failed — verification or funding failure
- 4 = FundingInitiated — funding process started
- 5 = FundingSent — funding transaction broadcast to blockchain
- 6 = FundingVerified — funding confirmed on blockchain
- 7 = FundingFailed — funding transaction failed
- 10 = Timeout — process timed out
- 11 = VerifiedForAssign — verified and ready for customer assignment

### 2.2 Latest-Status Derivation Pattern

**What**: Downstream SPs extract the most recent status per wallet pool using a windowed ROW_NUMBER pattern.
**Columns Involved**: `WalletPoolId`, `Occurred`, all status columns
**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC)` with `RN = 1`
- Used in both SP_EXW_WalletInventory and SP_EXW_Hourly
- The latest status determines the `LastWalletPoolStatus` field in EXW_WalletInventory

### 2.3 Promotion Tag Tracking

**What**: PromotionTagId identifies promotional campaigns associated with wallet pool creation.
**Columns Involved**: `PromotionTagId`
**Rules**:
- Value 1 is the most common promotion tag in data samples
- SP_EXW_WalletInventory uses `PromotionTagId = 1` combined with crypto type membership in `EXW_Wallet.CryptoTypes` to derive the `IsPromotionReady` flag

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distribution: `HASH(WalletPoolId)` — optimized for JOINs on WalletPoolId and the latest-status ROW_NUMBER pattern
- Index: HEAP with NCI on `partition_date` — partition pruning for date-filtered queries
- Co-locate JOINs with `EXW_Wallet.WalletPool` (also keyed on wallet pool identity)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Latest status per wallet pool | `ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) = 1` |
| Status distribution over time | `GROUP BY WalletPoolStatusId, CAST(Occurred AS DATE)` with `partition_date` filter |
| Count of pools in each status | `WHERE partition_date >= '2025-01-01' GROUP BY WalletPoolStatusId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.WalletPool | WalletPool.Id = WalletPoolStatuses.WalletPoolId | Get wallet pool details (Created, BlockchainCryptoId) |
| CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | Dictionary.Id = WalletPoolStatuses.WalletPoolStatusId | Resolve status name |
| EXW_Wallet.CryptoTypes | CryptoTypes.CryptoID = WalletPoolStatuses.CryptoId | Resolve cryptocurrency name and blockchain details |

### 3.4 Gotchas

- `Processed` is always `False` in current data — do not filter on it expecting `True` values
- `etr_y`, `etr_ym`, `etr_ymd` are NULL for recent records (2024+); use `partition_date` or `Occurred` for date filtering instead
- `SynapseUpdateDate` is NULL for older records (pre-2024); only populated after CopyFromLake migration
- `CorrelationId` is NULL for many records (especially status 1=Pending and 2=Verified without funding flow)
- The table tracks ALL status transitions, not just the latest — always use the ROW_NUMBER pattern to get current status
- `CryptoId` here refers to the blockchain-level crypto, not the ERC token-level crypto

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | ETL-computed, transform documented |
| Tier 3 | Inferred from DDL, SP code, and live data evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Surrogate key for the status change event record. Unique identifier per row. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 2 | WalletPoolId | bigint | YES | FK to EXW_Wallet.WalletPool. Identifies which wallet pool this status event belongs to. Distribution key. Used in downstream SPs with ROW_NUMBER to derive latest status. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 3 | WalletPoolStatusId | int | YES | FK to CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses. 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 4 | Occurred | datetime2(7) | YES | Timestamp when this status change occurred on the wallet pool. Used as the ordering column in ROW_NUMBER patterns to identify the latest status. Range: 2018-04-23 to present. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 5 | PromotionTagId | int | YES | Identifies the promotional campaign associated with the wallet pool. Value 1 is most common. Used in SP_EXW_WalletInventory to derive IsPromotionReady flag (PromotionTagId=1 AND crypto in CryptoTypes). NULL when no promotion applies. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 6 | CorrelationId | uniqueidentifier | YES | Correlation identifier linking related operations across the wallet lifecycle (e.g., funding flow). NULL for many status events, populated primarily for FundingSent/FundingVerified statuses. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 7 | Processed | bit | YES | Processing flag. Currently all values are False in the dataset, suggesting an unused or externally-handled event processing mechanism. (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 8 | CryptoId | int | YES | FK to EXW_Wallet.CryptoTypes. Identifies the blockchain-level cryptocurrency for this wallet pool. 11 distinct values observed (1, 2, 3, 4, 6, 8, 18, 19, 21, 27, 64). (Tier 3 — WalletDB.Wallet.WalletPoolStatuses, no upstream wiki) |
| 9 | etr_y | varchar(max) | YES | ETL partition column — year portion (e.g., '2019'). Populated for older records, NULL for recent records (2024+). Part of the Generic Pipeline ETL partitioning scheme. (Tier 3 — Generic Pipeline ETL metadata) |
| 10 | etr_ym | varchar(max) | YES | ETL partition column — year-month portion (e.g., '2019-05'). Populated for older records, NULL for recent records (2024+). Part of the Generic Pipeline ETL partitioning scheme. (Tier 3 — Generic Pipeline ETL metadata) |
| 11 | etr_ymd | varchar(max) | YES | ETL partition column — year-month-day portion (e.g., '2019-05-02'). Populated for older records, NULL for recent records (2024+). Part of the Generic Pipeline ETL partitioning scheme. (Tier 3 — Generic Pipeline ETL metadata) |
| 12 | SynapseUpdateDate | datetime | YES | Timestamp when the record was loaded or last updated in Synapse. NULL for older records pre-dating the CopyFromLake migration. (Tier 3 — Generic Pipeline ETL metadata) |
| 13 | partition_date | date | YES | Physical partition date used for data management and pruning. Indexed (NCI). Aligns with the Occurred date. Preferred column for date-range filtering. (Tier 3 — Generic Pipeline ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.WalletPoolStatuses | Id | Passthrough |
| WalletPoolId | WalletDB.Wallet.WalletPoolStatuses | WalletPoolId | Passthrough |
| WalletPoolStatusId | WalletDB.Wallet.WalletPoolStatuses | WalletPoolStatusId | Passthrough |
| Occurred | WalletDB.Wallet.WalletPoolStatuses | Occurred | Passthrough |
| PromotionTagId | WalletDB.Wallet.WalletPoolStatuses | PromotionTagId | Passthrough |
| CorrelationId | WalletDB.Wallet.WalletPoolStatuses | CorrelationId | Passthrough |
| Processed | WalletDB.Wallet.WalletPoolStatuses | Processed | Passthrough |
| CryptoId | WalletDB.Wallet.WalletPoolStatuses | CryptoId | Passthrough |
| etr_y | Generic Pipeline | — | ETL partition year |
| etr_ym | Generic Pipeline | — | ETL partition year-month |
| etr_ymd | Generic Pipeline | — | ETL partition year-month-day |
| SynapseUpdateDate | Generic Pipeline | — | Synapse load timestamp |
| partition_date | Generic Pipeline | — | Physical partition date |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletPoolStatuses (production, WalletDB server)
  |-- Generic Pipeline (Append, parquet, every 120 min) ---|
  v
Bronze/WalletDB/Wallet/WalletPoolStatuses/ (Data Lake)
  |-- CopyFromLake staging ---|
  v
CopyFromLake_staging.EXW_Wallet.WalletPoolStatuses (ROUND_ROBIN, HEAP)
  |-- CopyFromLake swap ---|
  v
EXW_Wallet.WalletPoolStatuses (3.24M rows, HASH(WalletPoolId), HEAP)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_walletpoolstatuses (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| WalletPoolId | EXW_Wallet.WalletPool | Parent wallet pool entity |
| WalletPoolStatusId | CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | Status name dictionary |
| CryptoId | EXW_Wallet.CryptoTypes | Cryptocurrency type reference |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|---|---|---|
| EXW_dbo.SP_EXW_WalletInventory | Reader SP | Derives latest wallet pool status via ROW_NUMBER for EXW_WalletInventory |
| EXW_dbo.SP_EXW_Hourly | Reader SP | Derives latest wallet pool status for hourly wallet inventory snapshot |

---

## 7. Sample Queries

### 7.1 Latest Status Per Wallet Pool

```sql
SELECT wps.WalletPoolId,
       wps.WalletPoolStatusId,
       d.Name AS StatusName,
       wps.Occurred,
       wps.CryptoId
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) AS RN
    FROM [EXW_Wallet].[WalletPoolStatuses]
    WHERE partition_date >= '2025-01-01'
) wps
JOIN [CopyFromLake].[WalletDB_Dictionary_WalletPoolStatuses] d
    ON d.Id = wps.WalletPoolStatusId
WHERE wps.RN = 1
```

### 7.2 Status Distribution Over Time

```sql
SELECT CAST(Occurred AS DATE) AS EventDate,
       WalletPoolStatusId,
       COUNT(*) AS EventCount
FROM [EXW_Wallet].[WalletPoolStatuses]
WHERE partition_date >= '2025-01-01'
GROUP BY CAST(Occurred AS DATE), WalletPoolStatusId
ORDER BY EventDate DESC, EventCount DESC
```

### 7.3 Wallet Pools with Funding Failures

```sql
SELECT WalletPoolId,
       WalletPoolStatusId,
       Occurred,
       CryptoId,
       CorrelationId
FROM [EXW_Wallet].[WalletPoolStatuses]
WHERE WalletPoolStatusId IN (3, 7) -- Failed, FundingFailed
  AND partition_date >= '2025-01-01'
ORDER BY Occurred DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 13 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.WalletPoolStatuses | Type: Table | Production Source: WalletDB.Wallet.WalletPoolStatuses*
