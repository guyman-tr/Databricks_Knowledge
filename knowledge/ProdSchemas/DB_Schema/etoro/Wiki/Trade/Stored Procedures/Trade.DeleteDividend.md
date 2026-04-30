# Trade.DeleteDividend

> Deletes a single pending index dividend record from Trade.IndexDividends after validating the record exists and has not yet been processed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendID (identifies the dividend record to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteDividend removes a single dividend event from Trade.IndexDividends. Index dividends are scheduled events that distribute profits to position holders of certain instruments. This procedure is called by administrators when a scheduled dividend needs to be cancelled before it is processed (e.g., incorrect dividend amount, wrong date, cancelled corporate action).

This procedure exists to provide a safe, validated delete mechanism. It enforces two business rules: (1) the DividendID must exist, and (2) the dividend must still be in Status=0 (pending). Dividends that have already been processed (Status <> 0) cannot be deleted - this prevents undoing financial operations that have already affected customer balances.

Data flow: The caller provides a DividendID. The procedure first queries DividendDate to verify existence. If not found, an error is raised. Then it checks if Status <> 0 (already occurred), and if so, raises a different error. Only if both checks pass does the DELETE execute, restricted to Status = 0.

---

## 2. Business Logic

### 2.1 Existence Validation

**What**: Verifies the DividendID exists before attempting deletion.

**Columns/Parameters Involved**: `@DividendID`, `DividendDate`

**Rules**:
- SELECT DividendDate WHERE DividendID = @DividendID
- If NULL (not found): RAISERROR with "Could not find record to delete"

### 2.2 Status Guard - Only Pending Dividends Deletable

**What**: Prevents deletion of dividends that have already been processed.

**Columns/Parameters Involved**: `@DividendID`, `Status`

**Rules**:
- If Status <> 0 for the given DividendID: RAISERROR with "Can not delete a record about an event that already occurred"
- Status = 0 means the dividend is still pending/scheduled
- This prevents accidental reversal of financial operations
- DELETE WHERE clause also includes Status = 0 as a safety net

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendID | INT | NO | - | CODE-BACKED | Unique identifier of the dividend record in Trade.IndexDividends to delete. Must exist and be in pending status (Status=0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendID | Trade.IndexDividends | DELETER | Reads for validation then deletes pending dividend record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteDividend (procedure)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | SELECT for validation, DELETE for pending records |

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

### 8.1 Delete a pending dividend

```sql
EXEC Trade.DeleteDividend @DividendID = 42
```

### 8.2 Check pending dividends before deletion

```sql
SELECT  DividendID, DividendDate, InstrumentID, Status
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   Status = 0
ORDER BY DividendDate
```

### 8.3 Verify dividend was deleted

```sql
SELECT  DividendID, Status
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   DividendID = 42
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteDividend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteDividend.sql*
