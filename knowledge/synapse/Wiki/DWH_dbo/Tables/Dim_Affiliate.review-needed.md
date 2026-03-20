# DWH_dbo.Dim_Affiliate — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

1. **ContractType values**: Are the numeric codes (0, 2, 3, 4, 6, 7, 8) defined in a reference table? The mapping is derived from CASE logic — confirm no values were missed or changed
2. **Hardcoded AffiliateIDs**: IDs 12306, 14596, 30122, 37665, 18230 are forced to ContractType=6 (eCost). Are these still valid overrides?
3. **FTDe definition**: What exactly qualifies as an "FTDe" (First Time Deposit equivalent)? Is it demo-to-real conversion, or a different qualifying event?
4. **TradingAccount lookup**: The 4-way COALESCE on UserName1..UserName4 — what are these 4 username sources? (e.g., old username, new username, alias, email-based username?)
5. **GCID vs TradingAccount_RealCID**: Both link the affiliate to a customer. When are they different?

## Structural Questions

1. **Masked columns**: Email and City are masked. Should CompanyAddress and Telephone also be masked for GDPR compliance?
2. **REPLICATE distribution**: Confirmed appropriate for this small dimension (~thousands of rows)
3. **Registration/FTD staging tables**: What is the source of `Ext_Dim_Affiliate_Registrations`, `Ext_Dim_Affiliate_FTD`, `Ext_Dim_Affiliate_FTDe`? Are these computed in Synapse or imported from AffWizz?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
