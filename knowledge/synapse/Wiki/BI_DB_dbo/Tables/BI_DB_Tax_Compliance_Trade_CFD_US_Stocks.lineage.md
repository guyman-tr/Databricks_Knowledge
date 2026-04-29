# BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| DWH_dbo.Dim_Instrument | DWH_dbo | US stock filter (InstrumentTypeID IN 5,6, ISIN starts 'US') | fca.InstrumentID = di.InstrumentID |
| DWH_dbo.Dim_Customer | DWH_dbo | Valid depositor CIDs | dc.IsValidCustomer=1 AND dc.IsDepositor=1 |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name (used in temp, not stored) | dc.RegulationID = dr.DWHRegulationID |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Trading activity (ActionTypeID IN 1,2,3) | vd.CID = fca.RealCID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename; filtered to valid depositors who traded CFD US stocks but never REAL US stocks |
| UpdateDate | (ETL) | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
DWH_dbo.Dim_Customer (valid depositors)
  + DWH_dbo.Dim_Instrument (US stocks: InstrumentTypeID IN 5,6 AND ISINCode LIKE 'US%')
  + DWH_dbo.Fact_CustomerAction (trades: ActionTypeID IN 1,2,3)
  + DWH_dbo.Dim_Regulation (regulation name)
    |-- SP_Tax_Compliance_W8_AND_TIN @Date (CFD US Stocks section) --|
    |-- Logic: CFD traded (IsSettled=0) AND NOT real traded (IsSettled=1) --|
    v
  BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks (164K rows)
```
