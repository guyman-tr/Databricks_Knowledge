# AffiliateCommission.RemoveClosedPositionExpiredEvents

> Purges closed position events that have exceeded the retention window for a given source, preventing unbounded table growth from events that were never picked up or reprocessed.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes expired ClosedPositionEvent rows by Source |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveClosedPositionExpiredEvents is a scheduled maintenance procedure that removes stale closed position events beyond the configured retention period. While individual events are normally removed by RemoveClosedPositionEvent after successful processing, some events may linger - perhaps the commission engine skipped them due to missing affiliate data, or a transient failure prevented the post-processing cleanup from executing.

This procedure operates per-source, allowing different processing pipelines to have independent retention policies. For example, the primary "Main" source might retain events for 30 days while a secondary reconciliation source retains them for 90 days. The @ExpirationInDays parameter controls the lookback window: any event whose Occurred timestamp is older than today minus the expiration days is deleted.

The scoped-by-source design also prevents a cleanup run for one pipeline from accidentally removing events that another pipeline still needs. Each source partition manages its own lifecycle independently.

---

## 2. Business Logic

### 2.1 Source-Scoped Expiration Cleanup

**What**: Deletes closed position events older than the retention window for a specific source.

**Columns/Parameters Involved**: `@ExpirationInDays`, `@Source`, `ClosedPositionEvent.Occurred`, `ClosedPositionEvent.Source`

**Rules**:
- DELETE FROM ClosedPositionEvent WHERE Source = @Source AND DATEADD(DAY, @ExpirationInDays, Occurred) < GETUTCDATE()
- Events are expired when their Occurred date plus the expiration window is in the past
- Only events matching the specified @Source are affected
- Typically called by a scheduled job (e.g., daily or weekly maintenance)
- May delete zero or many rows depending on volume and retention settings

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | Retention window in days. Events older than this many days past their Occurred date are deleted. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition to clean up. Only events from this source are removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Source, Occurred | AffiliateCommission.ClosedPositionEvent | WRITE (DELETE) | Removes expired rows filtered by Source and Occurred date |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline as a scheduled cleanup job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveClosedPositionExpiredEvents (procedure)
+-- AffiliateCommission.ClosedPositionEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionEvent | Table | DELETE with Source + date filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Scheduled cleanup of expired closed position events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove expired events older than 30 days for Main source
```sql
EXEC [AffiliateCommission].[RemoveClosedPositionExpiredEvents]
    @ExpirationInDays = 30, @Source = N'Main'
```

### 8.2 Preview events that would be expired
```sql
SELECT ID, ClosedPositionID, Occurred, [Source]
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
WHERE [Source] = N'Main'
  AND DATEADD(DAY, 30, Occurred) < GETUTCDATE()
```

### 8.3 Check event age distribution by source
```sql
SELECT [Source],
    COUNT(*) AS TotalEvents,
    MIN(Occurred) AS OldestEvent,
    MAX(Occurred) AS NewestEvent,
    DATEDIFF(DAY, MIN(Occurred), GETUTCDATE()) AS OldestAgeDays
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveClosedPositionExpiredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveClosedPositionExpiredEvents.sql*
