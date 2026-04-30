# History.GetClosedPositionsPerPageByParentCID

> Returns paginated closed positions for a customer filtered by a specific CopyTrader leader (ParentCID), supporting both "copying a leader" and "self/manual" views with dynamic sorting and date range.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (copier) + @ParentCID (leader) filter; @From/@To date range; @ItemsPerPage/@PageNum pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **leader-filtered** variant of `History.GetClosedPositionsPerPageAndTimeFrame`. It returns a customer's closed positions filtered to those copied from a specific leader (`@ParentCID`). It supports two modes:

1. **Viewing a leader's positions** (`@CID != @ParentCID`): Returns positions where the customer (@CID) copied the leader (@ParentCID).
2. **Viewing own/manual positions** (`@CID = @ParentCID`): Returns the customer's own direct positions (not copied from anyone), including Copy Plus positions without a mirror.

Used by the CopyTrader history UI when a customer drills down into a specific leader's contribution to their position history.

---

## 2. Business Logic

### 2.1 Dual-Mode CID/ParentCID Filter Logic

**What**: Complex WHERE clause handles both "copy of a leader" and "self-view" scenarios.

**Columns/Parameters Involved**: `@CID`, `@ParentCID`, `ParentPositionID`, `MirrorID`, `ParentCID`

**Rules** (from WHERE clause):

**When @CID != @ParentCID (viewing a specific leader's positions)**:
- hp.CID = @CID AND History.Mirror.ParentCID = @ParentCID

**When @CID = @ParentCID (viewing own/manual positions)**:
- hp.CID = @CID AND hp.ParentPositionID = 0 AND hp.MirrorID = 0 (pure manual trades), OR
- hp.CID = @CID AND hp.ParentPositionID > 0 AND hp.MirrorID = 0 (CopyPlus without mirror)

Combined with: `hp.EndDateTime BETWEEN @From1 AND @To1`

### 2.2 Dynamic Sort with ParentUserName Support

**What**: Same dynamic ORDER BY as GetClosedPositionsPerPageAndTimeFrame, extended with ParentUserName.

**Additional sort column**: `ParentUserName` (sort by leader's name), using lower(ParentUserName).

### 2.3 Double-Layer Pagination

**What**: Uses a nested ROW_NUMBER pattern for final pagination.

**Rules**:
- Inner CTE: ROW_NUMBER() over the dynamic ORDER BY
- Outer SELECT: ROW_NUMBER() OVER (ORDER BY RowNum ASC) as NewRowNum
- Final filter: WHERE NewRowNum BETWEEN (@ItemsPerPage * (@PageNum-1)) + 1 AND (@ItemsPerPage * @PageNum)
- This re-numbers rows after dynamic sorting, ensuring consistent pagination.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID (the copier). Main filter on History.Position.CID. |
| 2 | @ItemsPerPage | INT | YES | NULL | CODE-BACKED | Page size for pagination. Items per page for the result set. |
| 3 | @PageNum | INT | YES | NULL | CODE-BACKED | 1-based page number for pagination. |
| 4 | @From | DATETIME | NO | - | CODE-BACKED | Start of date range filter on hp.EndDateTime (close date). |
| 5 | @To | DATETIME | NO | - | CODE-BACKED | End of date range filter. |
| 6 | @OrderBy | VARCHAR(24) | NO | - | CODE-BACKED | Column to sort by. Supported: CloseDate, Amount, Units, OpenRate, CloseRate, NetProfit, CloseReason, Gain, Action, ParentUserName. |
| 7 | @SortDirection | VARCHAR(4) | NO | - | CODE-BACKED | Sort direction: 'ASC' or 'DESC'. Case-sensitive (unlike GetClosedPositionsPerPageAndTimeFrame). |
| 8 | @ParentCID | INT | NO | - | CODE-BACKED | Leader CID to filter by. Pass @CID = @ParentCID to return the customer's own manual/direct positions. |

**Result set columns** (subset of GetClosedPositionsPerPageAndTimeFrame):
PositionID, OpenDate, CloseDate, Amount, Units, OpenRate, CloseRate, NetProfit, Gain, ParentPositionID, Action, CloseReason, ParentUserName, MirrorID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source filtered by CID + EndDateTime. |
| JOIN | History.ForexResult | Read | GameTypeID. |
| JOIN | Dictionary.GameType | Lookup | Game name (joined but not in SELECT output). |
| JOIN | Trade.Instrument | Lookup | Currency IDs. |
| JOIN | Dictionary.Currency (x2) | Lookup | Currency abbreviations and type IDs for Action string. |
| JOIN | Dictionary.ClosePositionActionType | Lookup | Close reason. |
| LEFT JOIN | History.Mirror | Read | ParentUserName and ParentCID for leader identification and filtering. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eToro platform API | EXEC | Direct call | CopyTrader history drill-down UI (by leader). |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetClosedPositionsPerPageByParentCID (procedure)
├── History.Position (table)
├── History.ForexResult (table)
├── History.Mirror (table)
├── Dictionary.GameType (table) [cross-schema]
├── Dictionary.Currency (table) [cross-schema - x2]
├── Dictionary.ClosePositionActionType (table) [cross-schema]
└── Trade.Instrument (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source, filtered by CID + EndDateTime + ParentCID logic. |
| History.ForexResult | Table | JOIN for GameTypeID. |
| History.Mirror | Table | LEFT JOIN for ParentUserName, ParentCID, and the CID=@CID AND ParentCID=@ParentCID filter. |
| Dictionary.GameType | Table | Game name lookup. |
| Dictionary.Currency | Table | Buy/sell currency info for Action string. |
| Dictionary.ClosePositionActionType | Table | Close reason lookup. |
| Trade.Instrument | Table | Instrument currency IDs. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro platform (application) | External | CopyTrader leader drill-down view in position history UI. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @SortDirection case-sensitive | Difference from #12 | GetClosedPositionsPerPageAndTimeFrame uses lower(@SortDirection); this procedure compares @SortDirection exactly (case-sensitive). Callers must pass 'ASC'/'DESC' in exact case. |
| Double ROW_NUMBER | Pagination design | Inner CTE orders dynamically; outer SELECT re-numbers to produce stable NewRowNum for BETWEEN pagination. |

---

## 8. Sample Queries

### 8.1 Get positions copied from a specific leader

```sql
EXEC History.GetClosedPositionsPerPageByParentCID
    @CID = 12345, @ItemsPerPage = 20, @PageNum = 1,
    @From = '2024-01-01', @To = '2024-12-31',
    @OrderBy = 'CloseDate', @SortDirection = 'DESC',
    @ParentCID = 67890;  -- leader's CID
```

### 8.2 Get customer's own manual positions (self view)

```sql
EXEC History.GetClosedPositionsPerPageByParentCID
    @CID = 12345, @ItemsPerPage = 20, @PageNum = 1,
    @From = '2024-01-01', @To = '2024-12-31',
    @OrderBy = 'NetProfit', @SortDirection = 'DESC',
    @ParentCID = 12345;  -- same as @CID for self view
```

### 8.3 Verify copy relationship between copier and leader

```sql
SELECT DISTINCT MirrorID, ParentCID, ParentUserName
FROM History.Mirror WITH (NOLOCK)
WHERE CID = 12345 AND ParentCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetClosedPositionsPerPageByParentCID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetClosedPositionsPerPageByParentCID.sql*
