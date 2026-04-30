# AffiliateCommission.RemoveRegistrationExpiredEvents

> Purges registration events that have exceeded the retention window for a given source, removing stale records that were never successfully processed. Created PART-1195.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes expired RegistrationEvent rows by Source |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveRegistrationExpiredEvents is the scheduled maintenance procedure for the registration event table, introduced alongside the registration commission model in PART-1195. While individual registration events are normally removed by RemoveRegistrationEvent after successful processing, some events may linger if the commission engine encounters unrecoverable errors or if a source pipeline is retired.

This procedure uses a different date comparison pattern than its closed-position and credit counterparts. Instead of adding the expiration window to the event date and comparing against now, it subtracts the expiration window from now and compares against the RegistrationDate. The effect is identical - events older than @ExpirationInDays are deleted - but the WHERE clause reads as RegistrationDate < DATEADD(DAY, -@ExpirationInDays, GETUTCDATE()), which expresses the cutoff as an absolute timestamp.

The per-source scoping allows independent retention policies across different registration pipelines. For instance, a real-time API source might use a 30-day window while a batch reconciliation source might retain events for 90 days.

---

## 2. Business Logic

### 2.1 Source-Scoped Expiration Cleanup

**What**: Deletes registration events older than the retention window for a specific source.

**Columns/Parameters Involved**: `@ExpirationInDays`, `@Source`, `RegistrationEvent.RegistrationDate`, `RegistrationEvent.Source`

**Rules**:
- DELETE FROM RegistrationEvent WHERE Source = @Source AND RegistrationDate < DATEADD(DAY, -@ExpirationInDays, GETUTCDATE())
- Events are expired when their RegistrationDate is before the cutoff timestamp
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
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | Retention window in days. Events with a RegistrationDate more than this many days in the past are deleted. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition to clean up. Only events from this source are removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Source, RegistrationDate | AffiliateCommission.RegistrationEvent | WRITE (DELETE) | Removes expired rows filtered by Source and RegistrationDate |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline as a scheduled cleanup job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveRegistrationExpiredEvents (procedure)
+-- AffiliateCommission.RegistrationEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEvent | Table | DELETE with Source + date filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Scheduled cleanup of expired registration events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove expired registration events older than 30 days for Main source
```sql
EXEC [AffiliateCommission].[RemoveRegistrationExpiredEvents]
    @ExpirationInDays = 30, @Source = N'Main'
```

### 8.2 Preview events that would be expired
```sql
SELECT ID, CID, RegistrationDate, [Source]
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
WHERE [Source] = N'Main'
  AND RegistrationDate < DATEADD(DAY, -30, GETUTCDATE())
```

### 8.3 Check registration event age distribution by source
```sql
SELECT [Source],
    COUNT(*) AS TotalEvents,
    MIN(RegistrationDate) AS OldestEvent,
    MAX(RegistrationDate) AS NewestEvent,
    DATEDIFF(DAY, MIN(RegistrationDate), GETUTCDATE()) AS OldestAgeDays
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-1195: Registration commission events

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveRegistrationExpiredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveRegistrationExpiredEvents.sql*
