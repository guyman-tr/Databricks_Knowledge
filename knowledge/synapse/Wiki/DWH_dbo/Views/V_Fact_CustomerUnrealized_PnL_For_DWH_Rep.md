# DWH_dbo.V_Fact_CustomerUnrealized_PnL_For_DWH_Rep

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_CustomerUnrealized_PnL_For_DWH_Rep]` |
| **Type** | View |
| **Base Tables** | `Fact_CustomerUnrealized_PnL` |
| **Purpose** | Replication-ready column subset of `Fact_CustomerUnrealized_PnL`. Provides all columns except identity/internal columns for downstream DWH replication targets. |

## 2. Business Context

This is a **passthrough replication view** — it selects 48 columns from `Fact_CustomerUnrealized_PnL` without any filtering, joining, or computation. The "ForDWHRep" suffix indicates it feeds downstream DWH replication processes.

The view exposes unrealized P&L metrics by customer, including breakdowns by asset class (stocks, crypto, futures, CFD) and position type (manual, copy, mirror). It also includes risk metrics like NOP (Net Open Position) and Notional values.

## 3. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | CID | int | Fact_CustomerUnrealized_PnL.CID | Customer ID. Grouping key for all PnL aggregations. FK to Dim_Customer. HASH distribution key, part of PK. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 2 | DateModified | int | Fact_CustomerUnrealized_PnL.DateModified | Date key in YYYYMMDD integer format. Part of PK. One row per CID per day. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 3 | PositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnL | Total unrealized PnL in USD across all open positions. Primary PnL metric. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 4 | CopyPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Unrealized PnL from copy-trading positions only (MirrorID > 0). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 5 | MenualPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.MenualPositionPnL | Unrealized PnL from manual positions (MirrorID = 0). Note: typo for "Manual". (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 6 | StocksPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 7 | UpdateDate | datetime | Fact_CustomerUnrealized_PnL.UpdateDate | ETL load timestamp (GETDATE() at INSERT time). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 8 | TransURPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.TransURPnL | Transaction unrealized PnL. Not populated — always NULL. Legacy. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 9 | StandardDeviation | float | Fact_CustomerUnrealized_PnL.StandardDeviation | Portfolio risk: standard deviation from instrument covariance matrix. NULL pre-2013. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 10 | CommissionOnOpen | decimal(16,2) | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Sum of opening commissions across all open positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 11 | MirrorStocksPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Unrealized PnL from copy-trading stock positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 12 | CryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 13 | ManualCryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Unrealized PnL from manually-opened crypto positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 14 | CopyCryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Unrealized PnL from copy-trading crypto positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 15 | CopyFundPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyFundPnL | Unrealized PnL from copy-fund relationships (parent AccountTypeID=9). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 16 | FullCommissionOnOpen | decimal(16,2) | Fact_CustomerUnrealized_PnL.FullCommissionOnOpen | Sum of full opening commissions (before discounts). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 17 | NOP | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP | Net Open Position — total signed directional USD exposure. Positive = net long, negative = net short. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 18 | Notional | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional | Total absolute USD exposure across all instruments. Always >= 0. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 19 | NOP_Crypto | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto | Net Open Position for crypto instruments only. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 20 | Notional_Crypto | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto | Absolute USD exposure for crypto instruments. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 21 | NOP_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_CFD | Net Open Position for all CFD positions (IsSettled = 0). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 22 | Notional_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_CFD | Absolute USD exposure for all CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 23 | NOP_Crypto_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Net Open Position for crypto CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 24 | Notional_Crypto_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Absolute USD exposure for crypto CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 25 | CommissionByUnits | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnits | Sum of prorated commissions across all open positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 26 | FullCommissionByUnits | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnits | Sum of full prorated commissions (before discounts). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 27 | NOP_Stock | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Stock | Net Open Position for stock instruments. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 28 | Notional_Stock | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Stock | Absolute USD exposure for stock instruments. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 29 | NOP_Stock_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Stock_CFD | Net Open Position for stock CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 30 | Notional_Stock_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Stock_CFD | Absolute USD exposure for stock CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 31 | PositionPnLStocksReal | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Unrealized PnL from real (settled) stock positions only. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 32 | PositionPnLCryptoReal | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Unrealized PnL from real (settled) crypto positions only. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 33 | FullCommissionByUnitsStocksReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsStocksReal | Full prorated commission for real stock positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 34 | FullCommissionByUnitsCryptoReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCryptoReal | Full prorated commission for real crypto positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 35 | GuruCopiesPNL | decimal(16,2) | Fact_CustomerUnrealized_PnL.GuruCopiesPNL | Unrealized PnL from guru-connected copy positions (ConnectedGuruCopies = 1). (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 36 | GuruCopiesPNL_Dit | decimal(16,2) | Fact_CustomerUnrealized_PnL.GuruCopiesPNL_Dit | Unrealized PnL from non-guru-connected copy positions. "Dit" = direct copy. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 37 | CommissionByUnitsStocksReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsStocksReal | Prorated commission for real stock positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 38 | CommissionByUnitsCryptoReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsCryptoReal | Prorated commission for real crypto positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 39 | FullCommissionByUnitsStocksCFD | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsStocksCFD | Full prorated commission for stock CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 40 | FullCommissionByUnitsCryptoCFD | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCryptoCFD | Full prorated commission for crypto CFD positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 41 | CommissionByUnitsCrypto_TRS | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Prorated commission for crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 42 | CopyCryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Unrealized PnL from copy-trading crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 43 | CryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Unrealized PnL from all crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 44 | FullCommissionByUnitsCrypto_TRS | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Full prorated commission for crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 45 | ManualCryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Unrealized PnL from manually-opened crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 46 | NOP_Crypto_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Net Open Position for crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 47 | Notional_Crypto_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Absolute USD exposure for crypto TRS positions. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |
| 48 | PositionPnL_old | decimal(38,6) | Fact_CustomerUnrealized_PnL.PositionPnL_old | Legacy PnL using V0 formula. Kept for gap monitoring. Will be deprecated. (Tier 1 — inherited from Fact_CustomerUnrealized_PnL wiki) |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DataWareHouseChecker: ValidateDWHreadiness](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952633410) | Validates DWH replication tasks including `DWH Replication Fact_CustomerUnrealized_PnL` with Dim_Date windows |
| [DB Scripts](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13955596294) | Lists DWH `Fact_CustomerUnrealized_PnL_UserAPI` / equity-related objects for app integrations |
| [PeriodicRankingService Documentation](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13951959407) | DWH as source for customer equity snapshots and unrealized P&L |
| [Portfolio Value (Equity)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12039520520) | Business definition of unrealized equity vs portfolio value |

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 48 columns expanded (all Tier 1 from Fact_CustomerUnrealized_PnL wiki) | Sources: SSDT DDL, Fact_CustomerUnrealized_PnL.md*
