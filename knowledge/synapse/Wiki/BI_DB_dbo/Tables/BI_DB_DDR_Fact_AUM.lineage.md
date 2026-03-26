# BI_DB_dbo.BI_DB_DDR_Fact_AUM — Column Lineage

> Source-to-target column mapping from `SP_DDR_Fact_AUM`.

## Sources

| Source | Type | Alias in SP |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table (BI_DB) | cb |
| DWH_dbo.V_Liabilities | View (DWH) | vl |
| eMoney_dbo.eMoneyClientBalance | Table (eMoney) | mcb |
| BI_DB_dbo.Function_AUM_OptionsPlatform | TVF (BI_DB) | ob |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| RealCID | Multi-source | cb.CID / i.CID / ob.RealCID | COALESCE | Full outer join merge key |
| DateID | SP parameter | @dateID | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | ETL-computed |
| Date | SP parameter | @date | passthrough | |
| RealizedEquityTP | BI_DB_Client_Balance_CID_Level_New | realizedEquity | SUM, rename | SUM per CID/DateID |
| TotalLiabilityTP | BI_DB_Client_Balance_CID_Level_New | TotalLiability | SUM, rename | SUM per CID/DateID |
| InProcessCashout | BI_DB_Client_Balance_CID_Level_New | InProcessCashout | SUM | |
| NOP | BI_DB_Client_Balance_CID_Level_New | NOP | SUM | Net Open Position |
| NOPCrypto | BI_DB_Client_Balance_CID_Level_New | NOPCrypto | SUM | |
| NOPCryptoCFD | BI_DB_Client_Balance_CID_Level_New | NOPCryptoCFD | SUM | |
| NOPStocks | BI_DB_Client_Balance_CID_Level_New | NOPStocks | SUM | |
| NOPStocksCFD | BI_DB_Client_Balance_CID_Level_New | NOPStocksCFD | SUM | |
| TotalRealCryptoLoan | BI_DB_Client_Balance_CID_Level_New | TotalRealCryptoLoan | SUM | |
| TotalPositionPNL | BI_DB_Client_Balance_CID_Level_New | PositionPNL | SUM, rename | Renamed from PositionPNL |
| TotalInvestedAmount | BI_DB_Client_Balance_CID_Level_New | PositionAmount | SUM, rename | Renamed from PositionAmount |
| TotalEquityTP | BI_DB_Client_Balance_CID_Level_New | TotalLiability + actualNWA | SUM(computed) | SUM(TotalLiability + actualNWA) |
| Bonus | BI_DB_Client_Balance_CID_Level_New | Bonus | SUM | |
| CashInCopy | DWH_dbo.V_Liabilities | TotalMirrorCash | passthrough | Via #vl temp table |
| CopyInvestedAmount | DWH_dbo.V_Liabilities | TotalMirrorPositionsAmount | passthrough | |
| CopyStockOrders | DWH_dbo.V_Liabilities | TotalMirrorStockOrders | passthrough | |
| CopyPositionPnL | DWH_dbo.V_Liabilities | CopyPositionPnL | passthrough | |
| EquityCopy | DWH_dbo.V_Liabilities | Computed | TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL | |
| InvestedAmountCopy | DWH_dbo.V_Liabilities | Computed | TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL | |
| StockInvestedAmount | DWH_dbo.V_Liabilities | TotalStockPositionAmount | passthrough | |
| StockOrders | DWH_dbo.V_Liabilities | TotalStockOrders | passthrough | |
| StocksPositionPnL | DWH_dbo.V_Liabilities | StocksPositionPnL | passthrough | |
| MirrorStockInvestedAmount | DWH_dbo.V_Liabilities | TotalMirrorStockPositionAmount | passthrough | |
| MirrorStocksPositionPnL | DWH_dbo.V_Liabilities | MirrorStocksPositionPnL | passthrough | |
| EquityStocksManual | DWH_dbo.V_Liabilities | Computed | TotalStockPositionAmount + TotalStockOrders + StocksPositionPnL - TotalMirrorStockPositionAmount - MirrorStocksPositionPnL | |
| InvestedAmountStocksManual | DWH_dbo.V_Liabilities | Computed | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | |
| InvestedAmountCryptoManual | DWH_dbo.V_Liabilities | TotalCryptoManualPosition | rename | Renamed from TotalCryptoManualPosition |
| CryptoManualPositionPnL | DWH_dbo.V_Liabilities | ManualCryptoPositionPnL | passthrough | |
| EquityCryptoManual | DWH_dbo.V_Liabilities | Computed | TotalCryptoManualPosition + ManualCryptoPositionPnL | |
| TotalRealCrypto | DWH_dbo.V_Liabilities | TotalRealCrypto | passthrough | |
| TotalRealStocks | DWH_dbo.V_Liabilities | TotalRealStocks | passthrough | |
| CreditTP | DWH_dbo.V_Liabilities | Credit | rename | Renamed from Credit |
| ActualNWA | DWH_dbo.V_Liabilities | ActualNWA | passthrough | V_Liabilities computed column |
| IBANBalance | eMoney_dbo.eMoneyClientBalance | ClosingBalanceBO * USDApproxRate | SUM(computed) | Non-core schema |
| RealizedEquityGlobal | Multi-source | realizedEquity + IBANBalance | ETL-computed | TP + IBAN (excl Options) |
| TotalLiabilityGlobal | Multi-source | TotalLiability + IBANBalance + OptionsTotalEquity | ETL-computed | TP + IBAN + Options |
| EquityGlobal | Multi-source | TotalEquity + IBANBalance + OptionsTotalEquity | ETL-computed | TP + IBAN + Options |
| CreditGlobal | Multi-source | CreditTP + IBANBalance + OptionsCashEquity | ETL-computed | TP + IBAN + Options cash |
| UpdateDate | SP | GETDATE() | ETL-computed | Load timestamp |
| OptionsTotalEquity | Function_AUM_OptionsPlatform | OptionsTotalEquity | passthrough | From Apex buy-power summary |
