# Trade.GetEstimatedTreeUnitsByCIDMotiJUNK

> Debug-only iterative procedure that estimates total copy-tree units for a customer using a WHILE loop approach instead of CTE recursion.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single SUM of units across the entire copy tree |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a **debug/diagnostic variant** of the copy-tree unit estimation logic, written by developer "Moti" as an alternative approach. Unlike `Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk` which uses a recursive CTE, this version uses an iterative WHILE loop with a temp table. The name contains "JUNK" to indicate it is not for production use.

The procedure calculates the total number of units that would be opened across the entire CopyTrader tree when a leader opens a position. It iterates level-by-level through the mirror hierarchy, accumulating each copier's proportional units into a `#Kids` temp table.

The final result is a single summed value: the total units including the leader's own units, excluding customers in the `BackOffice.BonusOnlyCustomers` exclusion list. It uses `Trade.GetTotalCash` function to calculate each copier's equity ratio.

---

## 2. Business Logic

### 2.1 Iterative Tree Traversal with WHILE Loop

**What**: Level-by-level iteration through the copy mirror hierarchy to calculate total tree units.

**Columns/Parameters Involved**: `@CID`, `@Leverage`, `@Ratio`, `@Units`, `@MinDollars`, `@InstrumentUnitMargin`

**Rules**:
- Level 0: Direct copiers of the leader; Units = Amount * Leverage * Ratio / InstrumentUnitMargin
- Level N: Deeper copiers; Units = parent's Ratio * Amount * Leverage * Ratio / InstrumentUnitMargin
- MinUnits = MinDollars * Leverage / InstrumentUnitMargin (minimum threshold to qualify)
- BonusOnlyCustomers are excluded from the final sum via LEFT JOIN / IS NULL pattern
- Final result = SUM(all copier units) + leader's own @Units

**Diagram**:
```
Level 0: Insert direct copiers from Trade.Mirror WHERE ParentCID = @CID
  WHILE new rows inserted:
    Level N: Insert copiers of Level N-1 from Trade.Mirror
  End WHILE
Final: SUM(#Kids.Units) + @Units, excluding BonusOnlyCustomers
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the leader initiating the position |
| 2 | @Leverage | INT | NO | - | CODE-BACKED | Position leverage multiplier |
| 3 | @Ratio | DECIMAL(16,4) | NO | - | CODE-BACKED | Proportion of equity allocated to this position |
| 4 | @Units | MONEY | NO | - | CODE-BACKED | Leader's own unit count, added to the tree total |
| 5 | @MinDollars | MONEY | NO | - | CODE-BACKED | Minimum position dollar amount (pre-calculated, passed in) |
| 6 | @InstrumentUnitMargin | INT | NO | - | CODE-BACKED | Unit margin for the instrument (price per unit) |

### Return Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed) | MONEY | NO | - | CODE-BACKED | Total estimated units across the entire copy tree plus the leader's own units |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE/WHILE | Trade.Mirror | JOIN | Traverses the copy mirror hierarchy level by level |
| Ratio calc | Trade.GetTotalCash | Function Call | Calculates copier's total cash for ratio computation |
| Exclusion | BackOffice.BonusOnlyCustomers | LEFT JOIN | Excludes bonus-only customers from the total |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None) | - | - | Debug-only procedure, not called by production code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEstimatedTreeUnitsByCIDMotiJUNK (procedure)
  +-- Trade.Mirror (table)
  +-- Trade.GetTotalCash (function)
  +-- BackOffice.BonusOnlyCustomers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Recursive level-by-level traversal of copy hierarchy |
| Trade.GetTotalCash | Function | Called to get copier total cash for ratio calculation |
| BackOffice.BonusOnlyCustomers | Table | LEFT JOIN exclusion from final sum |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None) | - | Debug-only procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Estimate total tree units
```sql
EXEC Trade.GetEstimatedTreeUnitsByCIDMotiJUNK
    @CID = 12345678,
    @Leverage = 1,
    @Ratio = 0.05,
    @Units = 100,
    @MinDollars = 50,
    @InstrumentUnitMargin = 1;
```

### 8.2 Check active mirrors for a leader
```sql
SELECT  MirrorID, CID, ParentCID, Amount, RealizedEquity
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 12345678
        AND IsActive = 1
        AND PauseCopy = 0;
```

### 8.3 Check bonus-only exclusions
```sql
SELECT  CID
FROM    BackOffice.BonusOnlyCustomers WITH (NOLOCK)
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEstimatedTreeUnitsByCIDMotiJUNK | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEstimatedTreeUnitsByCIDMotiJUNK.sql*
