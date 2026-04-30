# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results

## Summary

All 10 columns are Tier 2 (ETL-computed by SP_EY_Audit_IFRS_Control). No Tier 1 inheritance applies — this is a fully computed audit/control table with no passthrough columns from upstream sources.

## Items for Human Review

### 1. IsPriceFound Column — Dead Column?

The `IsPriceFound` column is hardcoded to NULL in every INSERT branch of the SP. No logic anywhere in the SP populates this column with a non-NULL value. It may be a vestigial placeholder from an earlier design. Consider:
- Was a price-validation check planned but never implemented?
- Can this column be dropped or is it referenced by downstream reporting?

### 2. Buy Diff_Percentage Routinely 80–89%

The Buy metric comparison shows large discrepancies (80–89%) on most dates. This appears to be by design — the position-level calculation (Metric_a) counts only direct buy/sell units from the three audit tables, while the IFRS balance (Metric_b) includes additional categories (StakingBuy, some CFD subcategories). Confirm with Finance/EY team:
- Is this expected and documented in the audit workpapers?
- Should the position-level calculation be expanded to match IFRS scope?

### 3. Stored_Proc Typo

The `Stored_Proc` column always contains 'SP_EY_Audit_Automation_IFRS_Contorl' (typo: 'Contorl' instead of 'Control'). This is cosmetic but may cause confusion in audit trail queries. The actual SP name in Synapse is `SP_EY_Audit_IFRS_Control` (no typo).

### 4. Additional Metric Variants (72 rows)

Beyond the standard 2-row-per-day pattern (TotalBuy/TotalSell), 8 additional Metric_a values appear for 12 dates each (TotalBuyReal_Calc_detailed, TotalSellCFD_Calc_detailed, etc.). These are likely from an expanded version of the SP not captured in the current SSDT code. Verify whether these represent a newer iteration of the control.

### 5. Upstream Wiki Usage

The bundle provided Dim_Instrument and BI_DB_IFRS15_Daily_Balance wikis. Neither contributes Tier 1 columns to this table — Dim_Instrument is used only as a filter (InstrumentTypeID=10), and BI_DB_IFRS15_Daily_Balance is an aggregation source (SUM of TotalUnits), not a passthrough. Bundle inheritance is correctly marked as NO.
