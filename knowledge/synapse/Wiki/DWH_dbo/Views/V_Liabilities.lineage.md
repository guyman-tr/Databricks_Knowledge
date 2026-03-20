# Column Lineage — DWH_dbo.V_Liabilities

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| CID | Fact_SnapshotEquity.CID | Direct |
| DateID | V_M2M_Date_DateRange.DateKey | Aliased to DateID |
| FullDate | V_M2M_Date_DateRange.FullDate | Direct |
| ActualNWA | Computed | `MIN(TotalPos+TotalCash+StockOrders+PnL, BonusCredit)` with floor at 0 |
| Liabilities | Computed | `InProcessCashouts + MAX(NetEquity−BonusCredit, MIN(NetEquity, 0))` |
| WA_Liabilities | Computed | `MIN(Liabilities_excl_cashouts, Credit)` |
| Liabilities_InUsedMargin | Computed | `MAX(Liabilities_excl_cashouts − Credit, 0)` |
| TotalStockManualPosition | Computed | `TotalStockPositionAmount + TotalStockOrders − TotalMirrorStockPositionAmount` |
| ManualStockPositionPnL | Computed | `StocksPositionPnL − MirrorStocksPositionPnL` |
| TotalCryptoManualPosition | Computed | `TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount` |
| LiabilitiesStockReal | Computed | `PositionPnLStocksReal + TotalRealStocks` |
| LiabilitiesCryptoReal | Computed | `PositionPnLCryptoReal + TotalRealCrypto` |
| LiabilitiesCrypto_TRS | Computed | `CryptoPositionPnL_TRS + Total_TRSCrypto` |
| TotalCryptoManualPosition_TRS | Computed | `TotalCryptoPositionAmount_TRS − TotalMirrorCryptoPositionAmount_TRS` |
| LiabilitiesFuturesReal | Computed | `PositionPnLFuturesReal + TotalRealFutures` |
| Equity columns (~16) | Fact_SnapshotEquity | Direct passthrough |
| PnL columns (~20) | Fact_CustomerUnrealized_PnL | LEFT JOIN on CID + DateKey=DateModified |

## Join Path
```
Fact_SnapshotEquity.DateRangeID → V_M2M_Date_DateRange.DateRangeID
LEFT JOIN Fact_CustomerUnrealized_PnL ON CID + DateKey=DateModified
LEFT JOIN Fact_Guru_Copiers ON CID + DateKey=DateID (unused in SELECT)
WHERE DateKey < today
```
