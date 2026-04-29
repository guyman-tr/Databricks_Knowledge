# BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| etoro_History_Position_10DaysRange_SuspiciousActivityTrading | BI_DB_dbo | Primary — 10-day closed position range (created by SP_Create_etoro_History_Position_Range) |
| Dim_Customer | DWH_dbo | Lookup — UserName, RegulationID, PlayerLevelID, FirstDepositDate, CountryID, PlayerStatusID |
| External_etoro_BackOffice_Customer | BI_DB_dbo | Filter — AccountTypeID <> 9 |
| Dim_Instrument | DWH_dbo | Filter — InstrumentType='Stocks', InstrumentDisplayName |
| Dim_Mirror | DWH_dbo | Lookup — active copier count for PI status |
| Dim_Regulation | DWH_dbo | Lookup — regulation name |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RootCID | History positions | CID (of TreeID root) | The parent position owner (copy-trade tree root) |
| CID | History positions | CID | Position owner (may differ from RootCID in copy trees) |
| UserName | DWH_dbo.Dim_Customer | UserName | Dim-lookup via RootCID |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via Dim_Customer.RegulationID |
| IsCopy | History positions | MirrorID | CASE: MirrorID > 0 → 'Copy', else 'Manual' |
| IsPI | DWH_dbo.Dim_Mirror | COUNT(MirrorID) | CASE: active copiers > 10 → 1, else 0 |
| Is3Month | DWH_dbo.Dim_Customer | FirstDepositDate | CASE: deposit < 3 months ago → 1, else 0 |
| NumOfTrades | History positions | COUNT(*) | Count of qualifying trades per group |
| NetProfit | History positions | SUM(NetProfit) | Sum of P&L per group |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup (NULL / 'Not Relevant' for group A) |
| Group_Type | SP-computed | — | Literal: 3 detection group labels |
| StartRunningDate | SP parameter | GETDATE() | Date of SP execution |
| StartRunningTime | SP parameter | GETDATE() | Datetime of SP execution |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

## ETL Pipeline

```
etoro.History.Position (10-day range via SP_Create_etoro_History_Position_Range)
  + DWH_dbo.Dim_Customer (filters: PlayerLevelID<>4, LabelID<>30, CountryID<>250, PlayerStatusID<>9)
  + BI_DB_dbo.External_etoro_BackOffice_Customer (AccountTypeID<>9)
  + DWH_dbo.Dim_Instrument (InstrumentType='Stocks')
  + DWH_dbo.Dim_Mirror (active copier count for PI flag)
  + DWH_dbo.Dim_Regulation (Name)
  |-- SP_SuspiciousActivityTrading_Investing ---|
  |  Group A: +5 trades <3 min/day (root opens+closes within 3 min)
  |  Group B: +5 trades same instrument/day (opened+closed same day)
  |  Group C: +30 trades same instrument/10 days
  |  UNION ALL → #Final → DELETE ALL + INSERT
  v
BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing (264 rows, single-day snapshot)
```
