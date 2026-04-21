# eMoney_dbo.eMoney_AM_Target — Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | Report_Date | SP_eMoney_AM_Target | @ReportDate (loop var) | Loop date variable (current day in while loop) | 2 |
| 2 | Report_Date_ID | SP_eMoney_AM_Target | @ReportDate | CAST(CONVERT(VARCHAR(8), @ReportDate, 112) AS INT) → YYYYMMDD int | 2 |
| 3 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | 1 |
| 4 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough rename | 1 |
| 5 | Country | DWH_dbo.Dim_Country | Name | Passthrough (Dim_Country.Name AS Country) | 2 |
| 6 | Region | eMoney_dbo.eMoney_Dim_Country_Rollout | Region | Passthrough | 2 |
| 7 | Euro_Non_Euro | SP_eMoney_AM_Target | Dim_Customer.CountryID | CASE WHEN CountryID IN (154,196,72,57,95) → 'Non_Euro'; CountryID=218 → 'GBP'; else → 'Euro' | 2 |
| 8 | Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough (Dim_PlayerLevel.Name AS Club) | 2 |
| 9 | Account_Manager | DWH_dbo.Dim_Manager | FirstName, LastName | Dim_Manager.FirstName + ' ' + Dim_Manager.LastName | 2 |
| 10 | Account_Manager_ID | DWH_dbo.Dim_Customer | AccountManagerID | Passthrough (Dim_Customer.AccountManagerID AS Account_Manager_ID) | 2 |
| 11 | Attemp_Last_Date | SP_eMoney_AM_Target | Hardcoded | Hardcoded '1900-01-01' — contact attempt tracking disabled (code commented out) | 2 |
| 12 | Contacted_Last_Date | SP_eMoney_AM_Target | Hardcoded | Hardcoded '1900-01-01' — contact success tracking disabled (code commented out) | 2 |
| 13 | Value_TotalActions | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7, DateID in current period window | 2 |
| 14 | Value_eMoneyActions | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 AND FundingTypeID=33, current period | 2 |
| 15 | Value_OtherActions | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 AND FundingTypeID<>33, current period | 2 |
| 16 | CNT_TotalActions | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) WHERE ActionTypeID=7, current period (2023-10-01 to ReportDate) | 2 |
| 17 | CNT_eMoneyActions | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) WHERE ActionTypeID=7 AND FundingTypeID=33, current period | 2 |
| 18 | CNT_OtherActions | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) WHERE ActionTypeID=7 AND FundingTypeID<>33, current period | 2 |
| 19 | Value_TotalActions_Targets | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7, targets period (2023-07-01 to 2023-10-01) | 2 |
| 20 | Value_eMoneyActions_Targets | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE FundingTypeID=33, targets period | 2 |
| 21 | Value_OtherActions_Targets | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE FundingTypeID<>33, targets period | 2 |
| 22 | CNT_TotalActions_Targets | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) WHERE ActionTypeID=7, targets period | 2 |
| 23 | CNT_eMoneyActions_Targets | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) FundingTypeID=33, targets period | 2 |
| 24 | CNT_OtherActions_Targets | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) FundingTypeID<>33, targets period | 2 |
| 25 | Value_TotalActions_Daily | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7, DateID=ReportDate only | 2 |
| 26 | Value_eMoneyActions_Daily | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) FundingTypeID=33, daily | 2 |
| 27 | Value_OtherActions_Daily | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) FundingTypeID<>33, daily | 2 |
| 28 | CNT_TotalActions_Daily | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) WHERE ActionTypeID=7, DateID=ReportDate only | 2 |
| 29 | CNT_eMoneyActions_Daily | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) FundingTypeID=33, daily | 2 |
| 30 | CNT_OtherActions_Daily | DWH_dbo.Fact_CustomerAction | HistoryID | COUNT(*) FundingTypeID<>33, daily | 2 |
| 31 | UpdateDate | SP_eMoney_AM_Target | GETDATE() | ETL load timestamp | 2 |

## ETL Chain Summary

```
DWH_dbo.Dim_Customer + Dim_Country + Dim_PlayerLevel + Dim_Manager
  + eMoney_dbo.eMoney_Dim_Country_Rollout
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=7, FundingTypeID=33 for eMoney)
    |-- SP_eMoney_AM_Target (daily while-loop: DELETE+INSERT per date) ---|
    v
eMoney_dbo.eMoney_AM_Target (385M rows, 2023-07-01 to 2026-04-11)
  |-- UC Gold (no UC mapping known) ---|
```

## Source Objects

- `DWH_dbo.Dim_Customer` (GCID, RealCID→CID, AccountManagerID, eligibility filters)
- `DWH_dbo.Dim_Country` (Country name)
- `DWH_dbo.Dim_PlayerLevel` (Club name)
- `DWH_dbo.Dim_Manager` (Account_Manager full name)
- `eMoney_dbo.eMoney_Dim_Country_Rollout` (Region)
- `DWH_dbo.Fact_CustomerAction` (MIMO amounts and counts, ActionTypeID=7)
