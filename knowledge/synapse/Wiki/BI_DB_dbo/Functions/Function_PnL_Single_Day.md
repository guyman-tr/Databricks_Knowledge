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
| 2 | CID |  | Direct | T1 |
| 3 | PositionID |  | Direct | T1 |
| 4 | UnrealizedPnLStart |  | SUM(UnrealizedPnLStart) | T2 |
| 5 | UnrealizedPnLEnd |  | SUM(UnrealizedPnLEnd) | T2 |
| 6 | UnrealizedPnLChange |  | SUM(UnrealizedPnLChange) | T2 |
| 7 | NetProfit |  | SUM(NetProfit) | T2 |
| 8 | InstrumentID |  | Direct | T1 |
| 9 | MirrorID |  | Direct | T1 |
| 10 | Leverage |  | Direct | T1 |
| 11 | IsBuy |  | Direct | T1 |
| 12 | IsSettled |  | Direct | T1 |
| 13 | HedgeServerID |  | Direct | T1 |
| 14 | SettlementTypeID |  | Direct | T1 |
| 15 | ClosedOnDate |  | Direct | T1 |
| 16 | IsFuture |  | Direct | T1 |
| 17 | IsCopyFund |  | Direct | T1 |
| 18 | IsMarginTrade |  | Direct | T1 |
| 19 | IsSQF |  | case when InstrumentID is not null then 1 else 0 end | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
