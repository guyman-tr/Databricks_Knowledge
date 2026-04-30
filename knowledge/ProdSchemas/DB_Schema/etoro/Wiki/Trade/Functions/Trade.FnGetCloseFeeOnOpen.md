# Trade.FnGetCloseFeeOnOpen

> Estimates the close fee at position open time, projecting what the close fee will be when the position is eventually closed, with unit-proportional scaling for partial closes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with FeeType, FeeValue, EstimateCloseFeeOnOpen, EstimateCloseFeeOnOpenByUnits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCloseFeeOnOpen estimates the close fee at the time a position is opened. This estimate is stored with the position so the platform can project total fees before the position closes. The estimate accounts for the fee configuration, the open market spread, and the initial position size. It also calculates a per-unit proportional fee for partial closes.

This function exists because displaying estimated total costs (open fee + projected close fee) at open time is required for regulatory transparency. The customer sees the full cost of the trade before confirming. The estimate is also used in equity calculations and close fee projections in end-of-day views.

---

## 2. Business Logic

### 2.1 Close Fee Estimation at Open

**What**: Projects the close fee using open-time parameters and current fee configuration.

**Columns/Parameters Involved**: `@InstrumentID`, `@IsSettled`, `@OpenTotalFees`, `@InitialLots`, `@IsBuy`, `@OpenMarketSpread`

**Rules**:
- If @OpenTotalFees = 0: EstimateCloseFeeOnOpen = 0 (no fee scenario)
- **FeePerLot**: `ROUND(@InitialLots * FeeValue, 2)` - straightforward lot-based projection
- **FeeInPercentage**: `ROUND(@OpenTotalFees + IIF(@IsBuy=1, -1, 1) * @OpenMarketSpread * FeeValue / 100, 2)` - adjusts the open fee by the spread-based close fee component
- **EstimateCloseFeeOnOpenByUnits**: `ROUND(EstimateCloseFeeOnOpen * @AmountInUnitsDecimal / ISNULL(@InitialUnits, @AmountInUnitsDecimal), 2)` - proportional fee for current units (supports partial closes)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier for fee configuration lookup. |
| 2 | @IsSettled | bit | NO | - | VERIFIED | Settlement type for fee lookup. |
| 3 | @OpenTotalFees | decimal(19,4) | NO | - | CODE-BACKED | Total fees charged at open. If 0, close fee estimate is also 0. |
| 4 | @InitialLots | decimal(16,6) | NO | - | CODE-BACKED | Initial lot count at position open. Used for per-lot fee estimate. |
| 5 | @IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy, 0=Sell. Affects spread adjustment sign in percentage formula. |
| 6 | @OpenMarketSpread | decimal(19,8) | NO | - | CODE-BACKED | Market spread at open time. Used to adjust percentage-based close fee estimate. |
| 7 | @AmountInUnitsDecimal | decimal(16,6) | NO | - | CODE-BACKED | Current units (may differ from initial after partial closes). |
| 8 | @InitialUnits | decimal(16,6) | NO | - | CODE-BACKED | Original units at position open. Used for proportional scaling. |
| 9 | FeeType (return) | varchar | NO | - | CODE-BACKED | Fee method: 'FeePerLot' or 'FeeInPercentage'. |
| 10 | FeeValue (return) | decimal | YES | - | CODE-BACKED | Raw fee configuration value (per-lot amount or percentage). |
| 11 | EstimateCloseFeeOnOpen (return) | decimal | NO | - | CODE-BACKED | Projected total close fee based on initial position size. |
| 12 | EstimateCloseFeeOnOpenByUnits (return) | decimal | NO | - | CODE-BACKED | Proportional close fee for current units (for partial close scenarios). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @IsSettled | Trade.FnGetCloseFixPerLot | Function call | Per-lot fee configuration |
| @InstrumentID, @IsSettled | Trade.FnGetCloseFeeInPercentage | Function call | Percentage fee configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD close fee estimate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCloseFeeOnOpen (function)
  ├── Trade.FnGetCloseFixPerLot (function)
  └── Trade.FnGetCloseFeeInPercentage (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCloseFixPerLot | Function | Called for per-lot fee configuration |
| Trade.FnGetCloseFeeInPercentage | Function | Called for percentage fee configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay variants | Views | CROSS APPLY for projected close fees |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 4 columns |
| ROUND(..., 2) | Precision | All fee amounts rounded to 2 decimal places |
| ISNULL(@InitialUnits, @AmountInUnitsDecimal) | Safety | Handles positions opened before InitialUnits was added |

---

## 8. Sample Queries

### 8.1 Estimate close fee for a new position

```sql
SELECT  FeeType, FeeValue, EstimateCloseFeeOnOpen, EstimateCloseFeeOnOpenByUnits
FROM    Trade.FnGetCloseFeeOnOpen(1001, 0, 5.50, 1.0, 1, 0.05, 100.0, 100.0);
```

### 8.2 Show projected close fees for all open positions

```sql
SELECT  p.PositionID, p.InstrumentID,
        fee.EstimateCloseFeeOnOpen,
        fee.EstimateCloseFeeOnOpenByUnits
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnGetCloseFeeOnOpen(
            p.InstrumentID, p.IsSettled, ISNULL(p.OpenTotalFees, 0),
            ISNULL(p.LotCountDecimal, 0), p.IsBuy, ISNULL(p.OpenMarketSpread, 0),
            p.AmountInUnitsDecimal, ISNULL(p.InitialUnits, p.AmountInUnitsDecimal)
        ) fee
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

### 8.3 Compare full vs partial close fee estimate

```sql
SELECT  'Full' AS CloseType,
        fee_full.EstimateCloseFeeOnOpenByUnits AS Fee
FROM    Trade.FnGetCloseFeeOnOpen(1001, 0, 5.50, 1.0, 1, 0.05, 100.0, 100.0) fee_full
UNION ALL
SELECT  'Partial (50%)',
        fee_partial.EstimateCloseFeeOnOpenByUnits
FROM    Trade.FnGetCloseFeeOnOpen(1001, 0, 5.50, 1.0, 1, 0.05, 50.0, 100.0) fee_partial;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCloseFeeOnOpen | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCloseFeeOnOpen.sql*
