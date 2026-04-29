# BI_DB_dbo.BI_DB_Unsettled_Trades_Risk — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| Dealing_staging.LP_BNY_Unsettled_Trades_UnsettledTrades | Staging Table | Primary — BNY Mellon unsettled trades report |
| DWH_dbo.Dim_Instrument | Table | Currency pair lookup for FX conversion |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | FX rates (Ask price) for USD conversion |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Client_Reference | LP_BNY_Unsettled_Trades | [Client Reference] | Rename (space to underscore) |
| Reference_Number | LP_BNY_Unsettled_Trades | [Reference Number] | Rename |
| Report_Run_Date | LP_BNY_Unsettled_Trades | [Report Run Date] | Rename |
| Contractual_Settle_Date | LP_BNY_Unsettled_Trades | [Contractual Settle Date] | Rename |
| Trade_Date | LP_BNY_Unsettled_Trades | [Trade Date] | Rename |
| Local_Currency | LP_BNY_Unsettled_Trades | [Local Currency Code] | Rename |
| Transaction_Name | LP_BNY_Unsettled_Trades | [Transaction Name] | Rename |
| Fail_Reason_Code | LP_BNY_Unsettled_Trades | [Fail Reason Code] | Rename |
| Shares_Par | LP_BNY_Unsettled_Trades | [Shares/Par] | Rename |
| Local_Net_Amount | LP_BNY_Unsettled_Trades | [Local Net Amount] | Rename |
| ISIN | LP_BNY_Unsettled_Trades | [ISIN] | Passthrough |
| Age_Days | Derived | Report_Run_Date, Contractual_Settle_Date | DATEDIFF(day, Report_Run_Date, Contractual_Settle_Date) |
| Amount_USD | Derived | Local_Net_Amount, Dim_Instrument, Fact_CurrencyPriceWithSplit | CASE: Ind=1 → amount/Ask, Ind=2 → amount*Ask, USD → amount*1, else → amount*1B (sentinel) |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

## Lineage Notes

- **FX conversion**: Amount_USD converts local currency amounts to USD using Dim_Instrument to identify currency pairs and Fact_CurrencyPriceWithSplit for the Ask rate on the trade date. Ind=1 means USD is buy currency (divide by Ask), Ind=2 means USD is sell currency (multiply by Ask). USD-denominated trades pass through unchanged. Non-supported currencies get a sentinel value (1B multiplier) to flag unconverted amounts.
- **Filtering**: Excludes SECURITY DEPOSIT, SECURITY WITHDRAWAL, CORPORATE ACTION transaction types. Only includes trades where Report_Run_Date > Contractual_Settle_Date (actually unsettled/failed).
- **Dedup**: Deletes existing records matching Reference_Number + Trade_Date before insert to handle reprocessing.
