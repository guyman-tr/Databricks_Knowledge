# BI_DB_dbo.BI_DB_AM_Contacted — Column Lineage

*Generated: 2026-04-21 | Phase 10B output — written BEFORE wiki*

## Source Objects

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_UsageTracking_SF | BI_DB Table | Salesforce action log — provides contact events (Phone_Call_Succeed__c, Completed_Contact_Email__c, Contacted__c) with CID and CreatedDate_SF |
| DWH_dbo.Dim_Customer | DWH Dimension | Customer master — provides RealCID, AccountManagerID, PlayerLevelID, CountryID, FirstDepositDate |
| DWH_dbo.Dim_Manager | DWH Dimension | Account manager master — provides ManagerID, FirstName, LastName, IsActive |
| DWH_dbo.Dim_Country | DWH Dimension | Country master — provides Region (marketing region) and Desk (sales desk) via JOIN on CountryID |
| DWH_dbo.Dim_PlayerLevel | DWH Dimension | Player level master — provides Name (Bronze/Silver/Gold/Platinum/Diamond) via JOIN on PlayerLevelID |
| DWH_dbo.V_Liabilities | DWH View | Customer liabilities view — provides RealizedEquity, Liabilities, ActualNWA; filtered to DateID = yesterday |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Renamed passthrough: `cid.RealCID AS CID` | Tier 1 — Customer.CustomerStatic |
| 2 | Last30DaysContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COMPUTED: `CASE WHEN sf.CID IS NULL THEN 0 ELSE 1 END`. sf = customers with ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') AND CreatedDate_SF within 30 days | Tier 2 — SP_AM_Contacted |
| 3 | Last30DaysPhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | COMPUTED: `CASE WHEN sf.PhoneCall = 1 THEN 1 ELSE 0 END`. PhoneCall=1 only for 'Phone_Call_Succeed__c'. DDM MASKED (default()). | Tier 2 — SP_AM_Contacted |
| 4 | Last60DaysContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COMPUTED: same as Last30DaysContacted but 60-day window | Tier 2 — SP_AM_Contacted |
| 5 | Last60DaysPhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | COMPUTED: same as Last30DaysPhoneContacted but 60-day window. DDM MASKED (default()). | Tier 2 — SP_AM_Contacted |
| 6 | Last30DaysContactedAttempt | BI_DB_dbo.BI_DB_UsageTracking_SF | CID, ActionName | COMPUTED: `CASE WHEN sf3.CID IS NULL THEN 0 ELSE 1 END`. sf3 = customers with ActionName IN ('Phone_Call_Succeed__c','Contacted__c') — includes failed phone attempts (Contacted__c) | Tier 2 — SP_AM_Contacted |
| 7 | ManagerID | DWH_dbo.Dim_Manager | ManagerID | Passthrough from Dim_Customer.AccountManagerID → Dim_Manager.ManagerID | Tier 2 — SP_AM_Contacted |
| 8 | Region | DWH_dbo.Dim_Country | Region | JOIN: Dim_Customer.CountryID → Dim_Country.Region (marketing region from etoro.Dictionary.MarketingRegion) | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| 9 | AccountManager | DWH_dbo.Dim_Manager | FirstName, LastName | COMPUTED: `Dim_Manager.FirstName + ' ' + Dim_Manager.LastName` | Tier 2 — SP_AM_Contacted |
| 10 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN: Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal | Tier 2 — SP_AM_Contacted |
| 11 | UpdateDate | ETL | N/A | CAST(GETDATE() AS DATE) — date of ETL run | Tier 2 — SP_AM_Contacted |
| 12 | Last30DaysPhoneContactedAttempt | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | COMPUTED: `CASE WHEN sf3.PhoneCallAttempt = 1 THEN 1 ELSE 0 END`. PhoneCallAttempt=1 for 'Phone_Call_Succeed__c' OR 'Contacted__c'. DDM MASKED (default()). | Tier 2 — SP_AM_Contacted |
| 13 | Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | COMPUTED: `V_Liabilities.Liabilities + V_Liabilities.ActualNWA`. Filtered to DateID = yesterday's YYYYMMDD int | Tier 2 — SP_AM_Contacted |
| 14 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough from V_Liabilities. Filtered to DateID = yesterday | Tier 2 — SP_AM_Contacted |
| 15 | Desk | DWH_dbo.Dim_Country | Desk | JOIN: Dim_Customer.CountryID → Dim_Country.Desk. Sales/support desk assignment | Tier 3 — Ext_Dim_Country_Region_Desk |

## ETL Pipeline Summary

```
eToro Salesforce (via BI_DB_UsageTracking_SF)
  ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c','Contacted__c')
  30-day / 60-day windows → 3 temp tables (#UsageTracking_SF1/#2/#3)

DWH_dbo.Dim_Customer  → AccountManagerID, RealCID, PlayerLevelID, CountryID
DWH_dbo.Dim_Manager   → ManagerID, FirstName+LastName (AccountManager), IsActive
DWH_dbo.Dim_Country   → Region, Desk
DWH_dbo.Dim_PlayerLevel → Name (Club: Bronze/Silver/Gold/Platinum/Diamond)
DWH_dbo.V_Liabilities  → Liabilities+ActualNWA (Equity), RealizedEquity [DateID=yesterday]
    |-- SP_AM_Contacted -----------------------------------|
    |   Schedule: Daily, SB_Daily, Priority 20            |
    |   Load: DELETE today + DELETE >120d + INSERT today  |
    v
BI_DB_dbo.BI_DB_AM_Contacted
  296.6M rows | 2.5M distinct CIDs
  Rolling 120-day daily snapshots (2025-12-14 to 2026-04-13)
  Contact rate (2026-04-13): 0.7% contacted in last 30 days
    |-- Not yet migrated to UC ---|
    v
UC Target: _Not_Migrated
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | CID |
| Tier 2 | 13 | Last30DaysContacted, Last30DaysPhoneContacted, Last60DaysContacted, Last60DaysPhoneContacted, Last30DaysContactedAttempt, ManagerID, Region, AccountManager, Club, UpdateDate, Last30DaysPhoneContactedAttempt, Equity, RealizedEquity |
| Tier 3 | 1 | Desk |
