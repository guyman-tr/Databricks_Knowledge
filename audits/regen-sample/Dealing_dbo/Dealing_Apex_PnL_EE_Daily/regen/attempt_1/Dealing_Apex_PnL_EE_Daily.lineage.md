# Lineage: Dealing_dbo.Dealing_Apex_PnL_EE_Daily

## Source Objects

| # | Source Object | Source Type | Schema | Relationship |
|---|--------------|-------------|--------|--------------|
| 1 | Dealing_staging.LP_APEX_EXT981_3EU | Staging table | Dealing_staging | Apex equity statement feed — provides TotalEquity for Equity_Start (prior day) and Equity_End (current day) |
| 2 | Dealing_staging.LP_APEX_EXT869_3EU | Staging table | Dealing_staging | Apex activity feed — provides Transfers (TerminalID IN CSCSG/FWWRD/MGLOA/MGJNL) and Dividends (TerminalID = $+DIV) |
| 3 | DWH_dbo.Dim_Date | Dimension | DWH_dbo | Calendar logic for bank holiday detection and weekend skipping |
| 4 | Dealing_dbo.SP_Apex_PnL | Stored Procedure | Dealing_dbo | Writer SP — DELETE+INSERT daily pattern |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform |
|---|--------------|---------------|---------------|-----------|
| 1 | Date | SP_Apex_PnL | @Date parameter | Passthrough — SP input parameter |
| 2 | AccountNumber | LP_APEX_EXT981_3EU / LP_APEX_EXT869_3EU | AccountNumber | ISNULL chain: ISNULL(ISNULL(equity.AccountNumber, transfers.AccountNumber), dividends.AccountNumber) |
| 3 | Equity_Start | Dealing_staging.LP_APEX_EXT981_3EU | TotalEquity | Scientific notation handling (CASE WHEN like '%e+%') then passthrough; uses @PreviousDayID (prior business day, skipping weekends) |
| 4 | Equity_End | Dealing_staging.LP_APEX_EXT981_3EU | TotalEquity | Scientific notation handling then passthrough; uses @DateID (current day, adjusted for bank holidays) |
| 5 | Transfers | Dealing_staging.LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL') for @DateID only (daily window) |
| 6 | PnL | — (computed) | — | ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0) |
| 7 | UpdateDate | — (computed) | — | GETDATE() — ETL execution timestamp |
| 8 | Dividends | Dealing_staging.LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID = '$+DIV' for @DateID only (daily window), aggregated per AccountNumber |
