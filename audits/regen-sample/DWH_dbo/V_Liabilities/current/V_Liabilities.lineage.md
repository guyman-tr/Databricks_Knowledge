# V_Liabilities — Column Lineage

## Source → View Column Mapping

### From Fact_SnapshotEquity (alias `a`)

| View Column | FSE Column | Notes |
|-------------|-----------|-------|
| CID | CID | PK component |
| RealizedEquity | RealizedEquity | |
| TotalPositionsAmount | TotalPositionsAmount | Used in NetEquity formula |
| TotalCash | TotalCash | Used in NetEquity formula |
| InProcessCashouts | InProcessCashouts | Added to Liabilities |
| TotalMirrorPositionsAmount | TotalMirrorPositionsAmount | |
| TotalMirrorCash | TotalMirrorCash | |
| TotalStockOrders | TotalStockOrders | Legacy — always 0. In NetEquity formula. |
| TotalMirrorStockOrders | TotalMirrorStockOrders | Legacy — always 0 |
| Credit | Credit | Used in WA_Liabilities cap |
| AUM | AUM | |
| BonusCredit | BonusCredit | Used in ActualNWA/Liabilities CASE |
| TotalStockPositionAmount | TotalStockPositionAmount | |
| TotalMirrorStockPositionAmount | TotalMirrorStockPositionAmount | |
| TotalCryptoPositionAmount | TotalCryptoPositionAmount | |
| TotalRealStocks | TotalRealStocks | |
| TotalRealCrypto | TotalRealCrypto | |
| Total_TRSCrypto | Total_TRSCrypto | |
| TotalCryptoPositionAmount_TRS | TotalCryptoPositionAmount_TRS | |
| TotalMirrorRealFuturesPositionAmount | TotalMirrorRealFuturesPositionAmount | |
| TotalRealFutures | TotalRealFutures | |
| TotalFuturesProviderMargin | TotalFuturesProviderMargin | |
| TotalStocksMargin | TotalStocksMargin | |
| TotalStockMarginLoanValue | TotalStockMarginLoanValue | |
| CopyFundAUM | CopyFundAUM | |

### From V_M2M_Date_DateRange (alias `b`)

| View Column | Source Column | Notes |
|-------------|-------------|-------|
| DateID | DateKey | Renamed via AS |
| FullDate | FullDate | |

### From Fact_CustomerUnrealized_PnL (alias `c`)

| View Column | FCUPNL Column | Notes |
|-------------|-------------|-------|
| PositionPnL | PositionPnL | Used in NetEquity formula |
| CopyPositionPnL | CopyPositionPnL | |
| StandardDeviation | StandardDeviation | Portfolio risk |
| CommissionOnOpen | CommissionOnOpen | |
| StocksPositionPnL | StocksPositionPnL | |
| MirrorStocksPositionPnL | MirrorStocksPositionPnL | |
| CryptoPositionPnL | CryptoPositionPnL | |
| ManualCryptoPositionPnL | ManualCryptoPositionPnL | |
| CopyCryptoPositionPnL | CopyCryptoPositionPnL | |
| CopyFundPnL | CopyFundPnL | |
| NOP | NOP | |
| Notional | Notional | |
| NOP_Crypto | NOP_Crypto | |
| Notional_Crypto | Notional_Crypto | |
| NOP_CFD | NOP_CFD | |
| Notional_CFD | Notional_CFD | |
| NOP_Crypto_CFD | NOP_Crypto_CFD | |
| Notional_Crypto_CFD | Notional_Crypto_CFD | |
| PositionPnLStocksReal | PositionPnLStocksReal | |
| PositionPnLCryptoReal | PositionPnLCryptoReal | |
| CommissionByUnitsCrypto_TRS | CommissionByUnitsCrypto_TRS | |
| CopyCryptoPositionPnL_TRS | CopyCryptoPositionPnL_TRS | |
| CryptoPositionPnL_TRS | CryptoPositionPnL_TRS | |
| FullCommissionByUnitsCrypto_TRS | FullCommissionByUnitsCrypto_TRS | |
| ManualCryptoPositionPnL_TRS | ManualCryptoPositionPnL_TRS | |
| NOP_Crypto_TRS | NOP_Crypto_TRS | |
| Notional_Crypto_TRS | Notional_Crypto_TRS | |
| MirrorRealFuturesPositionPnL | MirrorRealFuturesPositionPnL | |
| ManualRealFuturesPositionPnL | ManualRealFuturesPositionPnL | |
| NOP_FuturesReal | NOP_FuturesReal | |
| Notional_FuturesReal | Notional_FuturesReal | |
| PositionPnLFuturesReal | PositionPnLFuturesReal | |
| FullCommissionByUnitsFuturesReal | FullCommissionByUnitsFuturesReal | |
| CommissionByUnitsFuturesReal | CommissionByUnitsFuturesReal | |
| NOP_StocksMargin | NOP_StocksMargin | |
| PositionPnLStocksMargin | PositionPnLStocksMargin | |

### Computed Columns (T2)

| View Column | Sources | Formula |
|-------------|---------|---------|
| ActualNWA | FSE + FCUPNL | CASE on NetEquity vs BonusCredit |
| Liabilities | FSE + FCUPNL | InProcessCashouts + CASE on NetEquity - BonusCredit |
| WA_Liabilities | FSE + FCUPNL | MIN(Liabilities_excl_cashouts, Credit) |
| Liabilities_InUsedMargin | FSE + FCUPNL | MAX(Liabilities_excl_cashouts - Credit, 0) |
| TotalStockManualPosition | FSE | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount |
| ManualStockPositionPnL | FCUPNL | StocksPositionPnL - MirrorStocksPositionPnL |
| TotalCryptoManualPosition | FSE | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount |
| TotalCryptoManualPosition_TRS | FSE | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS |
| LiabilitiesStockReal | FSE + FCUPNL | ISNULL(PositionPnLStocksReal,0) + ISNULL(TotalRealStocks,0) |
| LiabilitiesCryptoReal | FSE + FCUPNL | ISNULL(PositionPnLCryptoReal,0) + ISNULL(TotalRealCrypto,0) |
| LiabilitiesCrypto_TRS | FSE + FCUPNL | ISNULL(CryptoPositionPnL_TRS,0) + ISNULL(Total_TRSCrypto,0) |
| LiabilitiesFuturesReal | FSE + FCUPNL | ISNULL(PositionPnLFuturesReal,0) + ISNULL(TotalRealFutures,0) |

### Dead Join (no columns used)

| Source | Alias | Join | Status |
|--------|-------|------|--------|
| Fact_Guru_Copiers | gc | CID + DateKey = DateID | Dead — LEFT JOIN, no gc.* columns in SELECT. Added 2021-01-11 by Boris Slutski. |
