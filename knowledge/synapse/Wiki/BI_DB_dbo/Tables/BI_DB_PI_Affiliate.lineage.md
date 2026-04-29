# BI_DB_dbo.BI_DB_PI_Affiliate — Column Lineage

## Writer SP
`BI_DB_dbo.SP_PI_Affiliate` — daily DELETE+INSERT by DateID

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Affiliate | DWH_dbo | Affiliate accounts, FTD counts, SubChannelID |
| DWH_dbo.Dim_Customer | DWH_dbo | PI identification (GuruStatusID), UserName, PII for matching |
| DWH_dbo.Dim_Channel | DWH_dbo | Channel name ('Affiliate', 'Friend Referral') |
| DWH_dbo.Dim_Manager | DWH_dbo | Account manager name |
| DWH_dbo.Dim_GuruStatus | DWH_dbo | PITier (GuruStatusName) |
| DWH_dbo.Dim_Mirror | DWH_dbo | ParentCID for copy relationship attribution |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | MIMO amounts (ActionTypeID 15-18) |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | SerialID for affiliate-customer linkage |
| general.etoroGeneral_History_GuruCopiers | general | AUM components (Cash, Investment, PnL, DetachedPos, Dit_PnL) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | (computed) | — | @yesterday parameter |
| DateID | (computed) | — | INT conversion of @yesterday |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough |
| GuruStatusID | DWH_dbo.Dim_Customer | GuruStatusID | passthrough |
| PITier | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup |
| Manager | DWH_dbo.Dim_Manager | FirstName + ' ' + LastName | concatenation |
| PI_RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| AffiliateID | DWH_dbo.Dim_Affiliate | AffiliateID | STRING_AGG (comma-separated if multiple) |
| Aff_Channel | DWH_dbo.Dim_Channel | Channel | STRING_AGG |
| Aff_WebSiteURL | DWH_dbo.Dim_Affiliate | WebSiteURL | STRING_AGG |
| FTD* (5 cols) | DWH_dbo.Dim_Affiliate | FTD counts | SUM per PI across all affiliates |
| MoneyIn/Out/Net PI (Yesterday/LastMonth/LastYear/YTD) | DWH_dbo.Fact_CustomerAction | -Amount | SUM by ActionTypeID 15-18, WHERE ParentCID = PI |
| MoneyIn/Out/Net Others (Yesterday/LastMonth/LastYear/YTD) | DWH_dbo.Fact_CustomerAction | -Amount | SUM by ActionTypeID 15-18, WHERE ParentCID <> PI |
| AUM_in_PI | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPos+Dit_PnL | SUM WHERE ParentCID = PI |
| AUM_in_Copy_Others | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPos+Dit_PnL | SUM WHERE ParentCID <> PI |
| Total_AUM | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPos+Dit_PnL | SUM all |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
