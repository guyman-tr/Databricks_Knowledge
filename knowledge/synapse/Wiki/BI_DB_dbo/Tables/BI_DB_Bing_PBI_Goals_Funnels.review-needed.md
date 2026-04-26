# Review Needed: BI_DB_dbo.BI_DB_Bing_PBI_Goals_Funnels

## Items Requiring Human Review

### Tier 4 / Low-Confidence Items

None — all 18 columns are Tier 2 with clear SP code traceability.

### Questions for Reviewers

1. **Fivetran feed status**: The last loaded date is 2025-10-16, same as `BI_DB_Bing_PBI_Daily_Perf`. Is this feed permanently stopped or paused? Should this table be flagged as decommissioned?

2. **Unrecognized goals (36,100 NULL rows)**: What goal types exist in the source that are not mapped to the 9 DWH columns? Should the SP be updated to handle additional goal types, or are these legacy/deprecated goals?

3. **Goal triple-counting risk**: Registration_General + Registration_Brand + Bing_Registration and FTD_General + FTD_Brand + Bing_FTD may count the same customer conversion under different Bing goal tags. Is there documentation on which goals to use for official acquisition KPIs?

4. **ad_group_id type mismatch**: `ad_group_id` here is bigint but `id` in `BI_DB_Bing_PBI_Group_Dict` is varchar(max). This implicit conversion could cause JOIN issues with non-numeric ad group IDs. Should Group_Dict.id be cast to bigint on JOIN?

5. **Bing_V2_Complete definition**: The wiki documents this as "V2 onboarding completion" but the exact business definition of "V2 Complete" in eToro's Bing goal setup is not clear. What is the specific trigger for this goal?

### Potential Issues

- **SP comment "--need to fix"** on `External_Fivetran_bingads_ad_group_history` in the Group_Dict section of SP_Bing_PBI. This suggests a known data quality issue with the Group Dict source. Low impact on Goals_Funnels itself but the comment may indicate broader SP maintenance debt.

### Corrections from Prior Reviews

None.
