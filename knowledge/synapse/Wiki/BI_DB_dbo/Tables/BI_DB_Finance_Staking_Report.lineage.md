# BI_DB_dbo.BI_DB_Finance_Staking_Report — Column Lineage

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | DWH_dbo.Dim_Position | Table | AirDrop positions (InstrumentID IN (100017, 100026), IsAirDrop=1) |
| 2 | DWH_dbo.Dim_Customer | Table | Customer → Regulation mapping (CID → RealCID → RegulationID) |
| 3 | DWH_dbo.Dim_Regulation | Table | RegulationID → Name |
| 4 | BI_DB_dbo.BI_DB_Staking_Platform_Compensations | Table | Staking compensation payments (CID, CreditDate, Payment) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|---------------|-------------|---------------|-----------|
| 1 | type | Computed | — | 'AirDrop' for airdrop positions, 'Compensations' for staking compensation payments |
| 2 | Regulation_Name | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.RegulationID → Dim_Regulation.DWHRegulationID |
| 3 | StakingMonth | Computed | OpenOccurred / CreditDate | CONCAT(LEFT(DATENAME(MONTH, EOMONTH(DATEADD(MONTH,-1,date))), 3), '-', LEFT(EOMONTH(DATEADD(MONTH,-1,date)), 4)) — e.g., 'Mar-2026' |
| 4 | StakingMonthID | Computed | OpenOccurred / CreditDate | LEFT(CAST(CONVERT(CHAR(8), EOMONTH(DATEADD(MONTH,-1,date)), 112) AS INT), 6) — e.g., '202603' |
| 5 | Total_Dollars | Dim_Position / BI_DB_Staking_Platform_Compensations | Amount / Payment | SUM(Amount) for AirDrop, SUM(Payment) for Compensations |
| 6 | UpdateDate | ETL | GETDATE() | ETL timestamp |

## ETL Pipeline

```
DWH_dbo.Dim_Position (WHERE InstrumentID IN (100017, 100026) AND IsAirDrop=1)
  + DWH_dbo.Dim_Customer (CID → RealCID)
  + DWH_dbo.Dim_Regulation (RegulationID → Name)
    → #Temp_AirDrop (SUM(Amount) GROUP BY Regulation, StakingMonth)

BI_DB_dbo.BI_DB_Staking_Platform_Compensations (CreditDate within 2-month window)
  + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Regulation
    → #Temp_Compensations (SUM(Payment) GROUP BY Regulation, StakingMonth)

#Temp_AirDrop UNION ALL #Temp_Compensations
  |-- SP_Finance_Staking_Report @Date (DELETE matching StakingMonth + INSERT, SB_Daily P0) ---|
  v
BI_DB_dbo.BI_DB_Finance_Staking_Report (~500 rows, monthly aggregates)
```

*Generated: 2026-04-26*
