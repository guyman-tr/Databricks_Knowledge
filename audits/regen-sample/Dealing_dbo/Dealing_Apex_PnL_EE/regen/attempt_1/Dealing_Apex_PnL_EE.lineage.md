# Lineage: Dealing_dbo.Dealing_Apex_PnL_EE

## Source Objects

| # | Source Object | Source Type | Schema | Relationship | Wiki Available |
|---|--------------|-------------|--------|-------------|----------------|
| 1 | LP_APEX_EXT981_3EU | Staging Table | Dealing_staging | Equity (TotalEquity) at week-start and week-end | No |
| 2 | LP_APEX_EXT869_3EU | Staging Table | Dealing_staging | Transfers (TerminalID IN CSCSG/FWWRD/MGLOA/MGJNL) and Dividends (TerminalID=$+DIV) | No |
| 3 | SP_Apex_PnL | Stored Procedure | Dealing_dbo | Writer SP — produces WTD equity-level PnL | N/A |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|--------------|-----------|------|
| 1 | Date | SP_Apex_PnL | @Date parameter | SET to @Date (the report date — Saturday WTD) | Tier 2 |
| 2 | AccountNumber | LP_APEX_EXT981_3EU / LP_APEX_EXT869_3EU | AccountNumber | COALESCE across #Equity, #Transfers, #Dividends_PerAcc | Tier 2 |
| 3 | Equity_Start | LP_APEX_EXT981_3EU | TotalEquity | TotalEquity at @FridayBeforeID (prior week Friday EOD); scientific notation parsed | Tier 2 |
| 4 | Equity_End | LP_APEX_EXT981_3EU | TotalEquity | TotalEquity at @DateID (current date EOD); scientific notation parsed | Tier 2 |
| 5 | Transfers | LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL') between Saturday-before and @Date | Tier 2 |
| 6 | PnL | SP_Apex_PnL | computed | ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0) | Tier 2 |
| 7 | UpdateDate | SP_Apex_PnL | GETDATE() | ETL load timestamp | Tier 2 |
| 8 | Dividends | LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID = '$+DIV' aggregated per AccountNumber for the WTD window | Tier 2 |

## ETL Pipeline

```
Apex Clearing LP external files
  |-- LP_APEX_EXT981_3EU (account equity snapshots)
  |-- LP_APEX_EXT869_3EU (cash activity: transfers, dividends, fees)
  v
Dealing_staging (Synapse staging tables)
  |-- SP_Apex_PnL @Date (DELETE + INSERT, WTD window: FridayBefore → @Date)
  |   |-- #EquityStart_ApexFiles (TotalEquity at FridayBefore)
  |   |-- #EquityEnd_ApexFiles (TotalEquity at @Date)
  |   |-- #Equity (FULL JOIN start/end)
  |   |-- #Transfers (SUM cash movements, TerminalID filter)
  |   |-- #Dividends_PerAcc (SUM dividends per account)
  v
Dealing_dbo.Dealing_Apex_PnL_EE (5,130 rows, stale since 2024-06-08)
```
