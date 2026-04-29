# Lineage: DWH_dbo.V_Liabilities

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|---------------|------|--------|------|------|
| 1 | Fact_SnapshotEquity | Table | DWH_dbo | Primary equity snapshot (alias `a`) — cash, positions, credit, AUM, asset-class breakdowns | [Fact_SnapshotEquity.md](../../Tables/Fact_SnapshotEquity.md) |
| 2 | V_M2M_Date_DateRange | View | DWH_dbo | Date range bridge (alias `b`) — expands DateRangeID to individual DateKey + FullDate | [V_M2M_Date_DateRange.md](../../Views/V_M2M_Date_DateRange.md) |
| 3 | Fact_CustomerUnrealized_PnL | Table | DWH_dbo | Unrealized PnL snapshot (alias `c`) — position PnL, NOP, notional, commissions by asset class | [Fact_CustomerUnrealized_PnL.md](../../Tables/Fact_CustomerUnrealized_PnL.md) |
| 4 | Fact_Guru_Copiers | Table | DWH_dbo | CopyTrader snapshot (alias `gc`) — provides CopyFundAUM | [Fact_Guru_Copiers.md](../../Tables/Fact_Guru_Copiers.md) |

## Column Lineage

| # | View Column | Source Alias | Source Column | Transform | Tier | Origin |
|---|-------------|--------------|---------------|-----------|------|--------|
| 1 | CID | a | CID | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 2 | DateID | b | DateKey | Rename (DateKey → DateID) | Tier 1 | V_M2M_Date_DateRange |
| 3 | FullDate | b | FullDate | Passthrough | Tier 1 | V_M2M_Date_DateRange |
| 4 | RealizedEquity | a | RealizedEquity | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 5 | TotalPositionsAmount | a | TotalPositionsAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 6 | TotalCash | a | TotalCash | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 7 | InProcessCashouts | a | InProcessCashouts | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 8 | TotalMirrorPositionsAmount | a | TotalMirrorPositionsAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 9 | TotalMirrorCash | a | TotalMirrorCash | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 10 | TotalStockOrders | a | TotalStockOrders | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 11 | TotalMirrorStockOrders | a | TotalMirrorStockOrders | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 12 | Credit | a | Credit | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 13 | AUM | a | AUM | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 14 | BonusCredit | a | BonusCredit | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 15 | TotalStockPositionAmount | a | TotalStockPositionAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 16 | TotalMirrorStockPositionAmount | a | TotalMirrorStockPositionAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 17 | PositionPnL | c | PositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 18 | CopyPositionPnL | c | CopyPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 19 | StandardDeviation | c | StandardDeviation | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 20 | CommissionOnOpen | c | CommissionOnOpen | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 21 | ActualNWA | — | TotalPositionsAmount, TotalCash, TotalStockOrders, PositionPnL, BonusCredit | CASE: capped at BonusCredit when equity > BonusCredit, 0 when equity < 0, else equity | Tier 2 | View-computed |
| 22 | Liabilities | — | InProcessCashouts, TotalPositionsAmount, TotalCash, TotalStockOrders, PositionPnL, BonusCredit | ISNULL(InProcessCashouts,0) + CASE(equity - BonusCredit clamped to 0) | Tier 2 | View-computed |
| 23 | WA_Liabilities | — | TotalPositionsAmount, TotalCash, TotalStockOrders, PositionPnL, BonusCredit, Credit | MIN(Liabilities_base, Credit) — liabilities capped at Credit | Tier 2 | View-computed |
| 24 | Liabilities_InUsedMargin | — | TotalPositionsAmount, TotalCash, TotalStockOrders, PositionPnL, BonusCredit, Credit | MAX(Liabilities_base - Credit, 0) — excess liabilities beyond Credit | Tier 2 | View-computed |
| 25 | StocksPositionPnL | c | StocksPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 26 | TotalStockManualPosition | a | TotalStockPositionAmount, TotalStockOrders, TotalMirrorStockPositionAmount | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | Tier 2 | View-computed |
| 27 | ManualStockPositionPnL | c | StocksPositionPnL, MirrorStocksPositionPnL | StocksPositionPnL - MirrorStocksPositionPnL | Tier 2 | View-computed |
| 28 | MirrorStocksPositionPnL | c | MirrorStocksPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 29 | CryptoPositionPnL | c | CryptoPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 30 | ManualCryptoPositionPnL | c | ManualCryptoPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 31 | CopyCryptoPositionPnL | c | CopyCryptoPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 32 | TotalCryptoPositionAmount | a | TotalCryptoPositionAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 33 | TotalCryptoManualPosition | a | TotalCryptoPositionAmount, TotalMirrorCryptoPositionAmount | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount | Tier 2 | View-computed |
| 34 | CopyFundAUM | gc | CopyFundAUM | Passthrough | Tier 1 | Fact_Guru_Copiers |
| 35 | CopyFundPnL | c | CopyFundPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 36 | NOP | c | NOP | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 37 | Notional | c | Notional | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 38 | NOP_Crypto | c | NOP_Crypto | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 39 | Notional_Crypto | c | Notional_Crypto | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 40 | NOP_CFD | c | NOP_CFD | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 41 | Notional_CFD | c | Notional_CFD | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 42 | NOP_Crypto_CFD | c | NOP_Crypto_CFD | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 43 | Notional_Crypto_CFD | c | Notional_Crypto_CFD | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 44 | PositionPnLStocksReal | c | PositionPnLStocksReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 45 | PositionPnLCryptoReal | c | PositionPnLCryptoReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 46 | TotalRealStocks | a | TotalRealStocks | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 47 | TotalRealCrypto | a | TotalRealCrypto | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 48 | LiabilitiesStockReal | a, c | PositionPnLStocksReal, TotalRealStocks | ISNULL(PositionPnLStocksReal,0) + ISNULL(TotalRealStocks,0) | Tier 2 | View-computed |
| 49 | LiabilitiesCryptoReal | a, c | PositionPnLCryptoReal, TotalRealCrypto | ISNULL(PositionPnLCryptoReal,0) + ISNULL(TotalRealCrypto,0) | Tier 2 | View-computed |
| 50 | CommissionByUnitsCrypto_TRS | c | CommissionByUnitsCrypto_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 51 | CopyCryptoPositionPnL_TRS | c | CopyCryptoPositionPnL_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 52 | CryptoPositionPnL_TRS | c | CryptoPositionPnL_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 53 | FullCommissionByUnitsCrypto_TRS | c | FullCommissionByUnitsCrypto_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 54 | ManualCryptoPositionPnL_TRS | c | ManualCryptoPositionPnL_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 55 | NOP_Crypto_TRS | c | NOP_Crypto_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 56 | Notional_Crypto_TRS | c | Notional_Crypto_TRS | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 57 | Total_TRSCrypto | a | Total_TRSCrypto | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 58 | TotalCryptoPositionAmount_TRS | a | TotalCryptoPositionAmount_TRS | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 59 | TotalCryptoManualPosition_TRS | a | TotalCryptoPositionAmount_TRS, TotalMirrorCryptoPositionAmount_TRS | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS | Tier 2 | View-computed |
| 60 | LiabilitiesCrypto_TRS | a, c | CryptoPositionPnL_TRS, Total_TRSCrypto | ISNULL(CryptoPositionPnL_TRS,0) + ISNULL(Total_TRSCrypto,0) | Tier 2 | View-computed |
| 61 | MirrorRealFuturesPositionPnL | c | MirrorRealFuturesPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 62 | ManualRealFuturesPositionPnL | c | ManualRealFuturesPositionPnL | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 63 | NOP_FuturesReal | c | NOP_FuturesReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 64 | Notional_FuturesReal | c | Notional_FuturesReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 65 | PositionPnLFuturesReal | c | PositionPnLFuturesReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 66 | FullCommissionByUnitsFuturesReal | c | FullCommissionByUnitsFuturesReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 67 | CommissionByUnitsFuturesReal | c | CommissionByUnitsFuturesReal | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 68 | TotalMirrorRealFuturesPositionAmount | a | TotalMirrorRealFuturesPositionAmount | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 69 | TotalRealFutures | a | TotalRealFutures | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 70 | TotalFuturesProviderMargin | a | TotalFuturesProviderMargin | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 71 | LiabilitiesFuturesReal | a, c | PositionPnLFuturesReal, TotalRealFutures | ISNULL(PositionPnLFuturesReal,0) + ISNULL(TotalRealFutures,0) | Tier 2 | View-computed |
| 72 | NOP_StocksMargin | c | NOP_StocksMargin | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 73 | PositionPnLStocksMargin | c | PositionPnLStocksMargin | Passthrough | Tier 1 | Fact_CustomerUnrealized_PnL |
| 74 | TotalStocksMargin | a | TotalStocksMargin | Passthrough | Tier 1 | Fact_SnapshotEquity |
| 75 | TotalStockMarginLoanValue | a | TotalStockMarginLoanValue | Passthrough | Tier 1 | Fact_SnapshotEquity |
