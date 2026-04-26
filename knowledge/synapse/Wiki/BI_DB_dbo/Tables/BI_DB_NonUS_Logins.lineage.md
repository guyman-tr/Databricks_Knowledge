# BI_DB_dbo.BI_DB_NonUS_Logins — Column Lineage

## Writer SP

`BI_DB_dbo.SP_NonUS_Logins` (@date DATE)

## Load Pattern

Daily DELETE+INSERT by DateID = @DateINT.

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | DWH_dbo.Dim_Customer | dc | Population: non-US regulated depositors |
| 2 | BI_DB_dbo.BI_DB_CIDFirstDates | fd | LastLoggedIn filter (active on @date) |
| 3 | DWH_dbo.Fact_CustomerAction | fca | Login actions (ActionTypeID=14) |
| 4 | DWH_dbo.Dim_CountryIP | i | IP geolocation: CountryID=219 = US |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | RealCID | Dim_Customer | RealCID | Passthrough |
| 2 | DateID | Fact_CustomerAction | DateID | Passthrough (YYYYMMDD int) |
| 3 | USLogins | Fact_CustomerAction + Dim_CountryIP | IPNumber, CountryID | SUM(CASE WHEN CountryID=219 THEN TotalLogins ELSE 0 END) |
| 4 | NonUSLogin | Fact_CustomerAction + Dim_CountryIP | IPNumber, CountryID | SUM(CASE WHEN CountryID<>219 THEN TotalLogins ELSE 0 END) |
| 5 | UpdateDate | ETL | GETDATE() | ETL metadata |

## Production Source Chain

```
DWH_dbo.Dim_Customer (non-US regulated depositors)
BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn=@date)
DWH_dbo.Fact_CustomerAction (ActionTypeID=14, login events)
DWH_dbo.Dim_CountryIP (IP→Country geolocation)
  |-- SP_NonUS_Logins @date ---|
  v
BI_DB_dbo.BI_DB_NonUS_Logins (11.7M rows, only customers with USLogins>0)
  UC Target: _Not_Migrated
```
