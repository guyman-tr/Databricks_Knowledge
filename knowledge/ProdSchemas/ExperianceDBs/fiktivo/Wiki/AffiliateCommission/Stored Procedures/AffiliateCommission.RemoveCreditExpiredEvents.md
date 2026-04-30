# AffiliateCommission.RemoveCreditExpiredEvents

> Purges credit events that have exceeded the retention window for a given source, removing stale records that were never successfully processed or cleaned up.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes expired CreditEvent rows by Source |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveCreditExpiredEvents is the scheduled safety net for the credit event table. In the normal flow, each credit event is individually removed by RemoveCreditEvent after successful commission processing. However, events can become orphaned - for example, if the commission engine encounters an unrecoverable error for a specific event, or if a source pipeline is decommissioned while events remain in the table.

This procedure sweeps the CreditEvent table for a specific source and removes any event whose CreditDate is older than the retention window. The @ExpirationInDays parameter defines that window: an event is expired when DATEADD(DAY, @ExpirationInDays, CreditDate) falls before the current UTC time. This date arithmetic uses the event's CreditDate (when the credit occurred) rather than when the event record was created.

Running cleanup per-source ensures that different pipelines can define independent retention policies. A high-volume real-time source might use a short 14-day window, while a monthly reconciliation source might keep events for 90 days. This isolation also prevents cross-pipeline interference during cleanup operations.

---

## 2. Business Logic

### 2.1 Source-Scoped Expiration Cleanup

**What**: Deletes credit events older than the retention window for a specific source.

**Columns/Parameters Involved**: `@ExpirationInDays`, `@Source`, `CreditEvent.CreditDate`, `CreditEvent.Source`

**Rules**:
- DELETE FROM CreditEvent WHERE Source = @Source AND DATEADD(DAY, @ExpirationInDays, CreditDate) < GETUTCDATE()
- Events are expired when their CreditDate plus the expiration window is in the past
- Only events matching the specified @Source are affected
- Typically called by a scheduled maintenance job
- May delete zero or many rows depending on volume and retention settings

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | Retention window in days. Events with a CreditDate older than this many days ago are deleted. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition to clean up. Only events from this source are removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Source, CreditDate | AffiliateCommission.CreditEvent | WRITE (DELETE) | Removes expired rows filtered by Source and CreditDate |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline as a scheduled cleanup job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveCreditExpiredEvents (procedure)
+-- AffiliateCommission.CreditEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | DELETE with Source + date filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Scheduled cleanup of expired credit events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove expired credit events older than 30 days for Main source
```sql
EXEC [AffiliateCommission].[RemoveCreditExpiredEvents]
    @ExpirationInDays = 30, @Source = N'Main'
```

### 8.2 Preview events that would be expired
```sql
SELECT ID, CreditID, CreditDate, [Source]
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
WHERE [Source] = N'Main'
  AND DATEADD(DAY, 30, CreditDate) < GETUTCDATE()
```

### 8.3 Check credit event age distribution by source
```sql
SELECT [Source],
    COUNT(*) AS TotalEvents,
    MIN(CreditDate) AS OldestEvent,
    MAX(CreditDate) AS NewestEvent,
    DATEDIFF(DAY, MIN(CreditDate), GETUTCDATE()) AS OldestAgeDays
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveCreditExpiredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveCreditExpiredEvents.sql*
