# EXW_Wallet.ReceivedTransactionStatuses

> 5.6M-row status history table tracking every state transition of incoming cryptocurrency transactions in eToroX wallets from September 2018 to present — recording the status (Pending → Confirmed → Verified / Error), timestamp, and error details for each received transaction. Loaded via CopyFromLake Generic Pipeline (Append, daily) from WalletDB.Wallet.ReceivedTransactionStatuses. Production source: WalletDB (eToroX Wallet service).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.ReceivedTransactionStatuses (CopyFromLake Generic Pipeline) |
| **Refresh** | Every 1440 minutes / daily (Append strategy) |
| **Synapse Distribution** | HASH([ReceivedTransactionId]) |
| **Synapse Index** | HEAP |
| **Index** | NCI on partition_date (XI_partition_date) |
| **UC Target** | `wallet.bronze_walletdb_wallet_receivedtransactionstatuses` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.ReceivedTransactionStatuses is a bronze-layer status history table that records every state transition for incoming cryptocurrency transactions on eToroX wallet addresses. Each row represents a single status change event — a received transaction moving from Pending to Confirmed, Verified, or into an error state.

The table contains 5,609,610 rows spanning from September 2018 to April 2026. It is loaded directly from the production WalletDB.Wallet.ReceivedTransactionStatuses table via the CopyFromLake Generic Pipeline with an Append strategy on a daily (1440-minute) cycle. No writer stored procedure transforms this data — it is a direct replica of the production source.

Each received transaction (in EXW_Wallet.ReceivedTransactions) can have multiple status rows here, forming a status history chain ordered by `Id`. Downstream consumers use a "latest status wins" pattern: `SELECT TOP 1 StatusId ... WHERE ReceivedTransactionId = rt.Id ORDER BY Id DESC`.

The 7 status values (from EXW_Dictionary.TransactionStatus) are: 0=Pending (47%), 2=Verified (47%), 1=Confirmed (6%), 3=Error (<1%), 6=WavedError (<1%), 4=Timeout (<1%), 5=PermanentError (<1%). The typical lifecycle is Pending → Confirmed → Verified.

The `DetailsJson` column stores error context as JSON when a transaction enters an error state (StatusId 3/4/5/6), containing ErrorSourceType, ErrorCode, and ErrorMessage from the blockchain provider (e.g., BitGo 503 upstream errors).

---

## 2. Business Logic

### 2.1 Status Lifecycle

**What**: Each received transaction progresses through a status lifecycle tracked by multiple rows in this table.
**Columns Involved**: `ReceivedTransactionId`, `StatusId`, `Occurred`, `Id`
**Rules**:
- The latest status is determined by the highest `Id` for a given `ReceivedTransactionId`
- Typical happy path: Pending (0) → Confirmed (1) → Verified (2)
- Error path: Pending (0) → Error (3) / Timeout (4) / PermanentError (5)
- WavedError (6) indicates an error that was manually waived/resolved

### 2.2 Latest-Status-Wins Pattern

**What**: Downstream views and SPs retrieve only the most recent status for each transaction.
**Columns Involved**: `ReceivedTransactionId`, `StatusId`, `Id`, `Occurred`
**Rules**:
- EXW_TransactionsView uses: `SELECT TOP 1 StatusId FROM ReceivedTransactionStatuses WHERE ReceivedTransactionId = rt.Id ORDER BY Id DESC`
- Also retrieves `LastStatusUpdateOccurred` via: `SELECT TOP 1 Occurred ... ORDER BY Id DESC`
- The `Id` ordering (not `Occurred`) is the authoritative sequence — concurrent status updates may share timestamps

### 2.3 Error Details Capture

