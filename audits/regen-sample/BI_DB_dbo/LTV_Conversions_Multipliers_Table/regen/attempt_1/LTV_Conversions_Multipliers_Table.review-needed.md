# Review Needed: BI_DB_dbo.LTV_Conversions_Multipliers_Table

## Summary

Static 336-row LTV conversion multiplier lookup table. One-time load on 2024-10-30. 12 columns: 1 Tier 1, 11 Tier 2, 0 Tier 3, 0 Tier 4.

## Items for Review

### 1. Frozen Table — Guard Date

The SP is guarded by `IF CAST(GETDATE() AS DATE) <= '2024-10-30'`. This table will never refresh unless the guard is updated. Confirm with the Insights Team (Jan Iablunovskey) whether this is intentional or whether a refresh with updated FTD cohorts is planned.

### 2. FTD Cohort Range

Revenue is accumulated for FTDs from 2019–2021 only (`YEAR(dc.FirstDepositDate) IN (2019,2020,2021)`). The multipliers may not accurately represent conversion fee impact for more recent cohorts (2022+). Verify whether separate multipliers are needed for newer cohorts.

### 3. Revenue Date Range

The SP calls `Function_Revenue_Total(20190101, 20241027, 1)` — revenue accumulated through 2024-10-27. The table comment says "accumulated until 20240930" but the actual code uses 20241027. Minor discrepancy between SP comment and code.

### 4. Empty String vs NULL for Currency

The Currency column uses empty string (`''`) rather than SQL NULL for the third bucket (unmatched customers). This is a data quality consideration — downstream JOINs use `ISNULL(Currency, 'N/A')` which handles SQL NULL but the empty string requires explicit handling. The SP's `#Combinations` CROSS JOIN appends NULL (which becomes '' after ISNULL in the JOIN). Verify the JOIN pattern in SP_LTV_BI_Actual handles this correctly.

### 5. Region Column Source

Region is sourced from `Dim_Country.MarketingRegionManualName` (a manual override), not the standard `Dim_Country.Region` (which comes from Dictionary.MarketingRegion). These can differ for some countries (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Confirm this is the intended segmentation for LTV modeling.

---

*Generated: 2026-04-30*
