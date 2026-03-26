# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform — Column Lineage

> Source-to-target column mapping from `SP_DDR_Fact_MIMO_Options_Platform`.

## Sources

| Source | Type |
|--------|------|
| BI_DB_dbo.Function_MIMO_Options_Platform | TVF → External_Sodreconciliation_apex_EXT869_CashActivity, Dim_Customer, Fact_SnapshotCustomer |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | Function_MIMO_Options_Platform | DateID | passthrough | CONVERT(nvarchar(8), ProcessDate, 112) in function |
| Date | Function_MIMO_Options_Platform | Date | passthrough | CONVERT(date, ProcessDate) in function |
| RealCID | Function_MIMO_Options_Platform | RealCID | passthrough | Via Options GCID → Dim_Customer |
| MIMOAction | Function_MIMO_Options_Platform | MIMOAction | passthrough | CASE 'C'→Deposit, 'D'→Withdraw in function |
| OrigIdentifier | SP hardcoded | 'ApexTxID' | ETL-computed | Hardcoded string constant |
| TransactionID | Function_MIMO_Options_Platform | TransactionID | passthrough | ACATSControlNumber from Apex cash activity |
| AmountUSD | Function_MIMO_Options_Platform | AmountUSD | passthrough | ABS(Amount) with platform filters in function |
| AmountOrigCurrency | Function_MIMO_Options_Platform | AmountUSD | copy | Always USD — same as AmountUSD |
| FundingTypeID | SP hardcoded | 0 | ETL-computed | Options has no funding type concept |
| CurrencyID | SP hardcoded | 1 | ETL-computed | Always USD (CurrencyID=1) |
| Currency | SP hardcoded | 'USD' | ETL-computed | Options platform uses USD only |
| IsFTD | Function_MIMO_Options_Platform | IsFTD | passthrough | First-time deposit flag from function FTD logic |
| IsGlobalFTD | Function_MIMO_Options_Platform | IsGlobalFTD | passthrough | Global FTD across all platforms |
| IsInternalTransfer | Function_MIMO_Options_Platform | IsInternalTransfer | passthrough | CASE WHEN TerminalID='OMJNL' THEN 1 ELSE 0 |
| UpdateDate | SP | GETDATE() | ETL-computed | Load timestamp |
