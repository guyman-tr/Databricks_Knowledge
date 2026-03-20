# DWH_dbo.Fact_RegulationTransfer — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | etoro (BackOffice) |
| **Production Table** | History.BackOfficeCustomer (SCD2) |
| **Staging** | DWH_staging.etoro_History_BackOfficeCustomer |
| **Intermediate** | Ext_FRT_BackOffice_RegulationChangeLog, _All |
| **Equity Source** | V_Liabilities (day before transfer) |
| **ETL SPs** | SP_Fact_RegulationTransfer_DL_To_Synapse → SP_Fact_RegulationTransfer |

## Column Lineage

| # | DWH Column | Source | Transform | Notes |
|---|-----------|--------|-----------|-------|
| 1 | FromRegulationID | History.BackOfficeCustomer | Previous row's RegulationID | SCD2 change detection |
| 2 | ToRegulationID | History.BackOfficeCustomer | Current row's RegulationID | SCD2 change detection |
| 3 | Occurred | History.BackOfficeCustomer | MAX(ValidFrom) for CID on date | Transfer timestamp |
| 4 | DateID | Computed | CONVERT(INT, CONVERT(VARCHAR, Occurred, 112)) | YYYYMMDD |
| 5 | UnrealizedPnL | V_Liabilities | PositionPnL | Day before transfer |
| 6 | ActualNWA | V_Liabilities | ActualNWA | ISNULL → 0 |
| 7 | RealizedEquity | V_Liabilities | RealizedEquity | ISNULL → 0 |
| 8 | UpdateDate | Computed | GETDATE() | ETL timestamp |
| 9 | CID | History.BackOfficeCustomer | CID | Customer ID |
| 10-22 | Financial columns | V_Liabilities | Various | ISNULL → 0, day before |
| 23 | InvestedRealStocks | Computed | PnLStocksReal + TotalRealStocks | |
| 24 | InvestedRealCrypto | Computed | PnLCryptoReal + TotalRealCrypto | |
| 25-26 | PnL Stocks/Crypto | V_Liabilities | Direct | ISNULL → 0 |
| 27-28 | Futures columns | V_Liabilities + Computed | Added 2024-11 | |
| 29-31 | Stock Margin columns | V_Liabilities + Computed | Added 2025-10 | |
