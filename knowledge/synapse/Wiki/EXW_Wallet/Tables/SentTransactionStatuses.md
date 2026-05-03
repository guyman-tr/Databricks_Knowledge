# EXW_Wallet.SentTransactionStatuses

> 4.6M-row status history table tracking lifecycle state changes for outbound cryptocurrency transactions in the eToroX Wallet platform, sourced from WalletDB.Wallet.SentTransactionStatuses via Generic Pipeline (Append, daily). Covers 2018-04-23 to present with 7 distinct statuses (Pending, Confirmed, Verified, Error, Timeout, PermanentError, WavedError).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.SentTransactionStatuses (Generic Pipeline, Append) |
| **Refresh** | Daily (1440 min), Append strategy, parquet |
| **Synapse Distribution** | HASH(SentTransactionId) |
| **Synapse Index** | HEAP + NCI on partition_date ASC |
| **UC Target** | `wallet.bronze_walletdb_wallet_senttransactionstatuses` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.SentTransactionStatuses is a status-history (event-sourcing) table for outbound cryptocurrency transactions processed by the eToroX Wallet infrastructure. Each row represents a single status transition for a sent transaction, identified by `SentTransactionId`. A single sent transaction accumulates multiple status records as it progresses through its lifecycle.

The table contains 4,554,916 rows spanning from 2018-04-23 to 2026-04-27. Status distribution: Pending (0) = 1.86M (40.8%), Verified (2) = 1.85M (40.6%), Confirmed (1) = 807K (17.7%), Error (3) = 27K, WavedError (6) = 11K, Timeout (4) = 10, PermanentError (5) = 6.

Data is ingested daily from WalletDB.Wallet.SentTransactionStatuses via the Generic Pipeline using an Append strategy (new rows only, no full reload). There is no writer SP in Synapse; the data lands directly from the data lake.

The table is consumed by:
- **SP_EXW_C2F_E2E**: Joins on SentTransactionId to resolve the latest status per sent transaction (using ROW_NUMBER partitioned by SentTransactionId, ordered by Occurred DESC).
- **EXW_TransactionsView**: Uses correlated subqueries (`SELECT TOP 1 StatusId ... ORDER BY Id DESC`) to retrieve the most recent status and its timestamp for each sent transaction.

---

## 2. Business Logic

### 2.1 Status Lifecycle

**What**: Each sent transaction progresses through a defined status lifecycle.
**Columns Involved**: StatusId, Occurred
**Rules**:
- Happy path: Pending (0) -> Confirmed (1) -> Verified (2)
- Error path: Any state -> Error (3) or Timeout (4) or PermanentError (5)
- WavedError (6): An error that has been acknowledged/waived
- The latest status is determined by the highest `Id` value (used in ORDER BY Id DESC patterns)

### 2.2 Latest Status Resolution

**What**: Downstream consumers resolve the current status of a sent transaction using different windowing strategies.
**Columns Involved**: Id, SentTransactionId, StatusId, Occurred
**Rules**:
- SP_EXW_C2F_E2E uses `ROW_NUMBER() OVER (PARTITION BY st.Id ORDER BY ests.Occurred DESC)` with `rn=1` to get the latest status
- EXW_TransactionsView uses `SELECT TOP 1 StatusId ... ORDER BY Id DESC` correlated subqueries
- Both approaches yield the most recent status per SentTransactionId

### 2.3 ETL Partition Strategy

**What**: Generic Pipeline adds date-based partition columns derived from the Occurred timestamp.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date
**Rules**:
- etr_y = year portion of Occurred (e.g., "2021")
- etr_ym = year-month portion (e.g., "2021-11")
- etr_ymd = full date portion (e.g., "2021-11-03")
- partition_date aligns with etr_ymd as a DATE type
- Append strategy means rows are added incrementally, not reloaded

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(SentTransactionId) — optimizes JOINs to EXW_Wallet.SentTransactions (which is also HASH-distributed on its Id/SentTransactionId).
- **Index**: HEAP (no clustered index) + NCI on partition_date ASC for date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Latest status per sent transaction | `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Id DESC) = 1` |
| Status transitions for a specific transaction | `WHERE SentTransactionId = @id ORDER BY Id ASC` |
| Error rate over time | `WHERE StatusId IN (3,4,5) GROUP BY CAST(Occurred AS DATE)` |
| Volume by status | `GROUP BY StatusId` — small cardinality (7 values), fast |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.SentTransactions | SentTransactionId = SentTransactions.Id | Parent transaction details |
| EXW_Wallet.SentTransactionOutputs | SentTransactionId = SentTransactionOutputs.SentTransactionId | Transaction output amounts/addresses |
| CopyFromLake.WalletDB_Dictionary_TransactionStatus | StatusId = Dictionary.Id | Resolve status name |

### 3.4 Gotchas

