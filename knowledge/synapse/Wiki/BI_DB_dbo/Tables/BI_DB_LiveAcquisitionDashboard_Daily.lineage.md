# Lineage: BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily

**Writer SP**: `BI_DB_dbo.SP_LiveAcquisitionDashboard_Daily` (author: Amir Gurewitz, 2021-03-17)  
**Load Pattern**: Rolling 90-day window (DELETE WHERE Date <= @date + INSERT last 90 days from Dim_Customer)  
**Primary Source**: `DWH_dbo.Dim_Customer` (registration and FTD events for @3M to @date-1)  
**Secondary Sources**: `DWH_dbo.Dim_Affiliate`, `DWH_dbo.Dim_Channel`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Funnel`, `DWH_dbo.Dim_State_and_Province`

**Data Coverage**: Rolling 90 days. Two rows per valid customer: one for 'Registration' (on RegisteredReal date) and one for 'FTDs' (on FirstDepositDate) — but only for customers who had each event in the 90-day window. `IsValidCustomer=1` filter.

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | JOIN on AffiliateID → affiliate group/network name | Tier 2 |
| 2 | Contact | DWH_dbo.Dim_Affiliate | Contact | JOIN on AffiliateID → affiliate contact identifier/campaign tag | Tier 2 |
| 3 | Channel | DWH_dbo.Dim_Channel | Channel | JOIN on SubChannelID → marketing acquisition channel (SEM, Direct, Affiliate, etc.) | Tier 2 |
| 4 | SubChannel | DWH_dbo.Dim_Channel | SubChannel | JOIN on SubChannelID → marketing sub-channel detail | Tier 2 |
| 5 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough — platform customer ID (Customer.CustomerStatic.CID) | Tier 2 |
| 6 | Date | DWH_dbo.Dim_Customer | FirstDepositDate (KPI='FTDs') / RegisteredReal (KPI='Registration') | Conditional: FTD event date for FTDs rows; real account registration date for Registration rows | Tier 2 |
| 7 | Region | DWH_dbo.Dim_Country | MarketingRegionManualName | JOIN on CountryID → marketing region name (UK, Spain, French, Italian, CEE, etc.) | Tier 2 |
| 8 | Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID → full country name in English | Tier 1 |
| 9 | KPI | SP_LiveAcquisitionDashboard_Daily | Hardcoded | 'FTDs' for deposit-event rows, 'Registration' for registration-event rows | Tier 2 |
| 10 | FTDA | DWH_dbo.Dim_Customer | FirstDepositAmount | First deposit amount in USD; NULL for Registration rows | Tier 2 |
| 11 | SerialID | DWH_dbo.Dim_Customer | AffiliateID | Affiliate ID — acquisition affiliate/partner (FK to Dim_Affiliate) | Tier 2 |
| 12 | SubSerialID | DWH_dbo.Dim_Customer | SubSerialID | Sub-affiliate identifier string for affiliate sub-tracking | Tier 2 |
| 13 | DownloadID | DWH_dbo.Dim_Customer | DownloadID | Download/install tracking ID for app-based attribution | Tier 2 |
| 14 | FunnelName | DWH_dbo.Dim_Funnel | Name | JOIN on FunnelID → name of the acquisition funnel the customer entered | Tier 2 |
| 15 | FunnelFromName | DWH_dbo.Dim_Funnel | Name | JOIN on FunnelFromID → name of the source funnel (referral funnel) | Tier 2 |
| 16 | State | DWH_dbo.Dim_State_and_Province | Name | JOIN on RegionID → state/province name derived from customer IP at registration | Tier 2 |
| 17 | UpdateDate | ETL | GETDATE() | Batch timestamp | Tier 3 |

## ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1, last 90 days)
  UNION ALL: FTD events (FirstDepositDate in [t-90, t)) + Registration events (RegisteredReal in [t-90, t))
  + LEFT JOIN Dim_Funnel (FunnelID → FunnelName; FunnelFromID → FunnelFromName)
  + JOIN Dim_Country (CountryID → Country, Region)
  + LEFT JOIN Dim_State_and_Province (RegionID → State)
  + JOIN Dim_Channel (SubChannelID → Channel, SubChannel)
  + JOIN Dim_Affiliate (AffiliateID → AffiliatesGroupsName, Contact)
         |-- SP_LiveAcquisitionDashboard_Daily @date ---|
         v
BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily (~1.47M rows, rolling 90 days)
  |-- (No UC target — Not Migrated) ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | Country |
| Tier 2 | 15 | AffiliatesGroupsName, Contact, Channel, SubChannel, CID, Date, Region, KPI, FTDA, SerialID, SubSerialID, DownloadID, FunnelName, FunnelFromName, State |
| Tier 3 | 1 | UpdateDate |
| Tier 4 | 0 | — |
