# Trade.OpenPositionEndOfDay_PartialCloseFix

> Specialized end-of-day PnL view that adjusts for partial position closes by using the pre-close unit count from History.PositionChangeLog_Active_BIGINT, ensuring PnL reflects the full position value before intraday partial closures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Specialized variant of Trade.OpenPositionEndOfDay |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDay_PartialCloseFix addresses a specific edge case in end-of-day PnL calculation: positions that were partially closed during the trading day. When a customer partially closes a position (e.g., selling 50 of 100 units), the remaining position has fewer units at end-of-day than it had at market open. Standard end-of-day views would calculate PnL on the reduced unit count, understating the day's actual exposure.

This view fixes that by querying History.PositionChangeLog_Active_BIGINT for ChangeTypeID=12 (partial close) events that occurred today. For positions with a partial close, it uses PreviousAmountInUnits (the unit count before the partial close) instead of the current AmountInUnitsDecimal. This gives a more accurate representation of the position's exposure during the trading day.

---

## 2. Business Logic

### 2.1 Partial Close Unit Adjustment

**What**: Uses the pre-partial-close unit count for PnL calculation on positions partially closed today.

**Columns/Parameters Involved**: `PositionID`, `PreviousAmountInUnits`, `AmountInUnitsDecimal`

**Rules**:
- PartialPosition CTE: Queries History.PositionChangeLog_Active_BIGINT for ChangeTypeID=12 (partial close) events occurring today
- PartialPositionFirstRow CTE: Takes the earliest partial close per position (first PreviousAmountInUnits)
- PnL calculation uses: `CASE WHEN PP.PositionID IS NULL THEN TPOS.AmountInUnitsDecimal ELSE PP.PreviousAmountInUnits END`
- If no partial close today, uses current units as normal

---

## 3. Data Overview

N/A - same base position data with unit count adjustment for partially closed positions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | End-of-day PnL using adjusted unit count. For partially closed positions, uses PreviousAmountInUnits instead of current AmountInUnitsDecimal. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | End-of-day PnL in cents using adjusted units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDateWithSplitView | LEFT JOIN | Split-adjusted max-date prices |
| PartialPosition | History.PositionChangeLog_Active_BIGINT | CTE | Partial close events (ChangeTypeID=12) |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL with adjusted units |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay_PartialCloseFix (view)
+-- Trade.PositionForExternalUse (view)
+-- History.CurrencyPriceMaxDateWithSplitView (view) [cross-schema]
+-- History.PositionChangeLog_Active_BIGINT (table) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM |
| History.CurrencyPriceMaxDateWithSplitView | View | LEFT JOIN - prices |
| History.PositionChangeLog_Active_BIGINT | Table | CTE - partial close history |
| Trade.FnIsRealPosition | Function | CROSS APPLY |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Find positions with partial close adjustment
```sql
SELECT  PositionID, AmountInUnitsDecimal, PnLInDollars
FROM    Trade.OpenPositionEndOfDay_PartialCloseFix WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Compare adjusted vs unadjusted PnL
```sql
SELECT  a.PositionID,
        a.PnLInDollars AS AdjustedPnL,
        b.PnLInDollars AS UnadjustedPnL,
        a.PnLInDollars - b.PnLInDollars AS Difference
FROM    Trade.OpenPositionEndOfDay_PartialCloseFix a WITH (NOLOCK)
JOIN    Trade.OpenPositionEndOfDay_before0192025 b WITH (NOLOCK) ON a.PositionID = b.PositionID
WHERE   a.PnLInDollars <> b.PnLInDollars;
```

### 8.3 Total PnL impact of partial close adjustments
```sql
SELECT  COUNT(*) AS AffectedPositions, SUM(PnLInDollars) AS TotalAdjustedPnL
FROM    Trade.OpenPositionEndOfDay_PartialCloseFix WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Specialized variant addressing partial close PnL calculation edge case.

---

*Generated: 2026-03-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_PartialCloseFix | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_PartialCloseFix.sql*
