# History.Position_beforeUM_25_2

> Backward-compatibility preservation of the History.Position view as it existed before User Model schema release 25.2 - omits 9 columns added in that release (CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes, OpenMarkupByUnits, IsNoStopLoss, IsNoTakeProfit, OriginalOpenActionType, InitialLotCount) and excludes History.PositionClosePartial. No current SQL consumers in the SSDT codebase.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

History.Position_beforeUM_25_2 is a backward-compatibility snapshot of the `History.Position` view as it existed before a User Model schema change in release/sprint "25.2". It was created to allow stored procedures and external consumers written against the older 115-column schema to continue working without modification after History.Position gained 9 new columns in that release.

The view has the same UNION ALL architecture as `History.Position` but differs in three ways:
1. **Excludes 9 columns added in UM 25.2**: CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes, OpenMarkupByUnits, IsNoStopLoss, IsNoTakeProfit, OriginalOpenActionType, InitialLotCount
2. **Excludes quarterly archive tables 2021Q2-2022Q4**: These 7 quarterly tables were added to History.Position after the "25.2" milestone; this view stops at 2021Q1
3. **Excludes History.PositionClosePartial**: Not included as a UNION ALL source

**No procedure consumers found in the current SSDT codebase.** The view appears to be consumed by external systems (BI tools, analytics pipelines, or legacy applications) that were built against the pre-25.2 schema. No stored procedures in the repo reference this view.

The 115-column schema output is identical to History.Position output for all rows except: the 9 missing columns, positions from 2021Q2-2022Q4 quarterly archives (still visible via History.Position_Active branch), and partial-close positions from History.PositionClosePartial.

**Key distinction from History.Position**: Use History.Position for all new queries. Use History.Position_beforeUM_25_2 only when maintaining compatibility with legacy code written against the older column set.

---

## 2. Business Logic

### 2.1 What Was Changed in UM 25.2

**What**: The User Model release 25.2 added 9 fee/tax/risk columns to History.Position that were not in the original schema.

**Columns/Parameters Involved**: CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes, OpenMarkupByUnits, IsNoStopLoss, IsNoTakeProfit, OriginalOpenActionType, InitialLotCount

**Rules**:
- These 9 columns are NOT present in History.Position_beforeUM_25_2
- They are present in History.Position (with 0/NULL backfill for pre-2022Q4 branches, native in 2022Q4+)
- The fee/tax breakdown (CloseTotalFees etc.) was part of a platform-wide fee transparency initiative
- IsNoStopLoss/IsNoTakeProfit explicitly flag positions opened without risk parameters

### 2.2 UNION ALL Architecture (3-Source vs History.Position 4-Source)

**What**: This view uses 3 source types vs. History.Position's 4.

**Rules**:
- Quarterly archives: dbo.HistoryPosition_2007Q3 through dbo.HistoryPosition_2021Q1 (55 tables, vs. 62 in History.Position)
- History.Position_Active: same as History.Position, but SELECT list stops at EstimatedMarkupRatio (col 115)
- Trade.PositionTbl + Trade.PositionTreeInfo WHERE StatusID=2: same JOIN as History.Position, same 115-column SELECT
- NOT included: dbo.HistoryPosition_2021Q2 through 2022Q4, History.PositionClosePartial

### 2.3 CommissionByUnits Computation (ROUND vs CAST)

**What**: This view uses ROUND() while History.Position uses CAST() for the CommissionByUnits computation.

**Columns/Parameters Involved**: `CommissionByUnits`, `FullCommissionByUnits`

**Rules**:
- History.Position: `CAST(CASE ... AS MONEY)` - truncates to money precision
- History.Position_beforeUM_25_2: `ROUND(CASE ..., 2)` - rounds to 2 decimal places
- The difference is minor but may produce slightly different results for fractional commissions at the money precision boundary
- This reflects an implementation difference between the two view versions at the time they were last updated

---

## 3. Data Overview

Same data as History.Position minus the 9 columns, 7 quarterly tables, and PositionClosePartial. See History.Position documentation for live data samples.

---

## 4. Elements

115 output columns. Columns 1-115 are identical in name and meaning to History.Position columns 1-115. The 9 missing columns (CloseTotalFees through InitialLotCount, positions 116-124 in History.Position) are not present.

See History.Position.md for full element descriptions. Key elements noted here:

