# eMoney_dbo.eMoney_Marketing_EmailTracking — Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | Send Date | BI_DB_dbo.BI_DB_SFMC_Report | SendDateID | CONVERT(DATE, CONVERT(VARCHAR(10), SendDateID)) | 2 |
| 2 | Country | DWH_dbo.Fact_SnapshotCustomer + Dim_Country | CountryID → Name | Point-in-time country via Fact_SnapshotCustomer snapshot join (DateRangeID between SendDateID range) | 2 |
| 3 | Club | DWH_dbo.Fact_SnapshotCustomer + Dim_PlayerLevel | PlayerLevelID → Name | Point-in-time club via Fact_SnapshotCustomer snapshot join | 2 |
| 4 | CampaignNumber | BI_DB_dbo.BI_DB_SFMC_Report | CampaignNumber | Passthrough; filtered to hardcoded whitelist of ~20 campaign numbers | 2 |
| 5 | CampaignName | BI_DB_dbo.BI_DB_SFMC_Report | CampaignName | Passthrough | 2 |
| 6 | EmailName | BI_DB_dbo.BI_DB_SFMC_Report | EmailName | Passthrough | 2 |
| 7 | Delivered | BI_DB_dbo.BI_DB_SFMC_Report | GCID | COUNT(DISTINCT GCID) per campaign/date/country/club group (filter: Delivered=1) | 2 |
| 8 | UniqueOpen | BI_DB_dbo.BI_DB_SFMC_Report | UniqueOpen | SUM(UniqueOpen) per group | 2 |
| 9 | CountOpen | BI_DB_dbo.BI_DB_SFMC_Report | CountOpen | SUM(CountOpen) per group | 2 |
| 10 | UniqueClicks | BI_DB_dbo.BI_DB_SFMC_Report | UniqueClicks | SUM(UniqueClicks) per group | 2 |
| 11 | CountClicks | BI_DB_dbo.BI_DB_SFMC_Report | CountClicks | SUM(CountClicks) per group | 2 |
| 12 | CreatedAccount_Open | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | COUNT(DISTINCT GCID) where eTM account created within 3 days of first email open (UniqueOpen=1) | 2 |
| 13 | CreateAccount_Clicks | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | COUNT(GCID) where eTM account created within 3 days of first email open (UniqueClicks=1) | 2 |
| 14 | CreateAccount | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | COUNT(GCID) from UNION of open+click 3-day conversion records | 2 |
| 15 | CardActivations | eMoney_dbo.eMoney_Panel_FirstDates | CardActivationTime | COUNT(DISTINCT GCID) where card activated within 3 days of first email open (campaign 2208210977 only) | 2 |
| 16 | UpdateDate | SP_eMoney_Marketing_EmailTracking | GETDATE() | ETL load timestamp | 2 |

## ETL Chain Summary

```
BI_DB_dbo.BI_DB_SFMC_Report (Salesforce Marketing Cloud email delivery/engagement data)
  + BI_DB_dbo.BI_DB_SFMC_SendJobs (send job metadata; filter: TriggeredSendExternalKey IS NOT NULL)
  + DWH_dbo.Dim_Customer (customer validation: IsValidCustomer=1, VerificationLevelID=3, PlayerLevelID<>4)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Country + Dim_PlayerLevel (point-in-time country/club)
  + eMoney_dbo.eMoney_Dim_Account (3-day account creation conversion tracking)
  + eMoney_dbo.eMoney_Panel_FirstDates (3-day card activation tracking)
    |-- SP_eMoney_Marketing_EmailTracking (full DELETE + INSERT) ---|
    |   Currently commented out in SP_eMoney_Execute_Group_One (SP 12) |
    v
eMoney_dbo.eMoney_Marketing_EmailTracking (0 rows — currently empty/suspended)
  |-- UC Gold: _Not_Migrated ---|
```

## Source Objects

- `BI_DB_dbo.BI_DB_SFMC_Report` (SFMC email engagement per customer)
- `BI_DB_dbo.BI_DB_SFMC_SendJobs` (send job metadata)
- `DWH_dbo.Dim_Customer` (eligibility filter)
- `DWH_dbo.Fact_SnapshotCustomer` (point-in-time country/club)
- `DWH_dbo.Dim_Country` (country name lookup)
- `DWH_dbo.Dim_PlayerLevel` (club name lookup)
- `eMoney_dbo.eMoney_Dim_Account` (account creation date — conversion tracking)
- `eMoney_dbo.eMoney_Panel_FirstDates` (card activation date — conversion tracking)
