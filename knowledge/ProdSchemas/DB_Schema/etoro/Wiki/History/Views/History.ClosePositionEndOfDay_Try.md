# History.ClosePositionEndOfDay_Try

> Experimental variant of History.ClosePositionEndOfDay - identical structure and 30-day filter but uses inline IIF fee calculation instead of Trade.FnGetCloseFeeOnOpen, and Trade.FnGetCloseFeeInPercentage for fee percentage lookup.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (int, from History.PositionForExternalUse) |
| **Partition** | N/A (view - 30-day filter) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

`History.ClosePositionEndOfDay_Try` is the "_Try" (experimental) variant of `History.ClosePositionEndOfDay`. The two views are structurally identical - same PriceMaxData CTE, same 126-column position base from History.PositionForExternalUse, same EndOfDayPnLInDollars CASE expression, same 4 CROSS APPLYs for conversion rate, closing rate, and PnL calculation, same 30-day WHERE clause.

The sole difference is in how `EstimateCloseFeeOnOpen` and `EstimateCloseFeeOnOpenByUnits` are computed:
- **Current version**: calls `Trade.FnGetCloseFeeOnOpen` (OUTER APPLY function) - encapsulates fee logic in a function call
- **Try version**: computes fees inline using `IIF` expressions + `Trade.FnGetCloseFeeInPercentage` (OUTER APPLY for fee percentage)

The inline formula:
- `EstimateCloseFeeOnOpen = IIF(OpenTotalFees = 0, 0, ROUND(OpenTotalFees + (IIF(IsBuy=1, -1, 1) * OpenMarketSpread * FeeInPercentage.FeeValue / 100.00), 2))`
- `EstimateCloseFeeOnOpenByUnits = IIF(OpenTotalFees = 0, 0, ROUND((above) * AmountInUnitsDecimal / ISNULL(InitialUnits, AmountInUnitsDecimal), 2))`

This suggests the "_Try" version was testing whether the fee calculation could be expressed more directly using the market spread and a percentage lookup, possibly to compare results with the `FnGetCloseFeeOnOpen` approach.

The DDL comment `---Missing Columns` on the PnL CROSS APPLY's ConversionRate parameter suggests this view was in an incomplete state when saved.

No stored procedures consume this view. See `History.ClosePositionEndOfDay.md` for the full business context.

---

## 2. Business Logic

Identical to `History.ClosePositionEndOfDay` except for fee calculation. See that document for full logic.

### 2.1 Fee Calculation Difference

**EstimateCloseFeeOnOpen (Try version)**:
- If OpenTotalFees = 0: return 0 (no close fee if no open fee)
- Otherwise: `ROUND(OpenTotalFees + (IIF(IsBuy=1,-1,1) * OpenMarketSpread * FeeInPercentage.FeeValue / 100.00), 2)`
  - Long positions: `OpenTotalFees - (OpenMarketSpread * FeePercentage)`
  - Short positions: `OpenTotalFees + (OpenMarketSpread * FeePercentage)`

**FeeInPercentage**: from `OUTER APPLY Trade.FnGetCloseFeeInPercentage(HPOS.InstrumentID, HPOS.IsSettled)` - returns a fee value as a percentage.

---

## 3. Data Overview

Identical to `History.ClosePositionEndOfDay`. No active consumers.

---

## 4. Elements

Identical to `History.ClosePositionEndOfDay` plus the differently-computed:

| # | Added Element | Type | Source | Description |
|---|--------------|------|--------|-------------|
| 127 | EndOfDayPnLInDollars | MONEY | Trade.FnCalculatePnLWrapper | Same as ClosePositionEndOfDay |
| 128 | EstimateCloseFeeOnOpen | MONEY | Inline IIF + Trade.FnGetCloseFeeInPercentage | Close fee estimate using inline formula |
| 129 | EstimateCloseFeeOnOpenByUnits | MONEY | Inline IIF + Trade.FnGetCloseFeeInPercentage | Per-units fee estimate |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `History.ClosePositionEndOfDay` EXCEPT:
- Uses `Trade.FnGetCloseFeeInPercentage` (OUTER APPLY) instead of `Trade.FnGetCloseFeeOnOpen`

### 5.2 Referenced By (other objects point to this)

No active consumers in the SSDT repo.

---

## 6. Dependencies

```
History.ClosePositionEndOfDay_Try (view, 30-day filter)
|--> History.PositionForExternalUse (view)
|--> History.CurrencyPriceMaxDateWithSplitView (view)
|--> Trade.FnGetConversionInstrument (function)
|--> Trade.FnIsRealPosition (function)
|--> Trade.FnCalculatePnLWrapper (function)
+--> Trade.FnGetCloseFeeInPercentage (function) [vs FnGetCloseFeeOnOpen in current version]
```

---

## 7. Technical Details

Experimental variant with no active consumers. Candidate for removal or promotion to replace `ClosePositionEndOfDay` if the inline fee formula is confirmed correct.

---

## 8. Sample Queries

See `History.ClosePositionEndOfDay.md` - identical access pattern.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.3/10, Logic: 8.5/10, Relationships: 8.3/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/5 (1, 5, 7, 8, 10, 11) - experimental variant*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ClosePositionEndOfDay_Try | Type: View | Source: etoro/etoro/History/Views/History.ClosePositionEndOfDay_Try.sql*
