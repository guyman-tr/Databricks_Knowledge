# DWH_dbo.Dim_Fund - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code) or Tier 3 (live data).

## Columns Needing Clarification

- **FundAccountID vs FundOwnerID**: In all observed sample rows, FundAccountID = FundOwnerID (same integer value). Are these always the same? Is FundAccountID the trading account while FundOwnerID is the customer account? Or are they redundant?
- **HasCrypto dropped**: The staging column `HasCrypto` (bit) from etoro.Trade.Fund is not loaded into Dim_Fund. Was this intentional? Could "does this fund include crypto assets" be useful for DWH analytics?
- **CreateDate/LastUpdateDate dropped**: Source has fund creation and last-update timestamps but these are excluded from DWH. Only the ETL load timestamp (UpdateDate) is stored. Is this an intentional simplification?
- **MinCopyAmount currency**: Observed values are 500 and 5000. Are these always USD? What currency does eToro use for fund minimums?
- **FundType NULL**: DDL allows NULL for FundType, but all 877 rows have a value. Were there ever NULLs, or is this just a DDL oversight?

## Structural Questions

- **No active FK consumers**: Despite having 877 funds loaded daily, no DWH fact or dimension table references FundID. Where is fund-level analysis performed? Is there a fact table (e.g., Fact_Fund_AUM) planned or in a different schema?
- **Source is etoro.Trade.Fund (not Dictionary)**: Unlike most Dim_ tables in SP_Dictionaries, this comes from the Trade schema. Should it be considered a "slowly changing dimension" with historical tracking rather than a simple truncate-replace?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
