# BI_DB_dbo.BI_DB_NonPI_HighAUM — Column Lineage

## Writer SP

`BI_DB_dbo.SP_NonPI_HighAUM` (no parameters)
Changed: Ofir Chloe Gal (2023-01-16), Adi Ferber (2024-01-21 added TRUNCATE).

## Load Pattern

Daily TRUNCATE+INSERT (full refresh, no date parameter).

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | general.etoroGeneral_History_GuruCopiers | gc | Copy relationships (yesterday's snapshot) |
| 2 | DWH_dbo.Dim_Customer | par | Parent (copied) customer attributes |
| 3 | DWH_dbo.Dim_Manager | bm | Account manager name |
| 4 | DWH_dbo.Dim_PlayerStatus | dp | Player status name |
| 5 | DWH_dbo.Dim_Country | dc | Region |
| 6 | External_etoro_Customer_BlockedCustomerOperations | CBO | Block filter (OperationTypeID=2) |
| 7 | DWH_dbo.Dim_Position | tp | Open crypto positions with leverage>1 |
| 8 | DWH_dbo.Dim_Instrument | di | InstrumentTypeID=10 (crypto) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | Passthrough |
| 2 | UserName | Dim_Customer | UserName | Passthrough (parent user) |
| 3 | AUM | etoroGeneral_History_GuruCopiers | Cash+Investment+PnL | SUM(ISNULL(Cash,0)+ISNULL(Investment,0)+ISNULL(PnL,0)) |
| 4 | copiers | etoroGeneral_History_GuruCopiers | CID | COUNT(CID) per ParentCID |
| 5 | PlayerStatus | Dim_PlayerStatus | Name | JOIN lookup |
| 6 | AM | Dim_Manager | FirstName + ' ' + LastName | Concatenation via Dim_Customer.AccountManagerID |
| 7 | Region | Dim_Country | Region | JOIN via Dim_Customer.CountryID |
| 8 | HighLevCrypto | Dim_Position + Dim_Instrument | PositionID | COUNT of open crypto positions with Leverage>1 |
| 9 | BI_DB_NonPI_HighAUM | ETL | GETDATE() | ETL timestamp (same-name-as-table column) |
| 10 | UpdateDate | ETL | GETDATE() | ETL metadata |

## Production Source Chain

```
general.etoroGeneral_History_GuruCopiers (yesterday snapshot)
DWH_dbo.Dim_Customer + Dim_Manager + Dim_PlayerStatus + Dim_Country
DWH_dbo.Dim_Position + Dim_Instrument (crypto leverage)
  |-- SP_NonPI_HighAUM ---|
  v
BI_DB_dbo.BI_DB_NonPI_HighAUM (72 rows, AUM>15K non-PI)
  UC Target: _Not_Migrated
```
