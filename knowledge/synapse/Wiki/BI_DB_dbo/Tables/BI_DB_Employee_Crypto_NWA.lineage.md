# BI_DB_dbo.BI_DB_Employee_Crypto_NWA — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Employee_Crypto_NWA`

## Source Objects
- `DWH_dbo.Fact_SnapshotCustomer` — employee account identification (PlayerLevelID=4, AccountTypeID IN 7,13)
- `DWH_dbo.V_Liabilities` — balance and crypto position amounts (Liabilities, TotalCryptoPositionAmount)
- `DWH_dbo.Dim_Date` — EOM filtering (IsLastDayOfMonth='Y')
- `DWH_dbo.Dim_Range` — date range resolution for Fact_SnapshotCustomer
- `BI_DB_dbo.BI_DB_PositionPnL` — open position units by instrument (AmountInUnitsDecimal)
- `DWH_dbo.Dim_Instrument` — instrument names and type (InstrumentTypeID=10 for crypto)
- `BI_DB_dbo.BI_DB_Crypto_NOP` — EOD bid price per instrument

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | V_Liabilities | FullDate | Direct (EOM dates only) |
| Instrument | Dim_Instrument | Name | Direct (crypto only, InstrumentTypeID=10) |
| Units | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM per instrument across all employee accounts |
| Rate | BI_DB_Crypto_NOP | EOD_Bid_Price | MAX(EOD_Bid_Price) per instrument per date |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
