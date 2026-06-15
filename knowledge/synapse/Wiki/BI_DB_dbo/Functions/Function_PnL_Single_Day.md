# Function_PnL_Single_Day

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | PnL (Profit and Loss) |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 19 (T1: 13, T2: 6) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

single date full PnL picture (realized + unreaized change)

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @dateID | int | Date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_CopyFund_Positions | BI_DB_dbo |
| BI_DB_PositionPnL | BI_DB_dbo |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Position | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID |  | @dateID | T2 |
| 2 | CID |  | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 3 | PositionID |  | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 4 | UnrealizedPnLStart |  | SUM(UnrealizedPnLStart) | T2 |
| 5 | UnrealizedPnLEnd |  | SUM(UnrealizedPnLEnd) | T2 |
| 6 | UnrealizedPnLChange |  | SUM(UnrealizedPnLChange) | T2 |
| 7 | NetProfit |  | SUM(NetProfit) | T2 |
| 8 | InstrumentID |  | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 9 | MirrorID |  | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 10 | Leverage |  | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 11 | IsBuy |  | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 12 | IsSettled |  | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) (via Dim_Position) | T1 |
| 13 | HedgeServerID |  | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 14 | SettlementTypeID |  | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 15 | ClosedOnDate |  | ISNULL(dp.ClosedOnDate, 0) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: 1 when (dp.CloseDateID = @dateID) OR 0 (fallback); where dp = DWH_dbo.Dim_Position | T1 |
| 16 | IsFuture |  | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 17 | IsCopyFund |  | CASE WHEN NOT cpt.PositionID IS NULL THEN 1 ELSE 0 END (sql-derived [case] from Function_PnL_Single_Day); where cpt = BI_DB_dbo.BI_DB_CopyFund_Positions | T1 |
| 18 | IsMarginTrade |  | COALESCE(dp.IsMarginTrade, upl.IsMarginTrade) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END OR CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END; where dp = DWH_dbo.Dim_Position, bdppl = BI_DB_dbo.BI_DB_PositionPnL | T1 |
| 19 | IsSQF |  | case when InstrumentID is not null then 1 else 0 end | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
