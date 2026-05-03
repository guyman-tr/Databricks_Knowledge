# EXW_Wallet.RequestStatuses

> 48.4M-row status-history staging table tracking every state transition for wallet requests (crypto sends, conversions, redemptions) from WalletDB production, spanning 2018-07-11 to present. Loaded daily via Generic Pipeline (Append strategy) from `WalletDB.Wallet.RequestStatuses`. Each row records a single status event for a request; a request typically accumulates multiple status rows forming a state machine (Start → ExecuterEnqueued → ReadByExecuter → … → Done/Error). Consumed by `SP_EXW_C2F_E2E` (C2F/C2P end-to-end reconciliation) and `SP_EXW_FactRedeemTransactions` (redemption tracking).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.RequestStatuses (Generic Pipeline, Append) |
| **Refresh** | Daily (every 1440 minutes), Append strategy |
| **Synapse Distribution** | HASH(RequestId) |
| **Synapse Index** | HEAP + NCI on partition_date ASC |
| **UC Target** | `wallet.bronze_walletdb_wallet_requeststatuses` |
| **UC Format** | delta |
| **UC Partitioned By** | None (inferred) |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

`EXW_Wallet.RequestStatuses` is a bronze staging table that captures the full status-change history for wallet requests in the eToro crypto wallet platform. Each row represents a single status transition event, identified by a surrogate `Id`, linked to a parent request via `RequestId`, and recording the new status (`RequestStatusId`) along with the `Timestamp` of the transition.

The status lifecycle follows a state machine pattern with 29 known status values (e.g., 0=Start, 1=Done, 2=Error, 3=ExecuterEnqueued, 4=ReadByExecuter, 5=TransactionSentToBlockChain, 6=TransactionConfirmed, 7=TransactionVerified, 8=AmlEnqueued, 16=TemporaryError, etc.). A single request generates multiple rows as it progresses through the pipeline. Downstream SPs use `ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC)` to extract the latest status per request.

The table is loaded daily via the Generic Pipeline (Append) from `WalletDB.Wallet.RequestStatuses`. No writer SP exists in Synapse — the data arrives through the CopyFromLake ingestion layer. The `RequestStatusId` resolves to human-readable names via `CopyFromLake.WalletDB_Dictionary_RequestStatuses`.

The dominant status is `ReadByExecuter` (4) at ~24.1M rows (49.8%), followed by `Start` (0) at ~5M rows, `ExecuterEnqueued` (3) at ~3.9M, and `Done` (1) at ~3.8M.

---

## 2. Business Logic

### 2.1 State Machine — Request Lifecycle

**What**: Each wallet request accumulates status rows over time, forming a state machine from initiation to completion or failure.
**Columns Involved**: `RequestId`, `RequestStatusId`, `Timestamp`
**Rules**:
- A request starts with status 0 (Start) and progresses through intermediate states.
- Terminal states are 1 (Done) and 2 (Error).
- Intermediate states include queue/processing stages: 3 (ExecuterEnqueued), 4 (ReadByExecuter), 5 (TransactionSentToBlockChain), 6 (TransactionConfirmed), 7 (TransactionVerified), 8 (AmlEnqueued), 9 (ReadByAml).
- Status 16 (TemporaryError) may recover; status 41 (AmlFailed) is a terminal AML failure.
- Newer statuses (28–42) cover staking, conversion-to-fiat, bounce-back, and travel-rule flows.

### 2.2 Latest-Status Extraction Pattern

