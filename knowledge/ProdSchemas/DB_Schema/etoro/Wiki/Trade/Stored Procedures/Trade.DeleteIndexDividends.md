# Trade.DeleteIndexDividends

> Bulk-deletes index dividend records by DividendID from a TVP, within an explicit transaction for atomicity.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DeleteIndexDividendsTbl (TVP of DividendIDs to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteIndexDividends performs a bulk deletion of index dividend records from Trade.IndexDividends using a table-valued parameter. Unlike Trade.DeleteDividend (which deletes a single record with status validation), this procedure deletes multiple records in a single transactional operation without checking their Status. It is designed for administrative bulk cleanup scenarios.

This procedure exists to support bulk dividend management when multiple dividend events need to be removed at once (e.g., rescheduling an entire set of dividend dates, correcting batch-imported dividend data).

Data flow: The caller provides a TVP (Trade.DeleteIndexDividendsTbl) containing one or more DividendIDs. The procedure deletes all matching rows from Trade.IndexDividends within an explicit transaction. RETURN 0 signals success. Error handling with TRY/CATCH and transaction rollback ensures atomicity.

---

## 2. Business Logic

### 2.1 Transactional Bulk Delete

**What**: All specified dividends are deleted in a single atomic transaction.

**Columns/Parameters Involved**: `DividendID`

**Rules**:
- DELETE FROM Trade.IndexDividends WHERE DividendID IN (SELECT DividendID FROM @DeleteIndexDividendsTbl)
- Wrapped in explicit BEGIN TRANSACTION / COMMIT TRANSACTION
- Unlike DeleteDividend, no Status check is performed - all specified records are deleted regardless of state
- On error: ROLLBACK if @@TRANCOUNT = 1, otherwise COMMIT (nested transaction handling)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DeleteIndexDividendsTbl | Trade.DeleteIndexDividendsTbl (READONLY) | NO | - | CODE-BACKED | TVP containing DividendIDs to delete from Trade.IndexDividends. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.IndexDividends | DELETER | Removes rows matching DividendIDs from the TVP |
| (@DeleteIndexDividendsTbl) | Trade.DeleteIndexDividendsTbl | Type Reference | TVP type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteIndexDividends (procedure)
+-- Trade.IndexDividends (table)
+-- Trade.DeleteIndexDividendsTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | DELETE target |
| Trade.DeleteIndexDividendsTbl | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk delete dividends

```sql
DECLARE @Dividends Trade.DeleteIndexDividendsTbl
INSERT INTO @Dividends (DividendID) VALUES (10), (11), (12)
EXEC Trade.DeleteIndexDividends @DeleteIndexDividendsTbl = @Dividends
```

### 8.2 Preview dividends before bulk delete

```sql
SELECT  DividendID, InstrumentID, DividendDate, Status
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   DividendID IN (10, 11, 12)
```

### 8.3 Count remaining dividends by status

```sql
SELECT  Status, COUNT(*) AS DividendCount
FROM    Trade.IndexDividends WITH (NOLOCK)
GROUP BY Status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteIndexDividends | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteIndexDividends.sql*