**What**: When a transaction enters an error state, the JSON error context is stored for diagnostic purposes.
**Columns Involved**: `DetailsJson`, `StatusId`
**Rules**:
- `DetailsJson` is populated primarily for error statuses (3, 4, 5, 6)
- JSON structure: `{"ErrorSourceType": N, "ErrorCode": "NNN", "ErrorMessage": "..."}`
- ErrorSourceType 1 = blockchain provider (e.g., BitGo)
- Common errors: HTTP 503 upstream connect errors from BitGo

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH([ReceivedTransactionId]) — queries filtering or joining on `ReceivedTransactionId` are co-located on a single distribution
- HEAP storage (no clustered index) — typical for bronze staging tables
- NCI on `partition_date` — use `WHERE partition_date >= ...` for efficient date-range scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Latest status for a transaction | `SELECT TOP 1 StatusId FROM ... WHERE ReceivedTransactionId = @id ORDER BY Id DESC` |
| All status transitions for a transaction | `WHERE ReceivedTransactionId = @id ORDER BY Id ASC` |
| Error transactions in a date range | `WHERE StatusId IN (3, 4, 5, 6) AND partition_date >= '2026-01-01'` |
| Status distribution over time | `GROUP BY StatusId, etr_ym` with `partition_date` filter |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.ReceivedTransactions | ReceivedTransactionId = Id | Resolve parent transaction details (amount, wallet, crypto) |
| EXW_Dictionary.TransactionStatus | StatusId = Id | Resolve status name (Pending, Confirmed, Verified, etc.) |

### 3.4 Gotchas

