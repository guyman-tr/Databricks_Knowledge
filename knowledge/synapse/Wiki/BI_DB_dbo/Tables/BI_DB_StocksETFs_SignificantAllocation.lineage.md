# BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| Dim_Position | DWH_dbo | Primary — open/close positions on yesterday for stock/ETF net money calculation |
| Dim_Instrument | DWH_dbo | Filter — InstrumentTypeID IN (5,6), Symbol for listing |
| Dim_Customer | DWH_dbo | Lookup — UserName, CountryID (→ Dim_Country), AccountManagerID (→ Dim_Manager) |
| V_Liabilities | DWH_dbo | Lookup — Credit (Balance), RealizedEquity on @YestardayDateID |
| Dim_Country | DWH_dbo | Lookup — Region (marketing region) |
| Dim_Manager | DWH_dbo | Lookup — FirstName, LastName for AM full name |
| BI_DB_UsageTracking_SF | BI_DB_dbo | Join — last contact date for Contacted/Not Contacted flag |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Position | CID | Passthrough (GROUP BY key from position aggregation) |
| UserName | DWH_dbo.Dim_Customer | UserName | Dim-lookup passthrough via RealCID |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup passthrough via Dim_Customer.CountryID |
| AddMoneyIn | DWH_dbo.Dim_Position | Amount | SUM(Amount) for positions opened on @YestardayDateID |
| AddMoneyOut | DWH_dbo.Dim_Position | Amount | -1 × SUM(Amount) for positions closed on @YestardayDateID |
| NetMoney | Computed | MoneyIn + MoneyOut | Sum of AddMoneyIn + AddMoneyOut |
| Balance | DWH_dbo.V_Liabilities | Credit | Passthrough (customer credit balance on @YestardayDateID) |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| Listing | DWH_dbo.Dim_Instrument | Symbol | STRING_AGG(Symbol, ',') — comma-separated list of traded instruments |
| ContactedLastMonth | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate | CASE: DATEDIFF > 30 days → 'Not Contacted', else 'Contacted' |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

## ETL Pipeline

```
DWH_dbo.Dim_Position (open/close on yesterday, stocks/ETFs, non-mirror, valid customers)
  + DWH_dbo.Dim_Instrument (Symbol, InstrumentTypeID filter)
  + DWH_dbo.Dim_Customer (UserName, CountryID, AccountManagerID)
  |-- #Pos: per CID×Symbol money in/out ---|
  |-- #String_POS: per CID aggregation + STRING_AGG(Symbol) ---|
  + BI_DB_dbo.BI_DB_UsageTracking_SF (last contact date per CID)
  |-- #Contact: MAX(CreatedDate) for email/phone contacts ---|
  + DWH_dbo.V_Liabilities (Balance, RealizedEquity on yesterday)
  + DWH_dbo.Dim_Country (Region)
  + DWH_dbo.Dim_Manager (FirstName, LastName)
  |-- SP_StocksETFs_SignificantAllocation ---|
  |  Filter: ABS(NetMoney) >= $10,000
  |  TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation (0 rows currently — snapshot, single-day)
```