- **SynapseUpdateDate is mostly NULL**: Only populated for rows loaded after the SynapseUpdateDate column was added. Do not rely on it for incremental filtering.
- **Multiple rows per SentTransactionId**: This is a history table, not a current-state table. Always apply a latest-row filter (ROW_NUMBER or TOP 1 ORDER BY Id DESC) when you need the current status.
- **Id ordering vs Occurred ordering**: Downstream consumers use both `ORDER BY Id DESC` and `ORDER BY Occurred DESC`. In edge cases these may differ; `Id DESC` is the canonical approach used by EXW_TransactionsView.
- **etr_* columns are varchar(max)**: Despite containing date components, these are strings. Use partition_date (DATE type) for date filtering.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | ETL-computed or SP-derived with known logic |
| Tier 3 | Production source confirmed, no upstream wiki documentation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the status record in the WalletDB production source. Auto-incrementing surrogate identifying each individual status transition event. (Tier 3 — WalletDB.Wallet.SentTransactionStatuses) |
| 2 | SentTransactionId | bigint | YES | Foreign key to EXW_Wallet.SentTransactions.Id. Identifies the outbound wallet transaction this status belongs to. Distribution key. Multiple status rows exist per SentTransactionId, representing the status history. (Tier 3 — WalletDB.Wallet.SentTransactionStatuses) |
| 3 | StatusId | int | YES | Transaction status code. FK to WalletDB_Dictionary_TransactionStatus. 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. (Tier 3 — WalletDB.Wallet.SentTransactionStatuses) |
| 4 | Occurred | datetime2(7) | YES | Timestamp when this status transition occurred in the production system. Used by downstream consumers (SP_EXW_C2F_E2E) to determine the latest status via windowing. (Tier 3 — WalletDB.Wallet.SentTransactionStatuses) |
| 5 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column: year extracted from the source record timestamp (e.g., "2021"). (Tier 2 — Generic Pipeline) |
| 6 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column: year-month extracted from the source record timestamp (e.g., "2021-11"). (Tier 2 — Generic Pipeline) |
| 7 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column: full date extracted from the source record timestamp (e.g., "2021-11-03"). (Tier 2 — Generic Pipeline) |
| 8 | SynapseUpdateDate | datetime | YES | Timestamp when the record was loaded or last updated in Synapse. Set by the Generic Pipeline at ingestion time. Mostly NULL for older rows loaded before this column was introduced. (Tier 2 — Generic Pipeline) |
| 9 | partition_date | date | YES | Physical partition date used for the NCI index and data lifecycle management. Aligns with etr_ymd. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.SentTransactionStatuses | Id | Passthrough |
| SentTransactionId | WalletDB.Wallet.SentTransactionStatuses | SentTransactionId | Passthrough |
| StatusId | WalletDB.Wallet.SentTransactionStatuses | StatusId | Passthrough |
| Occurred | WalletDB.Wallet.SentTransactionStatuses | Occurred | Passthrough |
| etr_y | Generic Pipeline | — | Year extract from source timestamp |
| etr_ym | Generic Pipeline | — | Year-month extract from source timestamp |
| etr_ymd | Generic Pipeline | — | Full date extract from source timestamp |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load time |
| partition_date | Generic Pipeline | — | DATE partition key from source timestamp |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.SentTransactionStatuses (PROD, WalletDB server)
  |-- Generic Pipeline (Append, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/SentTransactionStatuses/ (Data Lake)
  |-- CopyFromLake / EXW_Wallet schema load ---|
  v
EXW_Wallet.SentTransactionStatuses (4.6M rows, Synapse)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_senttransactionstatuses (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| SentTransactionId | EXW_Wallet.SentTransactions.Id | Parent sent transaction |
| StatusId | CopyFromLake.WalletDB_Dictionary_TransactionStatus.Id | Status name lookup |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Type | Usage |
|---|---|---|
| EXW_Wallet.EXW_TransactionsView | View | Correlated subquery for latest StatusId and LastStatusUpdateOccurred |
| EXW_dbo.SP_EXW_C2F_E2E | Stored Procedure | JOIN to resolve latest sent transaction status in C2F end-to-end reconciliation |

---

## 7. Sample Queries

### 7.1 Latest Status per Sent Transaction

```sql
SELECT
    sts.SentTransactionId,
    sts.StatusId,
    dts.Name AS StatusName,
    sts.Occurred
FROM EXW_Wallet.SentTransactionStatuses sts
JOIN CopyFromLake.WalletDB_Dictionary_TransactionStatus dts
    ON dts.Id = sts.StatusId
WHERE sts.Id = (
    SELECT MAX(s2.Id)
    FROM EXW_Wallet.SentTransactionStatuses s2
    WHERE s2.SentTransactionId = sts.SentTransactionId
)
AND sts.partition_date >= '2026-01-01';
```

### 7.2 Status Transition History for a Specific Transaction

```sql
SELECT
    sts.Id,
    sts.StatusId,
    dts.Name AS StatusName,
    sts.Occurred
FROM EXW_Wallet.SentTransactionStatuses sts
JOIN CopyFromLake.WalletDB_Dictionary_TransactionStatus dts
    ON dts.Id = sts.StatusId
WHERE sts.SentTransactionId = 845036
ORDER BY sts.Id ASC;
```

### 7.3 Daily Error Rate

```sql
SELECT
    CAST(Occurred AS DATE) AS StatusDate,
    COUNT(*) AS total_transitions,
    SUM(CASE WHEN StatusId IN (3, 4, 5) THEN 1 ELSE 0 END) AS error_count,
    CAST(SUM(CASE WHEN StatusId IN (3, 4, 5) THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS error_pct
FROM EXW_Wallet.SentTransactionStatuses
WHERE partition_date >= '2026-01-01'
GROUP BY CAST(Occurred AS DATE)
ORDER BY StatusDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 13/14*
*Tiers: 0 T1, 5 T2, 4 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.SentTransactionStatuses | Type: Table | Production Source: WalletDB.Wallet.SentTransactionStatuses*