- Multiple rows per `ReceivedTransactionId` — this is a history table, not a current-state table. Always use `ORDER BY Id DESC` with `TOP 1` for latest status
- `SynapseUpdateDate` is NULL for ~54% of rows (3M of 5.6M) — older rows loaded before this column was added
- `DetailsJson` is empty/null for most rows; only populated on error statuses. Values include the string `"null"` (as text) in some rows
- Distribution key is `ReceivedTransactionId`, not `Id` — queries filtering only on `Id` will scan all distributions

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | ETL-computed or pipeline-added column, described from CopyFromLake/Generic Pipeline logic |
| Tier 3 | No upstream wiki available; description grounded in DDL, sample data, and downstream usage |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the status record in WalletDB. Surrogate identity; used to determine ordering of status transitions (highest Id = latest status). Referenced by EXW_TransactionsView via `ORDER BY Id DESC` to retrieve the most recent status. (Tier 3 — WalletDB.Wallet.ReceivedTransactionStatuses) |
| 2 | ReceivedTransactionId | bigint | YES | FK to EXW_Wallet.ReceivedTransactions.Id. Identifies the parent received transaction this status belongs to. Distribution key for this table. Multiple status rows exist per transaction, forming a status history chain. (Tier 3 — WalletDB.Wallet.ReceivedTransactionStatuses) |
| 3 | StatusId | int | YES | FK to EXW_Dictionary.TransactionStatus. 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. Typical lifecycle: Pending → Confirmed → Verified. Recent distribution (2026): Pending 47%, Verified 47%, Confirmed 6%, Error/Timeout/WavedError/PermanentError <1%. (Tier 3 — WalletDB.Wallet.ReceivedTransactionStatuses) |
| 4 | Occurred | datetime2(7) | YES | Timestamp when this status transition occurred in the wallet service. Used by EXW_TransactionsView as `LastStatusUpdateOccurred` (latest status row's Occurred). Microsecond precision. (Tier 3 — WalletDB.Wallet.ReceivedTransactionStatuses) |
| 5 | DetailsJson | varchar(max) | YES | JSON error context populated on error statuses (StatusId 3/4/5/6). Structure: `{"ErrorSourceType": N, "ErrorCode": "NNN", "ErrorMessage": "..."}`. ErrorSourceType 1 = blockchain provider (BitGo). Empty or null for non-error statuses. Some rows contain the string `"null"`. (Tier 3 — WalletDB.Wallet.ReceivedTransactionStatuses) |
| 6 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column: 4-digit year extracted from the source record's date (e.g., "2022"). Populated for this table (unlike ReceivedTransactions where it is NULL). (Tier 2 — Generic Pipeline) |
| 7 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column: year-month (e.g., "2022-04"). Populated for this table. (Tier 2 — Generic Pipeline) |
| 8 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column: year-month-day (e.g., "2022-04-25"). Populated for this table. Matches the date portion of `Occurred`. (Tier 2 — Generic Pipeline) |
| 9 | SynapseUpdateDate | datetime | YES | Timestamp of the CopyFromLake data refresh into Synapse. Set to GETDATE() at load time. NULL for ~54% of rows (older loads before this column was added). When populated, shows the most recent reload timestamp (e.g., 2026-04-27 06:01:12). (Tier 2 — Generic Pipeline) |
| 10 | partition_date | date | YES | Date-based partition key derived from the source record. Matches the date portion of `Occurred`. Indexed (XI_partition_date) for efficient date-range filtering in downstream queries. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.ReceivedTransactionStatuses | Id | Passthrough |
| ReceivedTransactionId | WalletDB.Wallet.ReceivedTransactionStatuses | ReceivedTransactionId | Passthrough |
| StatusId | WalletDB.Wallet.ReceivedTransactionStatuses | StatusId | Passthrough |
| Occurred | WalletDB.Wallet.ReceivedTransactionStatuses | Occurred | Passthrough |
| DetailsJson | WalletDB.Wallet.ReceivedTransactionStatuses | DetailsJson | Passthrough |
| etr_y | Generic Pipeline | — | ETL year partition from Occurred |
| etr_ym | Generic Pipeline | — | ETL year-month partition from Occurred |
| etr_ymd | Generic Pipeline | — | ETL year-month-day partition from Occurred |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at CopyFromLake load |
| partition_date | Generic Pipeline | — | Date partition key from Occurred |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.ReceivedTransactionStatuses (production, eToroX Wallet service)
  |-- Generic Pipeline (Bronze export, Append, daily, parquet) --|
  v
Bronze/WalletDB/Wallet/ReceivedTransactionStatuses/ (Data Lake)
  |-- CopyFromLake (staging load) --|
  v
EXW_Wallet_tmp.ReceivedTransactionStatuses_tmp (5 prod cols + etr_y2/ym2/ymd2, ROUND_ROBIN)
  |-- CopyFromLake (final load, adds ETL columns: etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date) --|
  v
EXW_Wallet.ReceivedTransactionStatuses (5.6M rows, HASH(ReceivedTransactionId))
  |-- Consumed by --|
  v
EXW_Wallet.EXW_TransactionsView (received_transactions CTE — latest StatusId + LastStatusUpdateOccurred)
  |-- Generic Pipeline (Bronze UC export) --|
  v
wallet.bronze_walletdb_wallet_receivedtransactionstatuses (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| ReceivedTransactionId | EXW_Wallet.ReceivedTransactions | FK to Id. Parent received transaction this status belongs to. |
| StatusId | EXW_Dictionary.TransactionStatus | FK to Id. 7 status values (Pending, Confirmed, Verified, Error, Timeout, PermanentError, WavedError). |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| StatusId, Id, ReceivedTransactionId | EXW_Wallet.EXW_TransactionsView | Subquery retrieves latest StatusId and Occurred per ReceivedTransactionId via `ORDER BY Id DESC`. |

---

## 7. Sample Queries

### 7.1 Latest Status per Received Transaction (Recent)

```sql
SELECT
    rt.Id AS ReceivedTransactionId,
    rt.Amount,
    rts.StatusId,
    ts.Name AS StatusName,
    rts.Occurred AS StatusUpdated
FROM EXW_Wallet.ReceivedTransactions rt
CROSS APPLY (
    SELECT TOP 1 StatusId, Occurred
    FROM EXW_Wallet.ReceivedTransactionStatuses
    WHERE ReceivedTransactionId = rt.Id
    ORDER BY Id DESC
) rts
JOIN EXW_Dictionary.TransactionStatus ts ON ts.Id = rts.StatusId
WHERE rt.partition_date >= '2026-04-01'
```

### 7.2 Error Transactions with Details

```sql
SELECT
    rts.ReceivedTransactionId,
    ts.Name AS StatusName,
    rts.Occurred,
    rts.DetailsJson
FROM EXW_Wallet.ReceivedTransactionStatuses rts
JOIN EXW_Dictionary.TransactionStatus ts ON ts.Id = rts.StatusId
WHERE rts.StatusId IN (3, 4, 5, 6)
    AND rts.partition_date >= '2026-01-01'
ORDER BY rts.Occurred DESC
```

### 7.3 Status Distribution by Month

```sql
SELECT
    rts.etr_ym AS Month,
    ts.Name AS StatusName,
    COUNT(*) AS StatusCount
FROM EXW_Wallet.ReceivedTransactionStatuses rts
JOIN EXW_Dictionary.TransactionStatus ts ON ts.Id = rts.StatusId
WHERE rts.partition_date >= '2025-01-01'
GROUP BY rts.etr_ym, ts.Name
ORDER BY rts.etr_ym DESC, StatusCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen-harness mode).

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 5 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.ReceivedTransactionStatuses | Type: Table | Production Source: WalletDB.Wallet.ReceivedTransactionStatuses (CopyFromLake)*
