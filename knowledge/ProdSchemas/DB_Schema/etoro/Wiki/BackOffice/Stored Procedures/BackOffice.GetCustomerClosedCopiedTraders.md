# BackOffice.GetCustomerClosedCopiedTraders

> Returns the closed copy-trading (Mirror) relationships for a customer within a date window, including the copied trader, number of closed positions, copy stop-loss, and the reason the copy relationship ended.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @DateFrom / @DateTo on min(History.Mirror.ModificationDate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure shows the BackOffice agent a customer's history of copy-trading relationships (Mirrors) - specifically, the traders they have copied and which of those relationships are closed or still open. Each row represents one Mirror relationship identified by MirrorID, showing who was copied (ParentCID/ParentUserName), how many positions were closed under that copy relationship, and why the copy was stopped.

"Copy trading" (called Mirror at eToro) is the feature where a customer automatically replicates another trader's positions. This procedure is used in the BackOffice customer profile to review a customer's copy trading activity history within a date window.

The date filter uses the earliest ModificationDate of the mirror's history records (`min(ModificationDate) BETWEEN @DateFrom AND @DateTo`), which typically corresponds to when the copy relationship was first established.

---

## 2. Business Logic

### 2.1 HAVING Clause for CID and Date Filtering

**What**: The CID and date range filter is applied in the HAVING clause, not WHERE - an unusual pattern driven by the GROUP BY aggregation.

**Columns/Parameters Involved**: `@CID`, `@DateFrom`, `@DateTo`, `min(HMIR.ModificationDate)`

**Rules**:
- `HAVING HMIR.CID = @CID AND min(HMIR.ModificationDate) BETWEEN @DateFrom AND @DateTo`
- Because the query groups by (CID, MirrorID, ParentCID, ParentUserName) and uses MIN/MAX aggregates, the date filter must be in HAVING
- `min(ModificationDate)` = earliest recorded modification = typically when the copy was started
- This means the date window targets mirrors that were FIRST modified (started) within the range, not necessarily closed within the range

### 2.2 Open vs Closed State Check

**What**: The [State] column checks whether the mirror still exists in the active Trade.Mirror table.

**Columns/Parameters Involved**: `State`, `Trade.Mirror`

**Rules**:
- Subquery: `SELECT TOP 1 'Open  ' FROM Trade.Mirror WHERE CID=HMIR.CID AND MirrorID=HMIR.MirrorID`
- If the mirror exists in Trade.Mirror (active table): returns 'Open  ' (with trailing spaces)
- If not found: ISNULL returns 'Closed'
- This allows the BO agent to see historical copy relationships even when they have been closed (moved out of Trade.Mirror into History.Mirror)

### 2.3 Close Reason Resolution

**What**: The most recent CloseMirrorActionType record from History.Mirror determines why the copy ended.

**Columns/Parameters Involved**: `[Close Reason]`, `History.Mirror`, `Dictionary.CloseMirrorActionType`

**Rules**:
- Subquery on History.Mirror ordered by ID DESC (most recent first), TOP 1
- JOINs Dictionary.CloseMirrorActionType to get the action name
- ISNULL defaults to 'Customer' if no CloseMirrorActionType is recorded - implying the customer voluntarily stopped copying
- The JOIN is between the outer HMIR aliases and the subquery's History.Mirror (h) using CID + ParentCID + ParentUserName + MirrorID to ensure the right mirror

### 2.4 Copy Stop Loss Value

**What**: The last recorded MirrorSL (mirror stop-loss) value from History.Mirror.

**Columns/Parameters Involved**: `[Copy Stop Loss]`, `History.Mirror.MirrorSL`

**Rules**:
- Subquery on History.Mirror ordered by ID DESC, TOP 1
- Returns `CAST(MirrorSL AS DECIMAL(16,2))` - the stop-loss percentage set by the customer to auto-close the copy if losses exceed this threshold
- NULL if never set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose copy-trading history to return. Applied in HAVING clause. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the date window. Filters mirrors where min(ModificationDate) >= @DateFrom. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the date window. Filters mirrors where min(ModificationDate) <= @DateTo. |
| **Output Columns** | | | | | | |
| 4 | Mirror ID | INT | NO | - | CODE-BACKED | Unique identifier of the copy-trading relationship. From History.Mirror.MirrorID. |
| 5 | Parent CID | INT | NO | - | CODE-BACKED | Customer ID of the trader being copied (the "popular investor" / parent). From History.Mirror.ParentCID. |
| 6 | Parent Username | NVARCHAR | YES | - | CODE-BACKED | Username of the copied trader. From History.Mirror.ParentUserName. |
| 7 | Closed Positions | INT | YES | - | CODE-BACKED | Count of positions that were closed under this copy relationship. Subquery: COUNT(PositionID) from History.Position WHERE CID=@CID AND MirrorID matches. |
| 8 | Copied On | DATETIME | NO | - | CODE-BACKED | Earliest occurrence date of the mirror: MIN(HMIR.Occurred). Represents when the customer first started copying this trader. |
| 9 | Last Modification Date | DATETIME | NO | - | CODE-BACKED | Most recent modification to any mirror history record: MAX(HMIR.ModificationDate). |
| 10 | State | VARCHAR(6) | NO | - | CODE-BACKED | Current state of the copy relationship: 'Open  ' (6 chars, trailing spaces) if still active in Trade.Mirror, or 'Closed' if not found. |
| 11 | Close Reason | NVARCHAR | YES | Customer | CODE-BACKED | Reason the copy was stopped. From Dictionary.CloseMirrorActionType.CloseMirrorActionName via most recent History.Mirror record. Defaults to 'Customer' if no reason recorded (voluntary stop). |
| 12 | Copy Stop Loss | DECIMAL(16,2) | YES | NULL | CODE-BACKED | The stop-loss percentage set on the copy relationship. From most recent History.Mirror.MirrorSL. Auto-closes the copy if total mirror losses exceed this percentage of copied amount. NULL if not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / MirrorID | History.Mirror | Primary Source | Copy-trading relationship history records |
| CID / MirrorID | Trade.Mirror | Lookup / Subquery | Checks if mirror still active (Open vs Closed state) |
| CloseMirrorActionType | Dictionary.CloseMirrorActionType | Lookup / LEFT JOIN | Resolves close action type ID to descriptive name |
| CID / MirrorID | History.Position | Subquery | Counts closed positions under each mirror relationship |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called by BackOffice customer profile to display copy-trading history tab |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerClosedCopiedTraders (procedure)
|- History.Mirror (copy-trading history records)
|- Trade.Mirror (active copy-trading - state check)
|- Dictionary.CloseMirrorActionType (close reason lookup)
+-- History.Position (closed positions count per mirror)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | Primary source - all historical mirror records for the customer |
| Trade.Mirror | Table | Subquery to determine if mirror is still active |
| Dictionary.CloseMirrorActionType | Table | LEFT JOINed to resolve close action type to descriptive name |
| History.Position | Table | Subquery to count closed positions per mirror |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Copy-trading history tab in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- HAVING clause filter: `HMIR.CID = @CID AND min(HMIR.ModificationDate) BETWEEN @DateFrom AND @DateTo` - applied post-aggregation; the CID filter could theoretically have been in WHERE for efficiency, but is placed in HAVING alongside the aggregate condition.
- ORDER BY `min(HMIR.Occurred) DESC` - most recently started copies appear first.

---

## 8. Sample Queries

### 8.1 Get closed copy relationships for a customer

```sql
EXEC BackOffice.GetCustomerClosedCopiedTraders
    @CID      = 12345678,
    @DateFrom = '2025-01-01',
    @DateTo   = '2026-03-17';
```

### 8.2 Direct History.Mirror query

```sql
SELECT HMIR.MirrorID, HMIR.ParentCID, HMIR.ParentUserName,
    MIN(HMIR.Occurred) AS CopiedOn,
    MAX(HMIR.ModificationDate) AS LastModified,
    CASE WHEN EXISTS(SELECT 1 FROM Trade.Mirror WITH(NOLOCK)
        WHERE CID=HMIR.CID AND MirrorID=HMIR.MirrorID) THEN 'Open' ELSE 'Closed' END AS State
FROM History.Mirror HMIR WITH(NOLOCK)
GROUP BY HMIR.CID, HMIR.MirrorID, HMIR.ParentCID, HMIR.ParentUserName
HAVING HMIR.CID = 12345678
    AND MIN(HMIR.ModificationDate) BETWEEN '2025-01-01' AND '2026-03-17'
ORDER BY MIN(HMIR.Occurred) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerClosedCopiedTraders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerClosedCopiedTraders.sql*
