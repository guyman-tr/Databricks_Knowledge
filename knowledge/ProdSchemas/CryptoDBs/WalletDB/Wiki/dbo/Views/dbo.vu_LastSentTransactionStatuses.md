# dbo.vu_LastSentTransactionStatuses

> Schema-bound view that ranks sent transaction statuses by recency, enabling retrieval of each transaction's latest (most recent) status via RowNumber = 1 filter.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: Wallet.SentTransactionStatuses |
| **Partition** | N/A |
| **Indexes** | N/A (but SCHEMABINDING enables potential indexed view creation) |

---

## 1. Business Meaning

This view provides a way to retrieve the latest status of each sent transaction without needing a complex subquery or CTE. Sent transactions go through multiple status changes (each recorded as a row in `Wallet.SentTransactionStatuses`), and this view adds a `RowNumber` column partitioned by `SentTransactionId` and ordered by `Occurred DESC`. Filtering to `RowNumber = 1` returns only the most recent status for each transaction.

Without this view, every query needing the current status of a sent transaction would need to replicate the `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC)` window function. The view centralizes this pattern and, critically, uses `WITH SCHEMABINDING` which means the underlying table cannot be altered without first dropping this view - providing schema stability guarantees.

The view reads from `Wallet.SentTransactionStatuses`, which tracks status progression of outbound crypto transactions (blockchain sends). This is a read-only view with no procedures writing through it.

---

## 2. Business Logic

### 2.1 Most-Recent-Status Pattern

**What**: ROW_NUMBER partitioning identifies the latest status entry for each sent transaction.

**Columns/Parameters Involved**: `SentTransactionID`, `Occurred`, `RowNumber`

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC)` assigns RowNumber=1 to the most recent status
- WHERE RowNumber = 1 retrieves exactly one row per SentTransactionId - the current status
- Without the filter, all historical statuses are visible with their rank

---

## 3. Data Overview

| id | SentTransactionID | statusId | Occurred | RowNumber | Meaning |
|---|---|---|---|---|---|
| 3894 | 1 | 4 (Timeout) | 2018-10-14 | 1 | First-ever sent transaction's latest status is Timeout - early system testing artifact |
| 2430 | 2 | 2 (Verified) | 2018-07-31 | 1 | Second transaction ended in Verified status - successfully confirmed on blockchain |
| 2431 | 3 | 2 (Verified) | 2018-07-31 | 1 | Batch of transactions verified on the same date - normal batch processing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | (bigint) | NO | - | CODE-BACKED | Status record identifier from Wallet.SentTransactionStatuses. Unique ID for each status entry (not the transaction ID). |
| 2 | SentTransactionID | (bigint) | NO | - | CODE-BACKED | Sent transaction identifier. Partition key for the ROW_NUMBER function. Groups all status entries for the same outbound crypto transaction. |
| 3 | statusId | (tinyint) | NO | - | VERIFIED | Transaction processing status: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. (Dictionary.TransactionStatus) |
| 4 | Occurred | (datetime2) | NO | - | CODE-BACKED | Timestamp when this status was recorded. Used as the ORDER BY DESC column for determining "most recent" status. |
| 5 | RowNumber | bigint | NO | - | VERIFIED | Computed rank: 1 = most recent status for this SentTransactionID, 2 = second most recent, etc. Filter to RowNumber = 1 to get current status only. Computed: `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC)`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base table) | Wallet.SentTransactionStatuses | FROM (SCHEMABINDING) | Single source table - provides all status records for sent transactions |
| statusId | Dictionary.TransactionStatus | Implicit | Status code lookup: 0=Pending through 6=WavedError |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.vu_LastSentTransactionStatuses (view)
  +-- Wallet.SentTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactionStatuses | Table | FROM with SCHEMABINDING - source of all status records |

### 6.2 Objects That Depend On This

No dependents found in SSDT code scan.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed, though SCHEMABINDING makes indexed view creation possible).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | Binding | View is schema-bound to Wallet.SentTransactionStatuses - the base table cannot be altered or dropped without first dropping this view |

---

## 8. Sample Queries

### 8.1 Get current status for all sent transactions
```sql
SELECT SentTransactionID, statusId, Occurred
FROM dbo.vu_LastSentTransactionStatuses WITH (NOLOCK)
WHERE RowNumber = 1
ORDER BY SentTransactionID DESC
```

### 8.2 Find transactions stuck in error or timeout
```sql
SELECT SentTransactionID, statusId, Occurred
FROM dbo.vu_LastSentTransactionStatuses WITH (NOLOCK)
WHERE RowNumber = 1
  AND statusId IN (3, 4, 5)
ORDER BY Occurred DESC
```

### 8.3 Status distribution with readable names
```sql
SELECT ts.Name AS Status, COUNT(*) AS Cnt
FROM dbo.vu_LastSentTransactionStatuses v WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON ts.Id = v.statusId
WHERE v.RowNumber = 1
GROUP BY ts.Name
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.vu_LastSentTransactionStatuses | Type: View | Source: WalletDB/dbo/Views/dbo.vu_LastSentTransactionStatuses.sql*
