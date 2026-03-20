# DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Immediate Source** | DWH_dbo.Fact_CustomerUnrealized_PnL |
| **ETL SP** | SP_Fact_CustomerUnrealized_PnL (same SP as parent table) |
| **Relationship** | Column subset — 34 of ~60 columns, no transformation |

## Column Lineage

All 34 columns are direct passthroughs from `Fact_CustomerUnrealized_PnL`. No transforms applied. See Fact_CustomerUnrealized_PnL lineage for the full column-level source mapping.

## Columns Retained (from parent)

CID, DateModified, PositionPnL, CopyPositionPnL, MenualPositionPnL, StocksPositionPnL, UpdateDate, TransURPnL, StandardDeviation, CommissionOnOpen, MirrorStocksPositionPnL, CryptoPositionPnL, ManualCryptoPositionPnL, CopyCryptoPositionPnL, CopyFundPnL, FullCommissionOnOpen, NOP, Notional, NOP_Crypto, Notional_Crypto, NOP_CFD, Notional_CFD, NOP_Crypto_CFD, Notional_Crypto_CFD, CommissionByUnits, FullCommissionByUnits, NOP_Stock, Notional_Stock, NOP_Stock_CFD, Notional_Stock_CFD, PositionPnLStocksReal, PositionPnLCryptoReal, FullCommissionByUnitsStocksReal, FullCommissionByUnitsCryptoReal

## Columns Excluded (in parent only)

All equity, cash, liability, overnight fee, position count, and internal risk columns from the parent table are excluded.
