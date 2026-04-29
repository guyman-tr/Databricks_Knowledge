# BI_DB_dbo.BI_DB_UsersEngagement — Column Lineage

## Source Objects

| Source Object | Schema | Role | Confidence |
|--------------|--------|------|------------|
| BI_DB_Social_Activity | BI_DB_dbo | Primary source — social feed actions (posts, comments, likes, shares) | Tier 2 — SP code |
| BI_DB_Social_Activity_Type | BI_DB_dbo | Lookup — ActionName for action type classification | Tier 2 — SP code |
| Dim_Customer | DWH_dbo | Lookup — RealCID, UserName for customer identity | Tier 1 — Customer.CustomerStatic wiki |
| Dim_Country | DWH_dbo | Lookup — Country name and marketing Region | Tier 1 — Dictionary.Country wiki |
| BI_DB_CIDFirstDates | BI_DB_dbo | Lookup — Channel, Blocked status, FirstDepositDate | Tier 2 — local wiki |
| BI_DB_CID_MonthlyPanel_FullData | BI_DB_dbo | Lookup — Active (trader) and ActiveUser flags by month | Tier 2 — local wiki |
| Fact_CustomerAction | DWH_dbo | Post-INSERT UPDATE — LastCODate and LastCOAmount (ActionTypeID=8 cashouts) | Tier 2 — SP code |
| Dim_Date | DWH_dbo | JOIN — CalendarYearMonth for monthly panel alignment | Tier 2 — SP code |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| DateCreated | — | — | ETL metadata: CAST(GETDATE() AS DATE) | Tier 5 |
| ActionID | BI_DB_Social_Activity | ActionID | Passthrough | Tier 2 |
| ActionType | BI_DB_Social_Activity_Type | ActionName | Dim-lookup via ActionTypeID (rename ActionName → ActionType) | Tier 2 |
| ActionDate | BI_DB_Social_Activity | ActionDate | Passthrough | Tier 2 |
| RealCID | DWH_dbo.Dim_Customer | RealCID | Dim-lookup passthrough via JOIN on RealCID | Tier 1 |
| UserName | DWH_dbo.Dim_Customer | UserName | Dim-lookup passthrough | Tier 1 |
| MessageText | BI_DB_Social_Activity | MessageText | Passthrough | Tier 2 |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via CountryID (rename Name → Country) | Tier 1 |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup passthrough | Tier 2 |
| Channel | BI_DB_CIDFirstDates | Channel | Passthrough from CIDFirstDates | Tier 2 |
| Blocked | BI_DB_CIDFirstDates | Blocked | Passthrough from CIDFirstDates | Tier 2 |
| FirstDepositDate | BI_DB_CIDFirstDates | FirstDepositDate | Passthrough from CIDFirstDates | Tier 2 |
| TotalDeposit | — | — | Hardcoded NULL (was from BI_DB_User_Segment, now disabled) | Tier 2 |
| LT_Engagement | BI_DB_Social_Activity + BI_DB_UsersEngagement | ActionID | Initially 0, then UPDATE: COUNT(DISTINCT ActionID) across all historical actions for the CID | Tier 2 |
| LastCODate | DWH_dbo.Fact_CustomerAction | DateID | Initially '1990-01-01', then UPDATE: MAX(DateID) WHERE ActionTypeID=8, converted to datetime | Tier 2 |
| LastCOAmount | DWH_dbo.Fact_CustomerAction | Amount | Initially 0, then UPDATE: Amount at LastCODate WHERE ActionTypeID=8 | Tier 2 |
| UpdateDate | — | — | ETL metadata: GETDATE() | Tier 5 |
| ActiveTrader | BI_DB_CID_MonthlyPanel_FullData | Active | ISNULL(Active, 0). 1 if customer closed ≥1 position in the action's month. | Tier 2 |
| ActiveUser | BI_DB_CID_MonthlyPanel_FullData | ActiveUser | ISNULL(ActiveUser, 0). 1 if EOM_Equity > 0 in the action's month. | Tier 2 |
| ActionDateID | BI_DB_Social_Activity | ActionDateID | Passthrough. YYYYMMDD integer. Clustered index key. | Tier 2 |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Social_Activity (social feed actions)
  + BI_DB_Social_Activity_Type (action type lookup)
  + DWH_dbo.Dim_Customer (customer identity)
  + DWH_dbo.Dim_Country (country/region lookup)
  + BI_DB_CIDFirstDates (channel, blocked, deposit date)
  + DWH_dbo.Dim_Date (month alignment)
  + BI_DB_CID_MonthlyPanel_FullData (active trader/user flags)
  |
  |-- SP_UsersEngagement @date ---|
  |-- DELETE WHERE ActionDateID=@YesterdayDateID + INSERT ---|
  |-- UPDATE LastCODate/LastCOAmount from Fact_CustomerAction (ActionTypeID=8) ---|
  |-- UPDATE LT_Engagement from COUNT(DISTINCT ActionID) ---|
  |-- DELETE WHERE ActionDateID < 2 years ago (rolling window) ---|
  v
BI_DB_dbo.BI_DB_UsersEngagement (~490K rows, rolling 2-year window)
```
