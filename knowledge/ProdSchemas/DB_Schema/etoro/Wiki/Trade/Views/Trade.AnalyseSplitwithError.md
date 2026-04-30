# Trade.AnalyseSplitwithError

> Diagnostic view that surfaces the stock-split error message and validates whether debug-captured numeric columns from failed split processing are castable to their target types (Value Ok vs Bug).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ErrorMessage + validation flags per column |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.AnalyseSplitwithError is a **diagnostic view** used when stock split processing fails. It cross-joins two CTEs: (1) validation of key numeric columns from Trade.DebugSplitwithError (whether each value is castable to its target type or is the sentinel -999999999999999/NULL), and (2) the ErrorMessage from Trade.PositionToSplitByJob where PositionWasSplit = -2. The view is referenced in the RAISERROR message of Trade.SplitOpenPositions: "check table Trade.AnalyseSplitwithError For Error Logs."

This view exists so DBAs and developers can quickly see the error details and which columns may have caused the failure when a split job errors. Without it, troubleshooting would require manual inspection of both DebugSplitwithError and PositionToSplitByJob. The view may return 0 rows when no split error has occurred (PositionToSplitByJob has no rows with PositionWasSplit = -2) or when DebugSplitwithError does not exist or is empty.

Data flows: Trade.SplitbyJob populates Trade.DebugSplitwithError and sets PositionWasSplit = -2 with ErrorMessage in Trade.PositionToSplitByJob when a split fails. SplitOpenPositions RAISERRORs and directs operators to check this view. The view is typically queried manually during incident response.

---

## 2. Business Logic

### 2.1 Per-Column Validation (Value Ok vs Bug)

**What**: Each numeric column from DebugSplitwithError is validated for safe casting to its target type. Sentinel values (-999999999999999, -9999999 for SLManualVer) and NULL are treated as "Value Ok"; any other value is checked with TRY_CAST.

**Columns/Parameters Involved**: AmountInUnitsDecimal, LotCountDecimal, InitialUnits, InitialLotCount, InitForexRate, SpreadedPipBid, SpreadedPipAsk, OrderPriceRate, MarketPriceRate, LastOpPriceRate, LimitRate, LimitRate_PriceRatio, StopRate, NextThresHold, SLManualVer.

**Rules**:
- If value = -999999999999999 OR NULL -> "Value Ok" (sentinel or unpopulated for that step).
- Else: TRY_CAST to target type; if NULL (cast failed) -> "Bug", else "Value Ok".
- Target types: decimal(16,6) for units/lots, decimal(16,8) for rates, BIGINT for SLManualVer.

### 2.2 Error Message Source

**What**: ErrorMessage comes from PositionToSplitByJob WHERE PositionWasSplit = -2. Only one such row is taken (TOP 1).

**Rules**:
- PositionWasSplit: -2 = specific error with ErrorMessage. -1 = general error.
- The view CROSS JOINs validation CTE with ErrorMessage CTE. If no error row exists, cte2 returns no rows and the view returns 0 rows.

---

## 3. Data Overview

The view did not exist or returned no rows in the connected database at documentation time (Trade.DebugSplitwithError or dependent objects may not exist in all environments). Representative output inferred from DDL:

| ErrorMessage | AmountInUnitsDecimal | LotCountDecimal | InitialUnits | InitForexRate | LimitRate | StopRate | SLManualVer | Meaning |
|--------------|---------------------|-----------------|--------------|---------------|-----------|----------|-------------|---------|
| (error text from PositionToSplitByJob) | Value Ok | Value Ok | Bug | Value Ok | Value Ok | Value Ok | Value Ok | Split failed; InitialUnits has non-castable value. Other columns OK. |

**Selection criteria**: Inferred from DDL. When a split fails, operators run this view to see ErrorMessage and which columns failed type validation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ErrorMessage | varchar(8000) | YES | - | CODE-BACKED | Error details from Trade.PositionToSplitByJob when PositionWasSplit = -2. Inherited from base table. |
| 2 | AmountInUnitsDecimal | varchar(10) | NO | - | CODE-BACKED | Computed: "Value Ok" if sentinel/NULL or TRY_CAST succeeds; "Bug" if cast fails. From Trade.DebugSplitwithError. |
| 3 | LotCountDecimal | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Intended post-split lot count. |
| 4 | InitialUnits | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Original unit count. |
| 5 | InitialLotCount | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Original lot count. |
| 6 | InitForexRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Intended init forex rate. |
| 7 | SpreadedPipBid | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Intended spreaded pip bid. |
| 8 | SpreadedPipAsk | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Intended spreaded pip ask. |
| 9 | OrderPriceRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Order price rate. |
| 10 | MarketPriceRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Market price rate. |
| 11 | LastOpPriceRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Last operation price rate. |
| 12 | LimitRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Take-profit rate. |
| 13 | LimitRate_PriceRatio | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Limit rate times price ratio. |
| 14 | StopRate | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Stop-loss rate. |
| 15 | NextThresHold | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. Next threshold. |
| 16 | SLManualVer | varchar(10) | NO | - | CODE-BACKED | Same validation pattern. SL manual version (BIGINT target). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all validation columns) | Trade.DebugSplitwithError | Implicit | Source of position/tree data for validation |
| ErrorMessage | Trade.PositionToSplitByJob | Implicit | Error message when PositionWasSplit = -2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitOpenPositions | RAISERROR | Logical | Directs operators to check this view for error logs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AnalyseSplitwithError (view)
├── Trade.DebugSplitwithError (table)
└── Trade.PositionToSplitByJob (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DebugSplitwithError | Table | FROM (TOP 1) - position/tree columns for validation |
| Trade.PositionToSplitByJob | Table | FROM (TOP 1 WHERE PositionWasSplit = -2) - ErrorMessage |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitOpenPositions | Procedure | RAISERROR references view name for operator guidance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Inspect split error details and validation

```sql
SELECT *
  FROM Trade.AnalyseSplitwithError WITH (NOLOCK);
```

### 8.2 Check if any column reported Bug

```sql
SELECT ErrorMessage, AmountInUnitsDecimal, LotCountDecimal, InitialUnits, InitialLotCount,
       InitForexRate, LimitRate, StopRate, SLManualVer
  FROM Trade.AnalyseSplitwithError WITH (NOLOCK)
 WHERE AmountInUnitsDecimal = 'Bug'
    OR LotCountDecimal = 'Bug'
    OR InitialUnits = 'Bug'
    OR InitForexRate = 'Bug'
    OR LimitRate = 'Bug'
    OR StopRate = 'Bug';
```

### 8.3 Combine with raw debug data (when DebugSplitwithError exists)

```sql
SELECT a.ErrorMessage, a.AmountInUnitsDecimal, a.InitialUnits, d.AmountInUnitsDecimal AS RawAmount
  FROM Trade.AnalyseSplitwithError a WITH (NOLOCK)
 CROSS JOIN Trade.DebugSplitwithError d WITH (NOLOCK)
 WHERE d.PositionID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,7,8*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.AnalyseSplitwithError | Type: View | Source: etoro/etoro/Trade/Views/Trade.AnalyseSplitwithError.sql*
