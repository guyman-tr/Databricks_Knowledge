# BI_DB_dbo.BI_DB_Staking_Email_For_Marcin — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Crypto staking positions (InstrumentID 100017=ADA, 100026=TRX) | DateID = @LastDateID |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | FCA customers (RegulationID=2), IsCreditReportValidCB, TanganyStatusID filter | RealCID = pl.CID |
| 3 | DWH_dbo.Dim_Instrument | DWH_dbo | Instrument symbol name | InstrumentID join |
| 4 | DWH_dbo.Dim_Regulation | DWH_dbo | Regulation join (used but not directly outputted) | RegulationID join |
| 5 | DWH_dbo.Dim_Country | DWH_dbo | Country join (used for staking pool filter) | CountryID join |
| 6 | DWH_dbo.Dim_Language | DWH_dbo | Language join (exists but not directly outputted) | LanguageID join |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @Date | Direct |
| 2 | Num_of_CID | BI_DB_PositionPnL | CID | COUNT(DISTINCT), formatted as money string |
| 3 | Amount_IN_Units | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM, formatted as money string |
| 4 | NOP | BI_DB_PositionPnL | NOP | SUM WHERE IsSettled=1, formatted as money string |
| 5 | Amount_For_StakingPool | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM with country exclusions (US, UK post-2022-02-08), formatted |
| 6 | NOP_For_StakingPool | BI_DB_PositionPnL | NOP | SUM with same country exclusions, formatted |
| 7 | UpdateDate | ETL | GETDATE() | Metadata |
| 8 | InstrumentName | Dim_Instrument | Symbol | 'ADA', 'TRX', or 'Total' |
