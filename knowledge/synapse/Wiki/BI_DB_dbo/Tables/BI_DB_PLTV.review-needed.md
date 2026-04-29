# BI_DB_dbo.BI_DB_PLTV — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Column count**: Batch assignment said 7, DDL has 8 (includes LeadScore which is always NULL).
2. **LeadScore removal**: Column was deprecated 2024-10-25 but retained in DDL. Should it be dropped?
3. **Age bucket overlap**: Max_Age=35 (bucket 2) and Min_Age=35 (bucket 3) overlap at exactly 35. The SP CASE logic sends age 35 to bucket 3 (Min_Age=35). Is this the intended boundary?
4. **Regional fallback joins**: Part 2 joins Dim_Country to LTV_BI_Actual via MarketingRegionManualName. One country can appear in multiple regional fallback rows if the JOIN produces duplicates. Are duplicates expected?
5. **Observation window**: The 2-8 month FTD window means the model is always 2 months behind. Is this the desired lag?
