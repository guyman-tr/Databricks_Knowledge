# BI_DB_dbo.BI_DB_RevenueForum — Review Needed

## Tier 4 Items (Low Confidence)

1. **Columns 24-37 (CopyAmount through UnknownInstrumentAmount)**: These 14 columns exist in DDL but are 100% NULL. The SP has commented-out code that would populate them from #RevAssetFinal. Marked Tier 4 as their intended semantics come from commented code — confirm with Ofir Chloe Gal whether these will be activated or should be dropped from the DDL.

## Questions for Reviewer

1. **Fake FTD exclusion**: The SP hardcodes exclusion of customers with FirstDepositDate between 2025-08-19 and 2025-08-21 AND FirstDepositAmount=1. What was the incident that caused this? Should it be parameterized or removed now?
2. **Cost source**: External_Fivetran_gsheet_costfinance — is this Google Sheet owned by Finance? Who maintains it? Is there a schedule for when it's updated?
3. **NOLOCK on Dim_Date**: The SP uses `WITH (NOLOCK)` on Dim_Date (line 319) which is unnecessary in Synapse. Not a functional issue but technically incorrect syntax for Synapse SQL Pool.
4. **Sibling table**: BI_DB_RevenueForum_Revenue stores the asset-type × settled × copy breakdown. Should it be documented as a separate object or as a view over this table?

## Upstream Verification

| Column | Source | Verified |
|--------|--------|----------|
| Country | Dim_Country.Name wiki (Tier 1 — Dictionary.Country) | Yes |
| Region | Dim_Country.MarketingRegionManualName wiki (Tier 3 — Ext_Dim_Country) | Yes |
| Club | Dim_PlayerLevel.Name wiki (Tier 1 — Dictionary.PlayerLevel) | Yes |
| Regulation | Dim_Regulation.Name wiki (Tier 1 — Dictionary.Regulation) | Yes |
