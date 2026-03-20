# DWH_dbo.Dim_Affiliate — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | fiktivo (AffWizz) |
| **Production Tables** | tblaff_Affiliates, tblaff_AffiliatesGroups, and related |
| **Staging Pipeline** | SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| **ETL SP** | SP_Dim_Affiliate (TRUNCATE + INSERT) |
| **Upstream Wiki** | None (AffWizz is external system) |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|---------------|-----------|
| 1 | AffiliateID | Ext_Dim_Channel_Affiliate_UnifyCode | AffiliateID | Passthrough |
| 2 | DateCreated | Ext_Dim_SubChannel_UnifyCode | DateCreated | Passthrough |
| 3 | SubChannelID | Ext_Dim_SubChannel_UnifyCode | SubChannelID | Passthrough |
| 4 | Contact | Ext_Dim_Channel_Affiliate_UnifyCode | Contact | Passthrough |
| 5 | ContractName | Ext_Dim_Channel_Affiliate_UnifyCode | ContractName | Passthrough |
| 6 | ContractType | Computed | ContractName + AffiliateID + Channel | CASE expression — keyword pattern matching |
| 7 | AffiliatesGroupsName | Ext_Dim_Channel_Affiliate_UnifyCode | AffiliatesGroupsName | Passthrough |
| 8 | AccountActivated | Ext_Dim_Channel_Affiliate_UnifyCode | AccountActivated | Passthrough |
| 9 | LoginName | Ext_Dim_Channel_Affiliate_UnifyCode | LoginName | Passthrough |
| 10 | TradingAccount_RealCID | Ext_Dim_Affiliate_Customer (×4) | CID | COALESCE across 4 username lookups |
| 11 | TradingAccount_UserName | Ext_Dim_Affiliate_Customer (×4) | UserName | COALESCE across 4 username lookups |
| 12 | Email | Ext_Dim_Channel_Affiliate_UnifyCode | Email | Passthrough (MASKED) |
| 13 | CompanyAddress | Ext_Dim_Channel_Affiliate_UnifyCode | CompanyAddress | Passthrough |
| 14 | City | Ext_Dim_Channel_Affiliate_UnifyCode | City | Passthrough (MASKED) |
| 15 | CountryID | Ext_Dim_Channel_Affiliate_UnifyCode | CountryID | Passthrough |
| 16 | WebSiteURL | Ext_Dim_Channel_Affiliate_UnifyCode | WebSiteURL | Passthrough |
| 17–23 | Registration[FirstDate..LastYear] | Ext_Dim_Affiliate_Registrations | Same names | Passthrough |
| 24–30 | FTD[FirstDate..LastYear] | Ext_Dim_Affiliate_FTD | Same names | Passthrough |
| 31–37 | FTDe[FirstDate..LastYear] | Ext_Dim_Affiliate_FTDe | Same names | Passthrough |
| 38 | MasterAffiliateID | Ext_Dim_Affiliate_MasterAffiliate | MasterAffiliateID | Passthrough |
| 39 | UpdateDate | Computed | — | GETDATE() |
| 40–42 | Registration[ThisMonth..ThisYear] | Ext_Dim_Affiliate_Registrations | Same names | Passthrough |
| 43–45 | FTDe[ThisMonth..ThisYear] | Ext_Dim_Affiliate_FTDe | Same names | Passthrough |
| 46–48 | FTD[ThisMonth..ThisYear] | Ext_Dim_Affiliate_FTD | Same names | Passthrough |
| 49 | LanguageName | Ext_Dim_Channel_Affiliate_UnifyCode | LanguageName | Passthrough |
| 50 | WebSiteTitle | Ext_Dim_Channel_Affiliate_UnifyCode | WebSiteTitle | Passthrough |
| 51 | GCID | Ext_Dim_Channel_Affiliate_UnifyCode | GCID | Passthrough |
| 52 | EntityName | Ext_Dim_Channel_Affiliate_UnifyCode | EntityName | Passthrough |
| 53 | ContactPersonFullName | Ext_Dim_Channel_Affiliate_UnifyCode | ContactPersonFullName | Passthrough |
| 54 | Telephone | Ext_Dim_Channel_Affiliate_UnifyCode | Telephone | Passthrough |
| 55 | SubChannel | Ext_Dim_SubChannel_UnifyCode | SubChannel | Passthrough |
| 56 | Channel | Ext_Dim_SubChannel_UnifyCode | Channel | Passthrough |
