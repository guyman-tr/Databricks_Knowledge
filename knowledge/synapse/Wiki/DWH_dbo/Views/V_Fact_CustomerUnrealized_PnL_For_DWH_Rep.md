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
| 1 | CID | int | Fact_CustomerUnrealized_PnL.CID | Customer ID. Grouping key for all PnL aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key, part of PK. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 2 | DateModified | int | Fact_CustomerUnrealized_PnL.DateModified | Date key in YYYYMMDD integer format. Part of PK. One row per CID per day. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 3 | PositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnL | Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 4 | CopyPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Unrealized PnL from copy-trading positions only (MirrorID > 0). Includes all asset classes. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 5 | MenualPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.MenualPositionPnL | Unrealized PnL from manually-opened positions only (MirrorID = 0). Note: column name is a typo for "Manual". (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 6 | StocksPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Includes both real and CFD stocks, both manual and copy. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 7 | UpdateDate | datetime | Fact_CustomerUnrealized_PnL.UpdateDate | ETL load timestamp (GETDATE() at INSERT time). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 8 | TransURPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.TransURPnL | Transaction unrealized PnL. Not populated by the current ETL SP — always NULL. Legacy column. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 9 | StandardDeviation | float | Fact_CustomerUnrealized_PnL.StandardDeviation | Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: √(Σ weight_a × weight_b × covariance). NULL for pre-2013 data. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 10 | CommissionOnOpen | decimal(16,2) | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Sum of opening commissions (Commission) across all open positions for this CID. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 11 | MirrorStocksPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 12 | CryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 13 | ManualCryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Unrealized PnL from manually-opened crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID = 0). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 14 | CopyCryptoPositionPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Unrealized PnL from copy-trading crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID > 0). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 15 | CopyFundPnL | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyFundPnL | Unrealized PnL from positions opened via copy-fund relationships (parent CID had AccountTypeID=9 at the time the copy was opened). Identified via History.BackOfficeCustomer + History.Mirror join. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 16 | FullCommissionOnOpen | decimal(16,2) | Fact_CustomerUnrealized_PnL.FullCommissionOnOpen | Sum of full opening commissions (FullCommission, before any discounts) across all open positions for this CID. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 17 | NOP | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP | Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. "eToro holding of each instrument" (Confluence). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 18 | Notional | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional | Total absolute USD exposure across all instruments. ABS(NOP) per instrument, then summed. Always >= 0. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 19 | NOP_Crypto | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto | Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 20 | Notional_Crypto | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto | Absolute USD exposure for crypto instruments only. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 21 | NOP_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_CFD | Net Open Position for all CFD positions (IsSettled = 0), all asset classes. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 22 | Notional_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_CFD | Absolute USD exposure for all CFD positions. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 23 | NOP_Crypto_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 24 | Notional_Crypto_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Absolute USD exposure for crypto CFD positions. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 25 | CommissionByUnits | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnits | Sum of prorated commissions (CommissionByUnits) across all open positions. Accounts for partial closes. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 26 | FullCommissionByUnits | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnits | Sum of full prorated commissions (FullCommissionByUnits, before discounts) across all open positions. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 27 | NOP_Stock | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Stock | Net Open Position for stock instruments (InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 28 | Notional_Stock | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Stock | Absolute USD exposure for stock instruments. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 29 | NOP_Stock_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Stock_CFD | Net Open Position for stock CFD positions (InstrumentTypeID IN (5,6) AND IsSettled = 0). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 30 | Notional_Stock_CFD | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Stock_CFD | Absolute USD exposure for stock CFD positions. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 31 | PositionPnLStocksReal | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 32 | PositionPnLCryptoReal | decimal(16,2) | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). Uses PnLInDollars. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 33 | FullCommissionByUnitsStocksReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsStocksReal | Full prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 34 | FullCommissionByUnitsCryptoReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCryptoReal | Full prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 35 | GuruCopiesPNL | decimal(16,2) | Fact_CustomerUnrealized_PnL.GuruCopiesPNL | Unrealized PnL from guru-connected copy positions (ConnectedGuruCopies = 1 AND MirrorID > 0). ConnectedGuruCopies = 1 means ParentPositionID != 0. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 36 | GuruCopiesPNL_Dit | decimal(16,2) | Fact_CustomerUnrealized_PnL.GuruCopiesPNL_Dit | Unrealized PnL from non-guru-connected copy positions (ConnectedGuruCopies = 0 AND MirrorID > 0). "Dit" = direct copy without guru position linkage. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 37 | CommissionByUnitsStocksReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsStocksReal | Prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 38 | CommissionByUnitsCryptoReal | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsCryptoReal | Prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 39 | FullCommissionByUnitsStocksCFD | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsStocksCFD | Full prorated commission for stock CFD positions (IsSettled = 0 AND InstrumentTypeID IN (5,6)). Added 2021-12-19 (Adi F). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 40 | FullCommissionByUnitsCryptoCFD | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCryptoCFD | Full prorated commission for crypto CFD positions (IsSettled = 0 AND InstrumentTypeID = 10). Added 2021-12-19 (Adi F). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 41 | CommissionByUnitsCrypto_TRS | decimal(38,6) | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). Added 2022-01-27 (Inbal BML). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 42 | CopyCryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 43 | CryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 44 | FullCommissionByUnitsCrypto_TRS | decimal(38,6) | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Full prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 45 | ManualCryptoPositionPnL_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Unrealized PnL from manually-opened crypto TRS positions (InstrumentTypeID = 10 AND MirrorID = 0 AND SettlementTypeID = 2). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 46 | NOP_Crypto_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 47 | Notional_Crypto_TRS | decimal(16,2) | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Absolute USD exposure for crypto TRS positions. (Tier 2 — via Fact_CustomerUnrealized_PnL) |
| 48 | PositionPnL_old | decimal(38,6) | Fact_CustomerUnrealized_PnL.PositionPnL_old | Legacy PnL calculated using V0 formula (CalculatedNetProfit from bid/ask price differences). Kept for V0-vs-V1 gap monitoring (SP_PNL_Alerts_Gap_Old_VS_New). Will eventually be deprecated. (Tier 2 — via Fact_CustomerUnrealized_PnL) |

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
