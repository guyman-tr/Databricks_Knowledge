# DWH_dbo.Dim_Channel — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | fiktivo (AffWizz affiliate system) |
| **Production Schema** | dbo |
| **Production Table** | tblaff_Affiliates (primary) + tblaff_MarketingExpense + tblaff_AffiliatesGroups |
| **Generic Pipeline ID** | Not in _generic_pipeline_mapping.json (custom staging pipeline) |
| **Lake Path** | DWH_staging.fiktivo_dbo_tblaff_Affiliates |
| **Staging Table** | DWH_dbo.Ext_Dim_SubChannel_UnifyCode (intermediate) |
| **ETL SP** | SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse → SP_Dim_Channel |
| **Upstream Wiki** | None (AffWizz is an external affiliate platform, no DB_Schema wiki) |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Notes |
|---|-----------|-------------|---------------|-----------|-------|
| 1 | SubChannelID | tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName, AffiliatesGroupsName | CASE: 30+ pattern-matching rules on lowercased Contact string | DWH-derived classification; not a production FK |
| 2 | Channel | tblaff_MarketingExpense + tblaff_AffiliatesGroups | MarketingExpenseName, AffiliatesGroupsName | CASE with overrides: Introducing Agents→Affiliate, AffID 56662/56663→Direct | Top-level channel category |
| 3 | SubChannel | tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName | Parallel CASE to SubChannelID returning name strings | Human-readable sub-channel label |
| 4 | Organic/Paid | N/A | N/A | CASE: Channel IN (Friend Referral, Direct, SEO) OR SubChannel='Google Brand' → Organic, else Paid | DWH-computed in SP_Dim_Channel (second ETL step) |
| 5 | InsertDate | N/A | N/A | GETDATE() | ETL load timestamp |
| 6 | UpdateDate | N/A | N/A | GETDATE() | ETL load timestamp (same as InsertDate — TRUNCATE+INSERT pattern) |

## Columns Lost (Production → DWH)

The intermediate Ext_Dim_SubChannel_UnifyCode table has 6 columns; Dim_Channel uses all 6. However, the upstream Ext_Dim_Channel_Affiliate_UnifyCode has 24 columns, of which only SubChannelID, SubChannel, Channel are carried forward. Lost columns include: AffiliateID, DateCreated, MarketingExpenseID, MarketingExpenseName, Contact, AffiliatesGroupsName, ContractName, AccountActivated, LoginName, UserName1-4, Email, CompanyAddress, City, CountryID, WebSiteURL, LanguageName, WebSiteTitle, GCID, EntityName, ContactPersonFullName, Telephone. These are available in Dim_Affiliate instead.

## Columns Added (DWH-specific)

| Column | Origin | Description |
|--------|--------|-------------|
| Organic/Paid | SP_Dim_Channel CASE | Binary classification not in production; computed from Channel + SubChannel |
| InsertDate | GETDATE() | ETL metadata |
| UpdateDate | GETDATE() | ETL metadata |
