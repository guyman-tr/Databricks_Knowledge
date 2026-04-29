# Column Lineage: BI_DB_dbo.BI_DB_PTM_Levy_Report

## Source Objects

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Dim_Position | Dimension | Position-level data: PositionID, CID, amounts, IsSettled, open/close dates |
| DWH_dbo.Dim_Instrument | Dimension | Instrument metadata: ISINCode, Exchange (LSE filter), InstrumentDisplayName, Symbol |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Fact | GBP/USD exchange rate (InstrumentID=2) for currency conversion |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough |
| InitialAmount_USD | DWH_dbo.Dim_Position | InitialAmountCents (opens) / Amount (closes) | Opens: InitialAmountCents/100; Closes: Amount passthrough |
| Bid | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | Passthrough (InstrumentID=2 = GBP/USD, matched on open/close DateID) |
| InitialAmount_GBP | ETL | — | Computed: InitialAmount_USD / Bid |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough (always 1, filtered in WHERE) |
| CID | DWH_dbo.Dim_Position | CID | Passthrough |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough (filtered GB/GG/JE/IM prefix) |
| TransactionType | ETL | — | Hardcoded: 'Open Position' or 'Close Position' |
| Date | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CAST to DATE |
| Instrument Name | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough (aliased) |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | Passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata date |
| Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Passthrough |
