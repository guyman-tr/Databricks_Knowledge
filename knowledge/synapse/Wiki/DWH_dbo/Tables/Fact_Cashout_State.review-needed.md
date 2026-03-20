# DWH_dbo.Fact_Cashout_State -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All 28 columns have Tier 2 (SP code) or Tier 3 (live sample/naming) descriptions.

## Columns Needing Clarification

1. **No upstream wiki**: `Billing.BI_Cashout_State_Report` is not documented in DB_Schema wiki. All descriptions are inferred from SP code and column naming. Domain expert validation recommended.
2. **ExchaFeeInPercentage typo**: Column name appears to be a truncated form of "ExchangeFeeInPercentage". Confirm intended name.
3. **WPID semantics**: WPID is described as "Withdrawal Payment Processing ID" based on naming convention. Confirm actual business meaning.
4. **PIPsInUSD semantics**: "PIPs" typically means "percentage in points" in forex context. Confirm whether this refers to the exchange fee yield in USD or some other measure.

## Structural Questions

1. **Custom pipeline**: `BI_Cashout_State_Report` is not in `_generic_pipeline_mapping.json`. Identify the pipeline name, schedule, and monitoring dashboard for this data source.
2. **ROUND_ROBIN distribution**: Consider whether HASH(WithdrawID) or HASH(CID) would improve query performance for common analytical patterns. Current ROUND_ROBIN may be intentional for full-scan aggregations.
3. **Daily snapshot only**: SP refreshes only today's rows. Historical state changes (e.g., a status that changed 2 days ago and then changed again yesterday) may not be captured. Confirm if this is acceptable or if a full-history strategy is needed.
4. **CreditID addition (2025-08-13)**: Confirm what `CreditID` represents in business terms. Is it a credit line, credit account, or credit transaction ID?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
