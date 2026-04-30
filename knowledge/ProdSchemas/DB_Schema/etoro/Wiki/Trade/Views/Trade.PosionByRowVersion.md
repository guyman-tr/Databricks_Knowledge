# Trade.PosionByRowVersion

> De-duplicates Trade.PositionForExternalUse by selecting the row version that has the highest version number between RowVersionPosition and RowVersionTree. This ensures each position is returned once with the latest version identifier. The name contains a typo ("Posion" instead of "Position") which is original.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

This view de-duplicates `Trade.PositionForExternalUse` by selecting the row version that has the highest version number between `RowVersionPosition` and `RowVersionTree`. It ensures each position is returned once with the latest version identifier. The name contains a typo ("Posion" instead of "Position") which is original.

The CTE unions both RowVersionPosition and RowVersionTree as candidate version IDs. The CROSS APPLY finds the MAX version per position. The WHERE clause keeps only the row matching the max version. This deduplication produces one row per position with the winning version stamped as LastvaersionID (also an original typo for "LastVersionID").

---

## 2. Business Logic

### 2.1 Version Candidate Union

**What**: Collects both row version columns as candidate version identifiers per position.
**Columns/Parameters Involved**: `PositionID`, `RowVersionPosition`, `RowVersionTree`, `LastvaersionID`
**Rules**:
- CTE produces two rows per position: one with RowVersionPosition as LastvaersionID, one with RowVersionTree as LastvaersionID
- UNION (no ALL) deduplicates identical version values across the two columns

### 2.2 Maximum Version Selection

**What**: Selects the row with the highest version value per position.
**Columns/Parameters Involved**: `PositionID`, `LastvaersionID`, `maxversion`
**Rules**:
- CROSS APPLY computes MAX(LastvaersionID) per PositionID from the CTE
- WHERE maxversion = LastvaersionID keeps only the row whose version equals the max
- Result: one row per position with the latest version identifier

### 2.3 Row Deduplication

**What**: Ensures each PositionID appears exactly once in the output.
**Columns/Parameters Involved**: `PositionID`, all PositionForExternalUse columns
**Rules**:
- When RowVersionPosition and RowVersionTree differ, the higher value wins
- When they match, UNION reduces to one candidate; the join yields one output row

---

## 3. Data Overview

One row per position from `Trade.PositionForExternalUse`, with all original columns plus `LastvaersionID`. The view guarantees no duplicate PositionIDs; each position is represented by the row that has the maximum version identifier between `RowVersionPosition` and `RowVersionTree`.

---

## 4. Elements

| # | Column Name | Data Type | Source | Confidence | Description |
|---|-------------|-----------|--------|------------|-------------|
| 1 | PositionID | bigint | Trade.PositionForExternalUse | High | Position identifier (PK) |
| 2 | LastvaersionID | rowversion/binary(8) | Computed MAX | High | Highest version between RowVersionPosition and RowVersionTree |
| 3 | CID | int | Trade.PositionForExternalUse | High | Customer ID |
| 4 | CurrencyID | int | Trade.PositionForExternalUse | High | Denomination currency |
| 5 | ProviderID | int | Trade.PositionForExternalUse | High | Execution provider |
| 6 | InstrumentID | int | Trade.PositionForExternalUse | High | Instrument traded |
| 7 | OrderID | int | Trade.PositionForExternalUse | High | Originating order |
| 8 | Leverage | int | Trade.PositionForExternalUse | High | Leverage multiplier |
| 9 | Amount | money | Trade.PositionForExternalUse | High | Position size |
| 10 | AmountInUnitsDecimal | decimal(16,6) | Trade.PositionForExternalUse | High | Position size in units |
| 11 | NetProfit | money | Trade.PositionForExternalUse | High | Unrealized PnL |
| 12 | InitForexRate | float | Trade.PositionForExternalUse | High | Forex rate at open |
| 13 | InitDateTime | datetime | Trade.PositionForExternalUse | High | Timestamp when opened |
| 14 | LimitRate | float | Trade.PositionForExternalUse | High | Take-profit level |
| 15 | StopRate | float | Trade.PositionForExternalUse | High | Stop-loss level |
| 16+ | (remaining columns) | (varied) | Trade.PositionForExternalUse | High | All other columns inherited from Trade.PositionForExternalUse—see Trade.PositionForExternalUse documentation |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Join Type | Join Condition |
|-------------------|-----------|----------------|
| Trade.PositionForExternalUse | FROM (CTE) | PositionID, RowVersionPosition, RowVersionTree |
| Trade.PositionForExternalUse | INNER JOIN | c.PositionID = t.PositionID |
| cte (CROSS APPLY) | Subquery | MAX(LastvaersionID) per PositionID |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PosionByRowVersion
└── Trade.PositionForExternalUse
```

### 6.1 Objects This Depends On

| Object | Type |
|--------|------|
| Trade.PositionForExternalUse | View |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get deduplicated positions for specific PositionIDs

```sql
SELECT *
FROM Trade.PosionByRowVersion
WHERE PositionID IN (12345, 12346, 12347);
```

### 8.2 Get positions with latest version, including version identifier

```sql
SELECT PositionID, LastvaersionID, CID, InstrumentID, NetProfit, IsBuy
FROM Trade.PosionByRowVersion
WHERE CID = 98765;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 7.5/10*
*Object: Trade.PosionByRowVersion | Type: View | Source: etoro/etoro/Trade/Views/Trade.PosionByRowVersion.sql*
