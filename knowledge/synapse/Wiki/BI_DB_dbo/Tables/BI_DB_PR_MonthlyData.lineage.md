# BI_DB_dbo.BI_DB_PR_MonthlyData — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| BI_DB_CIDFirstDates | BI_DB_dbo | Primary source — CID, Country, BirthDate, Gender; filter FirstDepositDate > 2000 |
| Dim_Position | DWH_dbo | JOIN — PositionID, OpenDateID, OpenOccurred, Amount; filter MirrorID = 0, OpenDateID in month |
| Dim_Instrument | DWH_dbo | LEFT JOIN — InstrumentDisplayName, InstrumentType |
| Dim_Country | DWH_dbo | LEFT JOIN — Desk, Region (via Country name match) |
| Dim_Date | DWH_dbo | LEFT JOIN — DayName for open date |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | — | — | @Startofmonth parameter (first day of month) |
| CID | BI_DB_CIDFirstDates | CID | Passthrough |
| Instrument | Dim_Instrument | InstrumentDisplayName | Passthrough (renamed) |
| InstrumentType | Dim_Instrument | InstrumentType | Passthrough |
| Desk | Dim_Country | Desk | Passthrough via LEFT JOIN ON Country = Name |
| Region | Dim_Country | Region | Passthrough via LEFT JOIN ON Country = Name |
| Country | BI_DB_CIDFirstDates | Country | Passthrough |
| Age_Group | BI_DB_CIDFirstDates | BirthDate | CASE: FLOOR(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25) → 18-24/25-34/35-44/45-54/55+ |
| Gender | BI_DB_CIDFirstDates | Gender | CASE: M→Male, F→Female, else Male |
| PositionID | Dim_Position | PositionID | Passthrough |
| OpenDateID | Dim_Position | OpenDateID | Passthrough |
| OpenOccurred | Dim_Position | OpenOccurred | Passthrough |
| Open_Hour | Dim_Position | OpenOccurred | DATEPART(HOUR, OpenOccurred) |
| OpenDate_DayName | Dim_Date | DayName | Passthrough via LEFT JOIN ON OpenDateID = DateKey |
| Amount | Dim_Position | Amount | Passthrough |
| UpdateDate | — | — | GETDATE() at insert time |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (depositors, FirstDepositDate > 2000)
  |-- JOIN DWH_dbo.Dim_Position (MirrorID = 0, OpenDateID in month)
  |-- LEFT JOIN DWH_dbo.Dim_Date (DayName)
  |-- LEFT JOIN DWH_dbo.Dim_Instrument (DisplayName, InstrumentType)
  |-- LEFT JOIN DWH_dbo.Dim_Country (Desk, Region via Country = Name)
  |-- Compute: Age_Group (CASE on BirthDate), Gender (CASE), Open_Hour (DATEPART)
  |-- DELETE WHERE Date = @Startofmonth, then INSERT
  v
BI_DB_dbo.BI_DB_PR_MonthlyData (100.2M rows, accumulating monthly)
  |-- No UC mapping found
```
