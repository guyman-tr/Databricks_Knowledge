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

All 48 columns are direct passthrough from `Fact_CustomerUnrealized_PnL`. Key column groups:

| Group | Columns | Description |
|-------|---------|-------------|
| Identity | `CID`, `DateModified` | Customer ID and snapshot date |
| P&L Core | `PositionPnL`, `CopyPositionPnL`, `MenualPositionPnL` | Aggregate unrealized P&L by position type |
| Stocks | `StocksPositionPnL`, `PositionPnLStocksReal` | Stock-specific P&L |
| Crypto | `CryptoPositionPnL`, `ManualCryptoPositionPnL`, `CopyCryptoPositionPnL` | Crypto P&L by origin |
| Crypto TRS | `*_TRS` columns (7) | TRS (Total Return Swap) crypto positions |
| Risk | `NOP`, `Notional`, `NOP_Crypto`, `Notional_Crypto`, `NOP_CFD`, `Notional_CFD` etc. | Net Open Position and Notional by asset class |
| Commissions | `CommissionOnOpen`, `FullCommissionOnOpen`, `CommissionByUnits`, `FullCommissionByUnits` | Commission amounts |
| Fund | `CopyFundPnL` | Copy fund unrealized P&L |
| Other | `TransURPnL`, `StandardDeviation`, `UpdateDate` | Transfer unrealized P&L, risk, audit |
| Legacy | `PositionPnL_old` | Previous calculation methodology |

See [Fact_CustomerUnrealized_PnL.md](../Tables/Fact_CustomerUnrealized_PnL.md) for full column documentation.

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DataWareHouseChecker: ValidateDWHreadiness](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952633410) | Validates DWH replication tasks including `DWH Replication Fact_CustomerUnrealized_PnL` with Dim_Date windows |
| [DB Scripts](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13955596294) | Lists DWH `Fact_CustomerUnrealized_PnL_UserAPI` / equity-related objects for app integrations |
| [PeriodicRankingService Documentation](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13951959407) | DWH as source for customer equity snapshots and unrealized P&L |
| [Portfolio Value (Equity)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12039520520) | Business definition of unrealized equity vs portfolio value |

---
*Generated: 2026-03-19 | Quality: 7.8/10 | Passthrough replication view — 48 columns | Sources: 8/10*
