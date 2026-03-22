# Function_Trading_Volume_PositionLevel

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Trading Volume |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 32 (T1: 12, T2: 20) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Position-level **one row per open or close event** (not aggregated across positions): **opens** with `OpenDateID` between `@sdateInt` and `@edateInt`, **closes** with `CloseDateID` in that range, unioned like `Function_Trading_Volume`. Exposes both **persisted** volume (`Volume` / `VolumeOnClose`) and **QA recomputed** notional from units × FX (and conversion-rate fallback chain on open), plus `IsValidCustomer` and product/context flags—no final `GROUP BY` volume roll-up.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Position | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |
| V_C2P_Positions | BI_DB_dbo |
| BI_DB_CopyFund_Positions | BI_DB_dbo |
| BI_DB_RecurringInvestment_Positions | BI_DB_dbo |
| BI_DB_Positions_Opened_From_IBAN | BI_DB_dbo |
| BI_DB_Positions_Closed_To_IBAN | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | DWH_dbo.Dim_Position.CID | Direct from union row | T1 |
| 2 | PositionID | DWH_dbo.Dim_Position.PositionID | Direct | T1 |
| 3 | InstrumentID | DWH_dbo.Dim_Position.InstrumentID | Direct | T1 |
| 4 | Amount | DWH_dbo.Dim_Position.Amount | Direct | T1 |
| 5 | Leverage | DWH_dbo.Dim_Position.Leverage | Direct | T1 |
| 6 | DateID | DWH_dbo.Dim_Position.OpenDateID, CloseDateID | Open or close calendar date | T2 |
| 7 | VolumeOpen | DWH_dbo.Dim_Position.Volume | `ISNULL(CAST(Volume AS BIGINT),0)` on **open** leg only (`OpenDateID` in range); **0** on close leg | T2 |
| 8 | VolumeClose | DWH_dbo.Dim_Position.VolumeOnClose | `ISNULL(CAST(VolumeOnClose AS BIGINT),0)` on **close** leg (`CloseDateID` in range); **0** on open leg | T2 |
| 9 | InvestedAmountOpen | DWH_dbo.Dim_Position.InitialAmountCents | CASE WHEN IsPartialCloseChild=1 THEN 0 ELSE InitialAmountCents/100.0 END on opens | T2 |
| 10 | InvestedAmountClosed | DWH_dbo.Dim_Position.Amount | CAST(Amount AS FLOAT) on closes | T2 |
| 11 | TotalVolume | DWH_dbo.Dim_Position.Volume, VolumeOnClose | `ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0)` per union row (stored volumes, not computed QA columns) | T2 |
| 12 | NetInvestedAmount | DWH_dbo.Dim_Position | `ISNULL(InvestedAmountOpen,0) - ISNULL(InvestedAmountClosed,0)` (open uses `InitialAmountCents/100.0` unless partial-close child; close uses `CAST(Amount AS FLOAT)`) | T2 |
| 13 | CountOpenTransactions | DWH_dbo.Dim_Position.IsPartialCloseChild | 1 or 0 on opens | T2 |
| 14 | CountCloseTransactions | DWH_dbo.Dim_Position | 0 on opens; 1 on closes | T2 |
| 15 | CountTotalTransactions | DWH_dbo.Dim_Position | CountOpenTransactions + CountCloseTransactions | T2 |
| 16 | IsSettled | DWH_dbo.Dim_Position.IsSettled | Direct | T1 |
| 17 | IsAirDrop | DWH_dbo.Dim_Position.IsAirDrop | Direct | T1 |
| 18 | IsBuy | DWH_dbo.Dim_Position.IsBuy | Direct | T1 |
| 19 | SettlementTypeID | DWH_dbo.Dim_Position.SettlementTypeID | Direct | T1 |
| 20 | ComputedVolumeOpen | DWH_dbo.Dim_Position | `CASE WHEN IsPartialCloseChild = 1 THEN 0 ELSE InitialUnits * InitForexRate * ISNULL(COALESCE(InitForex_USDConversionRate, InitConversionRate, LastOpConversionRate), 1) END` on **opens**; **0** on closes | T2 |
| 21 | ComputedVolumeClose | DWH_dbo.Dim_Position | `AmountInUnitsDecimal * EndForexRate * ISNULL(LastOpConversionRate, 1)` on **closes**; **0** on opens | T2 |
| 22 | IsCopy | DWH_dbo.Dim_Position.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END | T2 |
| 23 | IsMarginTrade | DWH_dbo.Dim_Position.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 24 | InstrumentTypeID | DWH_dbo.Dim_Instrument.InstrumentTypeID | JOIN | T1 |
| 25 | IsFuture | DWH_dbo.Dim_Instrument.IsFuture | JOIN | T1 |
| 26 | IsSQF | BI_DB_dbo.Function_Instrument_Snapshot_Enriched | ISNULL from TVF subset IsSQF=1 at @edateInt | T2 |
| 27 | IsC2P | BI_DB_dbo.V_C2P_Positions | CASE WHEN join match THEN 1 ELSE 0 END | T2 |
| 28 | IsCopyFund | BI_DB_dbo.BI_DB_CopyFund_Positions | CASE WHEN join match THEN 1 ELSE 0 END | T2 |
| 29 | IsRecurring | BI_DB_dbo.BI_DB_RecurringInvestment_Positions | CASE WHEN join match THEN 1 ELSE 0 END | T2 |
| 30 | IsOpenedFromIBAN | BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN | CASE WHEN join match THEN 1 ELSE 0 END | T2 |
| 31 | IsClosedToIBAN | BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN | CASE WHEN join match THEN 1 ELSE 0 END | T2 |
| 32 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer.IsValidCustomer | JOIN snapshot on RealCID + Dim_Range | T1 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