**What**: Downstream SPs extract the most recent status per request using window functions.
**Columns Involved**: `RequestId`, `RequestStatusId`, `Timestamp`
**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC) = 1` yields the current status.
- `SP_EXW_C2F_E2E` uses this pattern to determine `RequestLastStatusID` and `RequestLastStatus` for C2F and C2P reconciliation.
- `SP_EXW_FactRedeemTransactions` uses `ROW_NUMBER() OVER (PARTITION BY CorrelationId ORDER BY Timestamp DESC, Id DESC)` — adding `Id DESC` as a tiebreaker when timestamps collide.

### 2.3 DetailsJson — Optional Context Payload

**What**: Some status transitions carry a JSON payload with additional context.
**Columns Involved**: `DetailsJson`
**Rules**:
- ~85% of rows have NULL or empty `DetailsJson` (41.3M of 48.4M).
- ~7.2M rows carry a non-empty JSON payload, typically for error details or processing metadata.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: `HASH(RequestId)` — ensures all status rows for the same request are co-located on the same distribution, making the `ROW_NUMBER() OVER (PARTITION BY RequestId ...)` pattern efficient.
- **Index**: HEAP with a non-clustered index on `partition_date` — supports date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| What is the current status of a request? | `ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC) = 1` |
| How many requests completed today? | Filter `RequestStatusId = 1 AND partition_date = @today` |
| What is the error rate? | Compare `RequestStatusId = 2` count vs total distinct `RequestId` |
| Status distribution over time? | `GROUP BY partition_date, RequestStatusId` with date-range filter |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.Requests | `Requests.Id = RequestStatuses.RequestId` | Get request metadata (CorrelationId, Gcid, CryptoId, RequestTypeId) |
| CopyFromLake.WalletDB_Dictionary_RequestStatuses | `Dict.Id = RequestStatuses.RequestStatusId` | Resolve status ID to human-readable name |
| EXW_Wallet.SentTransactions | Via Requests.CorrelationId | Link request to blockchain sent transaction |

### 3.4 Gotchas

- **Multiple rows per request**: This is a status-history table, not a current-state table. Always use `ROW_NUMBER()` to get the latest status, or filter for specific `RequestStatusId` values.
- **Timestamp tiebreakers**: Two statuses can share the same `Timestamp` for a given request. Use `Id DESC` as a secondary sort (as `SP_EXW_FactRedeemTransactions` does).
- **etr_* columns partially populated**: Older rows have `etr_y`/`etr_ym`/`etr_ymd` values; newer rows may have these empty. Use `partition_date` for reliable date filtering.
- **DetailsJson sparsity**: ~85% of rows have empty/NULL `DetailsJson`. Do not rely on it for completeness.
- **48.4M rows**: Apply `partition_date` filters to avoid full table scans. Do not run unfiltered `GROUP BY` or `COUNT(*)`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from ETL/SP code with transform |
| Tier 3 | Inferred from DDL, data sample, and consuming SP code; no upstream wiki available |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Surrogate row identifier for each status-change event. Unique per status transition row. Used as a tiebreaker in `ROW_NUMBER()` ordering when timestamps collide. (Tier 3 — WalletDB.Wallet.RequestStatuses) |
| 2 | RequestId | bigint | YES | Foreign key to `EXW_Wallet.Requests.Id`. Identifies the parent wallet request that this status event belongs to. Distribution key — all status rows for the same request are co-located. (Tier 3 — WalletDB.Wallet.RequestStatuses) |
| 3 | RequestStatusId | int | YES | Status code for this transition event. FK to `CopyFromLake.WalletDB_Dictionary_RequestStatuses`. 29 known values: 0=Start, 1=Done, 2=Error, 3=ExecuterEnqueued, 4=ReadByExecuter, 5=TransactionSentToBlockChain, 6=TransactionConfirmed, 7=TransactionVerified, 8=AmlEnqueued, 9=ReadByAml, 16=TemporaryError, 35=SendTransactionOrchestratorEnqueued, 41=AmlFailed, 42=TravelRuleMessageCreated, and others. (Tier 3 — WalletDB.Wallet.RequestStatuses) |
| 4 | Timestamp | datetime2(7) | YES | Date and time when this status transition occurred. Used as the primary ordering column in `ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC)` to determine the latest status. (Tier 3 — WalletDB.Wallet.RequestStatuses) |
| 5 | DetailsJson | varchar(max) | YES | Optional JSON payload containing additional context for the status transition (e.g., error details, processing metadata). NULL or empty in ~85% of rows. (Tier 3 — WalletDB.Wallet.RequestStatuses) |
| 6 | etr_y | varchar(max) | YES | ETL year partition column, populated by the Generic Pipeline during ingestion. Contains the 4-digit year (e.g., '2023'). Partially populated — newer rows may have this empty. (Tier 2 — Generic Pipeline) |
| 7 | etr_ym | varchar(max) | YES | ETL year-month partition column, populated by the Generic Pipeline during ingestion. Format: 'YYYY-MM' (e.g., '2023-06'). Partially populated — newer rows may have this empty. (Tier 2 — Generic Pipeline) |
| 8 | etr_ymd | varchar(max) | YES | ETL year-month-day partition column, populated by the Generic Pipeline during ingestion. Format: 'YYYY-MM-DD' (e.g., '2023-06-13'). Partially populated — newer rows may have this empty. (Tier 2 — Generic Pipeline) |
| 9 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded into Synapse by the Generic Pipeline ingestion process. NULL for some older rows. (Tier 2 — Generic Pipeline) |
| 10 | partition_date | date | YES | Date-based partition column derived from the source event date. Aligned with the `Timestamp` column's date component. Indexed (NCI) for efficient date-range filtering. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Id | WalletDB.Wallet.RequestStatuses | Id | Passthrough |
| RequestId | WalletDB.Wallet.RequestStatuses | RequestId | Passthrough |
| RequestStatusId | WalletDB.Wallet.RequestStatuses | RequestStatusId | Passthrough |
| Timestamp | WalletDB.Wallet.RequestStatuses | Timestamp | Passthrough |
| DetailsJson | WalletDB.Wallet.RequestStatuses | DetailsJson | Passthrough |
| etr_y | — | — | Generic Pipeline ETL column |
| etr_ym | — | — | Generic Pipeline ETL column |
| etr_ymd | — | — | Generic Pipeline ETL column |
| SynapseUpdateDate | — | — | Generic Pipeline ingestion timestamp |
| partition_date | — | — | Generic Pipeline partition date |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.RequestStatuses (production, WalletDB server)
  |-- Generic Pipeline (Append, daily/1440 min, parquet) ---|
  v
Bronze/WalletDB/Wallet/RequestStatuses/ (Data Lake)
  |-- CopyFromLake ingestion ---|
  v
EXW_Wallet.RequestStatuses (Synapse, 48.4M rows, HASH(RequestId))
  |-- Generic Pipeline (Bronze export) ---|
  v
wallet.bronze_walletdb_wallet_requeststatuses (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RequestId | EXW_Wallet.Requests | Parent request this status event belongs to |
| RequestStatusId | CopyFromLake.WalletDB_Dictionary_RequestStatuses | Status name lookup (29 values) |
| RequestStatusId | EXW_Dictionary.RequestStatuses | Alternate dictionary copy with same Id/Name mapping |

### 6.2 Referenced By (other objects point to this)

| Consumer | Relationship | Description |
|----------|-------------|-------------|
| EXW_dbo.SP_EXW_C2F_E2E | Reader | Joins to Requests for C2F/C2P end-to-end reconciliation — determines latest request status |
| EXW_dbo.SP_EXW_FactRedeemTransactions | Reader | Joins to Requests for redemption status determination (Done/Error/Pending) |

---

## 7. Sample Queries

### 7.1 Latest Status Per Request (Last 7 Days)

```sql
SELECT rs.RequestId,
       rs.RequestStatusId,
       d.Name AS StatusName,
       rs.Timestamp
