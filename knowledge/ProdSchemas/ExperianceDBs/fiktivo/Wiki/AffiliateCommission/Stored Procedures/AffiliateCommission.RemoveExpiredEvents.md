# AffiliateCommission.RemoveExpiredEvents

> Performs a global cleanup of all expired credit events regardless of source, removing any CreditEvent row whose CreditDate is older than the specified retention window.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes all expired CreditEvent rows globally |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveExpiredEvents is the broadest cleanup procedure in the credit event lifecycle. Unlike RemoveCreditExpiredEvents, which targets a specific source partition, this procedure sweeps the entire CreditEvent table and removes every event whose CreditDate has exceeded the retention window. It serves as a last-resort safety valve to prevent the table from growing indefinitely.

This global approach is useful in scenarios where source-specific cleanup may not cover all records. For example, if a new source is introduced but its cleanup schedule is not yet configured, events from that source would accumulate without limit. RemoveExpiredEvents catches these orphans by applying a uniform expiration policy across all sources.

The procedure is typically scheduled to run less frequently than source-specific cleanup (e.g., weekly rather than daily) with a longer retention window, acting as a backstop rather than the primary cleanup mechanism. This layered approach - individual deletes after processing, source-scoped daily cleanup, and global weekly cleanup - ensures the credit event table remains manageable under all operational conditions.

---

## 2. Business Logic

### 2.1 Global Expiration Cleanup

**What**: Deletes all credit events older than the retention window, regardless of source.

**Columns/Parameters Involved**: `@ExpirationInDays`, `CreditEvent.CreditDate`

**Rules**:
- DELETE FROM CreditEvent WHERE DATEADD(DAY, @ExpirationInDays, CreditDate) < GETUTCDATE()
- No source filter - all sources are affected
- Events are expired when their CreditDate plus the expiration window is in the past
- Typically called by a less-frequent scheduled job (e.g., weekly maintenance)
- May delete zero or many rows across all sources

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | Retention window in days. All credit events with a CreditDate older than this many days ago are deleted, regardless of source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditDate | AffiliateCommission.CreditEvent | WRITE (DELETE) | Removes all expired rows based on CreditDate |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline as a global scheduled cleanup job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveExpiredEvents (procedure)
+-- AffiliateCommission.CreditEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | DELETE with global date filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Global scheduled cleanup of all expired credit events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove all expired credit events older than 60 days
```sql
EXEC [AffiliateCommission].[RemoveExpiredEvents] @ExpirationInDays = 60
```

### 8.2 Preview all events that would be expired globally
```sql
SELECT ID, CreditID, CreditDate, [Source]
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
WHERE DATEADD(DAY, 60, CreditDate) < GETUTCDATE()
ORDER BY CreditDate ASC
```

### 8.3 Check expiration candidates by source
```sql
SELECT [Source],
    COUNT(*) AS ExpiredCount,
    MIN(CreditDate) AS OldestCreditDate
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
WHERE DATEADD(DAY, 60, CreditDate) < GETUTCDATE()
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveExpiredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveExpiredEvents.sql*
