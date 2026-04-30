# Trade.UsUnitsToAddByPositionToSplitByJob

> Staging table holding the calculated fractional unit adjustments for US customer positions during stock split processing, consumed by the SplitbyJob procedure and cleared after each split operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID (BIGINT, UNIQUE CLUSTERED INDEX) |
| **Partition** | No (PRIMARY filegroup) |
| **Row Count** | 0 (MCP verified - cleared after processing) |
| **Indexes** | 1 active (unique clustered on PositionID) |

---

## 1. Business Meaning

Trade.UsUnitsToAddByPositionToSplitByJob is a staging table used during stock split operations to hold the calculated unit adjustments for US customer positions. When a stock split occurs (e.g., 2-for-1, 10-for-1), each open position's units must be recalculated. US customers have special precision requirements for unit calculations (5 decimal places vs 6 for non-US), and this table stores the pre-calculated US-specific unit additions.

Without this table, the stock split job would need to calculate US unit adjustments inline during the split transaction, increasing lock duration and complexity. By pre-staging the calculations, the split job can apply adjustments in controlled batches.

Data is populated by Trade.SplitOpenPositions (which calculates the split-adjusted units for US customer positions) and consumed by Trade.SplitbyJob (which applies the adjustments to Trade.PositionTbl). The table is empty between split operations because rows are consumed and removed during processing.

---

## 2. Business Logic

### 2.1 US-Specific Unit Precision in Stock Splits

**What**: Pre-calculates the fractional units to add to each US customer position during a stock split, using US-specific precision.

**Columns/Parameters Involved**: `PositionID`, `UnitsToAdd`

**Rules**:
- US customer positions use 5-decimal precision (@UsUnitsPrecision = 0.00001) for unit calculations
- Non-US positions use 6-decimal precision (@UnitsPrecision = 0.000001)
- UnitsToAdd is the additional units to be added to the position's existing units after applying the split ratio
- The staging pattern allows batch processing: populate the table, then apply updates in controlled batches of 2000 (or 1 for specific NtilePositionID=11)
- Table is empty between split events - rows exist only during active processing

---

## 3. Data Overview

Table is currently empty (0 rows). When populated during a stock split:

| PositionID | UnitsToAdd | Meaning |
|---|---|---|
| (example) 2100000001 | 50.00000000 | US customer position needs 50 additional units added due to a 2-for-1 stock split (original 50 units doubled) |
| (example) 2100000002 | 9.00000000 | US customer position needs 9 additional units for a 10-for-1 split (original 1 unit becomes 10) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | The position being adjusted in the stock split. References Trade.PositionTbl.PositionID (implicit). Unique clustered index ensures one adjustment per position per split operation. Nullable in DDL but unique index enforces non-null in practice. |
| 2 | UnitsToAdd | dbo.dtPrice (decimal(16,8)) | YES | - | CODE-BACKED | The number of fractional units to add to this position as a result of the stock split. Calculated using US-specific 5-decimal precision (0.00001). Applied by Trade.SplitbyJob to update Trade.PositionTbl.AmountInUnitsDecimal. Value depends on the split ratio and the position's current units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | References the position whose units are being adjusted during the stock split |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitbyJob | PositionID, UnitsToAdd | Reader | Reads pre-calculated US unit adjustments and applies them to Trade.PositionTbl |
| Trade.SplitOpenPositions | PositionID, UnitsToAdd | Writer | Populates the staging table with calculated US-specific unit adjustments |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitbyJob | Stored Procedure | Reader - applies unit adjustments from this staging table |
| Trade.SplitOpenPositions | Stored Procedure | Writer - populates this table with calculated adjustments |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| cix | UNIQUE CLUSTERED | PositionID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if there are pending US split adjustments
```sql
SELECT  COUNT(*) AS PendingAdjustments
FROM    Trade.UsUnitsToAddByPositionToSplitByJob WITH (NOLOCK);
```

### 8.2 View pending adjustments with position details
```sql
SELECT  us.PositionID,
        us.UnitsToAdd,
        tp.InstrumentID,
        tp.AmountInUnitsDecimal AS CurrentUnits,
        tp.CID
FROM    Trade.UsUnitsToAddByPositionToSplitByJob us WITH (NOLOCK)
JOIN    Trade.PositionTbl tp WITH (NOLOCK)
        ON us.PositionID = tp.PositionID
        AND us.PositionID % 50 = tp.PartitionCol
ORDER BY us.PositionID;
```

### 8.3 Summarize adjustments by instrument
```sql
SELECT  tp.InstrumentID,
        COUNT(*)             AS PositionCount,
        SUM(us.UnitsToAdd)   AS TotalUnitsToAdd
FROM    Trade.UsUnitsToAddByPositionToSplitByJob us WITH (NOLOCK)
JOIN    Trade.PositionTbl tp WITH (NOLOCK)
        ON us.PositionID = tp.PositionID
        AND us.PositionID % 50 = tp.PartitionCol
GROUP BY tp.InstrumentID
ORDER BY TotalUnitsToAdd DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from procedure logic analysis (Trade.SplitbyJob, Trade.SplitOpenPositions) and UDT resolution (dbo.dtPrice = decimal(16,8)).

---

*Generated: 2026-03-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UsUnitsToAddByPositionToSplitByJob | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.UsUnitsToAddByPositionToSplitByJob.sql*
