# Column Lineage: Dealing_dbo.Dealing_Best_Execution_Compensation_HBC

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Best_Execution
**⚠️ Pipeline status**: POTENTIALLY DECOMMISSIONED — max date 2025-01-11

## Pipeline Summary

Identical to CBH. See `Dealing_Best_Execution_Compensation_CBH.lineage.md` for the full pipeline diagram. The only differences are:
- HBC positions use commission-based spread (not forex-spreaded prices)
- HBC section is written FIRST in the SP (before CBH)
- HBC draws from `#TotalData_HBC_WithMarketHours` temp table (vs `#TotalData_CBH_WithMarketHours`)

## Column-Level Lineage

All columns have identical lineage to `Dealing_Best_Execution_Compensation_CBH` except:

| Column | HBC-Specific Transformation |
|--------|----------------------------|
| Spread | `(CommissionByUnits / (AmountInUnitsDecimal × ConversionRate)) / 2` for opens; `(CommissionOnClose / (AmountInUnitsDecimal × ConversionRate)) / 2` for closes — commission-derived, not from forex spreaded prices |
| HedgingMode | Always 'HBC' |
| InitForex_AskSpreaded | NULL for HBC positions (CBH uses this; HBC uses commission approach instead) |

## Key Difference: Spread Calculation

| | CBH | HBC |
|-|-----|-----|
| Indicator | `InitForex_AskSpreaded IS NOT NULL` | `InitForex_AskSpreaded IS NULL` |
| Spread source | Spreaded forex price (AskSpreaded − Rate) | Commission / (Units × FX) / 2 |
| Data source | DWH_dbo.Dim_Position.InitForex_AskSpreaded | DWH_dbo.Dim_Position.CommissionByUnits / CommissionOnClose |

## ETL Pattern

- DELETE WHERE Date=@Date → INSERT DISTINCT
- Written BEFORE CBH in same SP run
- Input: OverThreshold=1 rows from Dealing_Daily_Slippage_Positions where HedgingMode='HBC'
