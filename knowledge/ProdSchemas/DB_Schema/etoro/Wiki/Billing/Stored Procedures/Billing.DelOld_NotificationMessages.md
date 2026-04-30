# Billing.DelOld_NotificationMessages

> Batch-deletes expired payment provider notification messages from Billing.NotificationMessages in configurable batch sizes, implementing a rolling 31-day retention policy to prevent table growth.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes rows older than @DaysToKeep days in batches of @BatchSize |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DelOld_NotificationMessages` is the retention maintenance procedure for `Billing.NotificationMessages`, the landing table for inbound payment provider webhooks (WorldPay, Checkout.com callbacks). It purges notification records older than the configured retention period (default: 31 days) in controlled batches, keeping the table small and its indexes efficient.

`Billing.NotificationMessages` is a short-lived staging buffer - messages are written by the billing notification gateway, processed asynchronously by a background worker, and then no longer needed. Without periodic purging, the table would grow indefinitely with processed records that serve no further purpose. The 31-day default retention provides a reasonable window for debugging and reconciliation if payment events are disputed or misprocessed within the past month.

The batched deletion strategy (default: 4,500 rows at a time) is intentional for performance: large bulk deletes on transactional tables generate significant log activity and lock contention. The WHILE loop continues batching until there are no more old records to delete, ensuring complete cleanup in a single execution without overwhelming transaction log or blocking payment processing.

---

## 2. Business Logic

### 2.1 Batched Retention Purge Loop

**What**: Repeatedly deletes expired notification records in controlled batches until no more qualify.

**Columns/Parameters Involved**: `@DaysToKeep`, `@BatchSize`, `Billing.NotificationMessages.Created`

**Rules**:
- Loop: `DELETE TOP (@BatchSize) WHERE Created < DATEADD(DD, -@DaysToKeep, GETUTCDATE())`
- After each batch: check `@@ROWCOUNT = 0` -> if true, BREAK (no more records to delete)
- Default retention: 31 days (1 month rolling window)
- Default batch size: 4500 rows - chosen to balance throughput against lock contention
- Infinite loop safety: terminates automatically when no qualifying rows remain
- Typically called by a scheduled SQL Agent job during off-peak hours

**Diagram**:
```
WHILE 1=1
    DELETE TOP 4500
    FROM Billing.NotificationMessages
    WHERE Created < (now - 31 days)
         |
    @@ROWCOUNT = 0?
    YES -> BREAK (all old records purged)
    NO -> continue next batch
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysToKeep | INT | NO | 31 | CODE-BACKED | Number of days of notification history to retain. Records with Created timestamp older than this are eligible for deletion. Default of 31 days matches a rolling monthly retention policy - sufficient for payment dispute investigation windows. |
| 2 | @BatchSize | INT | NO | 4500 | CODE-BACKED | Maximum number of rows to delete in a single DELETE statement. Controls the transaction size and log generation. Default of 4500 balances throughput with performance impact on concurrent payment processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Created filter | Billing.NotificationMessages | Delete | Batch-deletes expired notification messages from the payment provider webhook staging table. See [Billing.NotificationMessages](../Tables/Billing.NotificationMessages.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Typically called by a SQL Server Agent scheduled maintenance job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DelOld_NotificationMessages (procedure)
└── Billing.NotificationMessages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.NotificationMessages | Table | DELETE target; purges records older than @DaysToKeep days in batches |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Maintenance Job | External | Calls this procedure on a scheduled basis (typically nightly) to enforce the 31-day retention policy |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with default 31-day retention and 4500-row batch size

```sql
EXEC Billing.DelOld_NotificationMessages;
```

### 8.2 Aggressive cleanup: shorter retention, smaller batches (avoid peak-hour impact)

```sql
EXEC Billing.DelOld_NotificationMessages
    @DaysToKeep = 14,
    @BatchSize = 1000;
```

### 8.3 Check how many records would be purged by the default policy

```sql
SELECT COUNT(*) AS RecordsToDelete,
       MIN(Created) AS OldestRecord,
       MAX(Created) AS NewestEligibleRecord
FROM Billing.NotificationMessages WITH (NOLOCK)
WHERE Created < DATEADD(DAY, -31, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DelOld_NotificationMessages | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DelOld_NotificationMessages.sql*