FROM EXW_Wallet.RequestStatuses rs
JOIN CopyFromLake.WalletDB_Dictionary_RequestStatuses d
  ON d.Id = rs.RequestStatusId
WHERE rs.partition_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
  AND ROW_NUMBER() OVER (PARTITION BY rs.RequestId ORDER BY rs.Timestamp DESC, rs.Id DESC) = 1
```

> Note: Use a subquery/CTE with `ROW_NUMBER()` in practice, as window functions cannot appear in WHERE directly.

### 7.2 Daily Status Distribution

```sql
SELECT rs.partition_date,
       rs.RequestStatusId,
       d.Name AS StatusName,
       COUNT(*) AS status_count
FROM EXW_Wallet.RequestStatuses rs
JOIN CopyFromLake.WalletDB_Dictionary_RequestStatuses d
  ON d.Id = rs.RequestStatusId
WHERE rs.partition_date >= '2026-01-01'
GROUP BY rs.partition_date, rs.RequestStatusId, d.Name
ORDER BY rs.partition_date DESC, status_count DESC
```

### 7.3 Error Rate by Day

```sql
WITH latest AS (
  SELECT RequestId,
         RequestStatusId,
         partition_date,
         ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY Timestamp DESC, Id DESC) AS rn
  FROM EXW_Wallet.RequestStatuses
  WHERE partition_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
)
SELECT partition_date,
       COUNT(*) AS total_requests,
       SUM(CASE WHEN RequestStatusId = 2 THEN 1 ELSE 0 END) AS errors,
       CAST(SUM(CASE WHEN RequestStatusId = 2 THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS error_pct
FROM latest
WHERE rn = 1
GROUP BY partition_date
ORDER BY partition_date DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources were searched for this object (dormant/staging table, Phase 10 skipped).

---

*Generated: 2026-04-30 | Quality: 7/10 | Phases: 12/14*
*Tiers: 0 T1, 5 T2, 5 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.RequestStatuses | Type: Table | Production Source: WalletDB.Wallet.RequestStatuses*