| # | Element | Type | Nullable | Confidence | Notes |
|---|---------|------|----------|------------|-------|
| 1-86 | (Core position columns) | Various | Various | CODE-BACKED | PositionID through FullCommissionOnClose - identical to History.Position |
| 87 | IsSettled | bit | NO | CODE-BACKED | 0 in pre-2021Q1 branches; native in History.Position_Active branch |
| 88 | SettlementTypeID | tinyint | YES | CODE-BACKED | 0 / cast(IsSettled) / ISNULL pattern same as History.Position |
| 89-95 | RedeemStatus...ReopenForPositionID | Various | YES | CODE-BACKED | NULL/0 in older branches, native in 2021+ branches |
| 96-99 | UnitsBaseValueCents...FullCommissionByUnits | Various | Various | CODE-BACKED | ROUND() used for CommissionByUnits (vs CAST() in History.Position) |
| 100-115 | InitConversionRate...EstimatedMarkupRatio | Various | YES | CODE-BACKED | NULL/0 in pre-2021Q2 branches; native in 2021Q2+ branches |
| **116-124** | **CloseTotalFees...InitialLotCount** | **N/A** | **N/A** | **N/A** | **NOT PRESENT - these columns were added in UM 25.2** |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (55 quarterly branches) | dbo.HistoryPosition_2007Q3 ... dbo.HistoryPosition_2021Q1 | View (UNION branches) | Historical quarterly archives - stops at Q1 2021 (7 fewer than History.Position) |
| (Position_Active branch) | History.Position_Active | View (UNION branch) | Primary archive 2021+; 115 columns selected (9 fewer) |
| (Trade branch) | Trade.PositionTbl + Trade.PositionTreeInfo | View (UNION branch, WHERE StatusID=2) | Live closed positions; ROUND() for CommissionByUnits |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (no SQL procedure consumers in SSDT repo) | - | - | External systems (legacy BI tools or applications) may consume this view directly. No SQL procedure in the codebase references this view. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Position_beforeUM_25_2 (view)
|- dbo.HistoryPosition_2007Q3 ... dbo.HistoryPosition_2021Q1 (55 tables - quarterly archives)
|- History.Position_Active (table - primary archive 2021+, 115 cols selected)
+- Trade.PositionTbl + Trade.PositionTreeInfo (WHERE StatusID=2)
   NOTE: History.PositionClosePartial is NOT included (unlike History.Position)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.HistoryPosition_2007Q3 ... 2021Q1 | Tables (55) | UNION ALL branches - historical quarterly archive (stops at 2021Q1) |
| History.Position_Active | Table | UNION ALL branch - 115 of 124 columns selected |
| Trade.PositionTbl | Table | UNION ALL branch (JOIN with Trade.PositionTreeInfo WHERE StatusID=2) |
| Trade.PositionTreeInfo | Table | INNER JOIN with Trade.PositionTbl |

### 6.2 Objects That Depend On This

No SQL procedure consumers found in SSDT codebase. View preserved for backward compatibility with external consumers.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Same base table indexes as History.Position apply. Avoid unfiltered queries due to the 57+ table UNION ALL.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Verify the 9-column difference from History.Position
```sql
-- History.Position has 124 cols; this view has 115 cols.
-- The following works on this view but would return 9 extra cols from History.Position:
SELECT TOP 1
    p.PositionID,
    p.CID,
    p.NetProfit,
    p.IsSettled,
    p.InitConversionRate,
    p.EstimatedMarkupRatio
    -- NOTE: CloseTotalFees, OpenTotalFees, IsNoStopLoss etc. NOT available here
FROM History.Position_beforeUM_25_2 p WITH (NOLOCK)
WHERE p.CID = 14952810
ORDER BY p.CloseOccurred DESC;
```

### 8.2 Same query as above using History.Position (preferred for new code)
```sql
SELECT TOP 1
    p.PositionID,
    p.CID,
    p.NetProfit,
    p.IsSettled,
    p.InitConversionRate,
    p.CloseTotalFees,    -- available here, NOT in _beforeUM_25_2
    p.IsNoStopLoss       -- available here, NOT in _beforeUM_25_2
FROM History.Position p WITH (NOLOCK)
WHERE p.CID = 14952810
ORDER BY p.CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.Position_beforeUM_25_2. Business context inherited from History.Position and History.Position_Active documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 115 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Position_beforeUM_25_2 | Type: View | Source: etoro/etoro/History/Views/History.Position_beforeUM_25_2.sql*
