# Trade.GetEstimatedClosingTreeUnitsByPositionID

> Estimates total units to be closed across the copy-tree for a partial or full position close. Used by the hedge service to calculate net exposure when closing part of a position. Delegates to GetClosingTreeUnitsByPositionID when ratio=1.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - root of the position tree being closed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a trader partially closes a position in a copy-trading tree, the hedge service must estimate how many units will be closed across the entire subtree. This procedure handles both full closes (ratio=1, delegates to Trade.GetClosingTreeUnitsByPositionID) and partial closes (ratio<1). For partial closes, it recursively walks the tree and determines for each child position whether the remaining amount after partial close meets the minimum copy threshold - if yes, close partial; if no, close full.

This procedure exists because copy-trading creates hierarchical positions. A partial close on a parent does not simply apply the ratio to every child; some children may have amounts below the minimum copy amount, so they must be fully closed. Without this logic, hedge calculations would be wrong and minimum-copy business rules would be violated.

Data flow: Called by the hedge service with PositionID, HedgeServerID, and PartialCloseRatio. Returns SUM(PartialCloseRatio * AmountInUnitsDecimal) for positions on the matching hedge server with IsComputeForHedge=1.

---

## 2. Business Logic

### 2.1 Partial Close Ratio Validation

**What**: @PartialCloseRatio must be > 0 and <= 1. Invalid values raise an error.

**Columns/Parameters Involved**: `@PartialCloseRatio`

**Rules**:
- Must be > 0 (no zero-ratio closes)
- Must be <= 1 (no over-close)
- Invalid values cause procedure to raise error and exit

### 2.2 Full Close vs Partial Close Routing

**What**: Ratio=1 delegates to Trade.GetClosingTreeUnitsByPositionID. Ratio<1 uses recursive CTE with minimum-copy logic.

**Columns/Parameters Involved**: `@PartialCloseRatio`, `AmountInUnitsDecimal`, `ParentPositionID`, `StatusID`, `PlayerStatusID`, `RealizedEquity`

**Rules**:
- If @PartialCloseRatio = 1: EXEC Trade.GetClosingTreeUnitsByPositionID and return
- If @PartialCloseRatio < 1: Get min copy amounts from Trade.GetMinCopyPositonAmountMaintenanceFeatureValues, convert cents to dollars (/100), run recursive CTE
- Root: position being closed must have StatusID=1, PlayerStatusID NOT IN (2,9), RealizedEquity > 0
- Recursive: child positions via ParentPositionID join
- Per child: if remaining amount after partial close >= minimum, close partial (same ratio); else close full (ratio=1)
- Final: SUM(PartialCloseRatio * AmountInUnitsDecimal) WHERE HedgeServerID matches and IsComputeForHedge=1

**Diagram**:
```
Partial Close Flow:
  @PartialCloseRatio = 0.5
       [Root: 1000 units]
       Remaining: 500 >= min? -> partial close
         /           \
  [Child: 200]  [Child: 50]
  Remaining: 100 >= min? -> partial
  Remaining: 25 < min? -> full close (ratio=1 for this child)
```

### 2.3 Minimum Copy Amount Application

**What**: Each child position's remaining amount is compared to the minimum copy amount (from maintenance feature) to decide partial vs full close.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `PartialCloseRatio`, min copy amount (cents/100)

**Rules**:
- Min amounts fetched via Trade.GetMinCopyPositonAmountMaintenanceFeatureValues
- Converted from cents to dollars before comparison
- Fund vs regular customer may have different minimums (Customer.IsCustomerFund)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Root position being closed. Recursive CTE starts here. (Comment: 17/11/2021 Bonnie Change positionID to bigint) |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server filter. Only positions on this server contribute to the unit sum |
| 3 | @PartialCloseRatio | DECIMAL(16,8) | NO | - | CODE-BACKED | Ratio of position to close: 0 < ratio <= 1. 1 = full close; <1 = partial close |
| 4 | (return) | DECIMAL | NO | - | CODE-BACKED | SUM(PartialCloseRatio * AmountInUnitsDecimal) for positions matching HedgeServerID and IsComputeForHedge=1 |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Trade.GetMinCopyPositonAmountMaintenanceFeatureValues | Call | Minimum copy amounts for threshold logic |
| EXEC | Trade.GetClosingTreeUnitsByPositionID | Call | Full close delegate when ratio=1 |
| FROM | Trade.PositionTbl | Table | Recursive CTE source |
| FROM | Customer.IsCustomerFund | Function/Table | Fund vs regular customer distinction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge service | Caller | Call | Estimates closing tree units for partial/full closes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEstimatedClosingTreeUnitsByPositionID (procedure)
+-- Trade.GetMinCopyPositonAmountMaintenanceFeatureValues (procedure)
+-- Trade.GetClosingTreeUnitsByPositionID (procedure)
+-- Trade.PositionTbl (table)
+-- Customer.IsCustomerFund (function/table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMinCopyPositonAmountMaintenanceFeatureValues | Procedure | EXEC - min copy amounts |
| Trade.GetClosingTreeUnitsByPositionID | Procedure | EXEC - full close when ratio=1 |
| Trade.PositionTbl | Table | Recursive CTE - position tree |
| Customer.IsCustomerFund | Function/Table | JOIN - fund vs regular threshold |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge service | Service | Calls for closing tree unit estimates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Recursive CTE with ParentPositionID join
- Root filter: StatusID=1, PlayerStatusID NOT IN (2,9), RealizedEquity > 0
- Comment: 17/11/2021 Bonnie Change positionID to bigint

---

## 8. Sample Queries

### 8.1 Full close (delegates to GetClosingTreeUnitsByPositionID)

```sql
EXEC Trade.GetEstimatedClosingTreeUnitsByPositionID
    @PositionID = 123456789,
    @HedgeServerID = 1,
    @PartialCloseRatio = 1.0;
```

### 8.2 Partial close at 50%

```sql
EXEC Trade.GetEstimatedClosingTreeUnitsByPositionID
    @PositionID = 123456789,
    @HedgeServerID = 1,
    @PartialCloseRatio = 0.5;
```

### 8.3 Inspect position tree for manual verification

```sql
;WITH TreeCTE AS (
    SELECT PositionID, ParentPositionID, CID, AmountInUnitsDecimal,
           HedgeServerID, IsComputeForHedge, 0 AS TreeLevel
    FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE PositionID = 123456789 AND StatusID = 1
    UNION ALL
    SELECT pos.PositionID, pos.ParentPositionID, pos.CID, pos.AmountInUnitsDecimal,
           pos.HedgeServerID, pos.IsComputeForHedge, c.TreeLevel + 1
    FROM Trade.PositionTbl pos WITH (NOLOCK)
    INNER JOIN TreeCTE c ON c.PositionID = pos.ParentPositionID AND pos.StatusID = 1
)
SELECT TreeLevel, PositionID, ParentPositionID, AmountInUnitsDecimal,
       HedgeServerID, IsComputeForHedge
FROM TreeCTE
ORDER BY TreeLevel, PositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEstimatedClosingTreeUnitsByPositionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEstimatedClosingTreeUnitsByPositionID.sql*
