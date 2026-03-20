# Column Lineage — DWH_dbo.V_Fact_SnapshotEquity_ForDWHRep

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| CID..Total_TRSCrypto | Fact_SnapshotEquity | Direct passthrough (26 of 32 columns) |
| PartitionCol | Computed | `CAST(CID % 10 AS INT)` |

## Excluded from base: TotalFuturesLockedCash, TotalMirrorRealFuturesPositionAmount, TotalRealFutures, TotalFuturesProviderMargin, TotalStocksMargin, TotalStockMarginLoanValue
