# Function_Trading_Volume

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Trading Volume |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 27 (T1: 8, T2: 19) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Builds **two legs** from `DWH_dbo.Dim_Position` over the inclusive `YYYYMMDD` range `[@sdateInt, @edateInt]`: **opens** where `OpenDateID` is in range (uses persisted `Volume`, `InitialAmountCents`, open counters), and **closes** where `CloseDateID` is in range (uses `VolumeOnClose`, `Amount` as closed invested, close counter). The legs are `UNION ALL`’d; each row gets `TotalVolume = ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0)` and `NetInvestedAmount = InvestedAmountOpen - InvestedAmountClosed` before the final `GROUP BY` on customer and product attributes. Joins `Fact_SnapshotCustomer` + `Dim_Range` (as-of snapshot for the event `DateID`), `Dim_Instrument`, SQF and C2P flags, then left-joins copy-fund / recurring / IBAN helper tables on `PositionID` for reporting dimensions.

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
| 1 | CID | DWH_dbo.Dim_Position.CID | GROUP BY customer from position events | T1 |
| 2 | InstrumentID | DWH_dbo.Dim_Position.InstrumentID | GROUP BY | T1 |
| 3 | Leverage | DWH_dbo.Dim_Position.Leverage | GROUP BY | T1 |
| 4 | DateID | DWH_dbo.Dim_Position.OpenDateID, CloseDateID | Event date from open or close leg of union | T2 |
| 5 | VolumeOpen | DWH_dbo.Dim_Position.Volume | `SUM(CAST(VolumeOpen AS BIGINT))` where each open row has `VolumeOpen = ISNULL(CAST(Volume AS BIGINT),0)` and **`OpenDateID` BETWEEN @sdateInt AND @edateInt** | T2 |
| 6 | VolumeClose | DWH_dbo.Dim_Position.VolumeOnClose | `SUM(CAST(VolumeClose AS BIGINT))` where each close row has `VolumeClose = ISNULL(CAST(VolumeOnClose AS BIGINT),0)` and **`CloseDateID` BETWEEN @sdateInt AND @edateInt** | T2 |
| 7 | InvestedAmountOpen | DWH_dbo.Dim_Position.InitialAmountCents | `SUM(InvestedAmountOpen)` with `CASE WHEN IsPartialCloseChild=1 THEN 0 ELSE InitialAmountCents/100 END` on **open** rows only | T2 |
| 8 | InvestedAmountClosed | DWH_dbo.Dim_Position.Amount | `SUM(Amount)` on **close** rows only (`CloseDateID` in range) | T2 |
| 9 | TotalVolume | DWH_dbo.Dim_Position.Volume, VolumeOnClose | Row-level `ISNULL(VolumeOpen,0)+ISNULL(VolumeClose,0)` in CTE; output **`SUM(CAST(TotalVolume AS BIGINT))`** by group | T2 |
| 10 | NetInvestedAmount | DWH_dbo.Dim_Position | Row-level `InvestedAmountOpen - InvestedAmountClosed` in CTE; output **`SUM(NetInvestedAmount)`** | T2 |
| 11 | CountOpenTransactions | DWH_dbo.Dim_Position.IsPartialCloseChild | `SUM(CountOpenTransactions)` where open rows use `CASE WHEN IsPartialCloseChild=1 THEN 0 ELSE 1 END` (**excludes partial-close child opens**) | T2 |
| 12 | CountCloseTransactions | DWH_dbo.Dim_Position | `SUM(CountCloseTransactions)` — **1** on each close row, **0** on opens | T2 |
| 13 | CountTotalTransactions | DWH_dbo.Dim_Position | `SUM(CountTotalTransactions)` where CTE sets `CountOpenTransactions + CountCloseTransactions` per row | T2 |
| 14 | IsSettled | DWH_dbo.Dim_Position.IsSettled | GROUP BY | T1 |
| 15 | IsCopy | DWH_dbo.Dim_Position.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END; GROUP BY | T2 |
| 16 | InstrumentTypeID | DWH_dbo.Dim_Instrument.InstrumentTypeID | JOIN; GROUP BY | T1 |
| 17 | IsCopyFund | BI_DB_dbo.BI_DB_CopyFund_Positions | CASE WHEN PositionID matched THEN 1 ELSE 0 END | T2 |
| 18 | IsRecurring | BI_DB_dbo.BI_DB_RecurringInvestment_Positions | CASE WHEN PositionID matched THEN 1 ELSE 0 END | T2 |
| 19 | IsOpenedFromIBAN | BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN | CASE WHEN PositionID matched THEN 1 ELSE 0 END | T2 |
| 20 | IsClosedToIBAN | BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN | CASE WHEN PositionID matched THEN 1 ELSE 0 END | T2 |
| 21 | IsAirDrop | DWH_dbo.Dim_Position.IsAirDrop | ISNULL(IsAirDrop,0); GROUP BY | T2 |
| 22 | IsBuy | DWH_dbo.Dim_Position.IsBuy | GROUP BY | T1 |
| 23 | IsFuture | DWH_dbo.Dim_Instrument.IsFuture | GROUP BY | T1 |
| 24 | SettlementTypeID | DWH_dbo.Dim_Position.SettlementTypeID | GROUP BY | T1 |
| 25 | IsMarginTrade | DWH_dbo.Dim_Position.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END; ISNULL; GROUP BY | T2 |
| 26 | IsSQF | BI_DB_dbo.Function_Instrument_Snapshot_Enriched | Instrument in SQF subset at @edateInt; GROUP BY | T2 |
| 27 | IsC2P | BI_DB_dbo.V_C2P_Positions | CASE WHEN PositionID matched THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2024-12-11 | Guy M | Added count of transactions needed by compliance |
| 2025-04-12 | Guy M | Added invested amounts |
| 2025-04-20 | Guy M | Added isbuy |
| 2025-04-23 | Guy M | cast as bigint, was creating errors over large periods of time |
| 2025-05-02 | Guy M | bug fix: forgot to exclude IsPartialChild = 1 from initial amounts. fixed |
| 2025-10-23 | Guy M | added margin trades |
| 2025-11-24 | Guy M | fixed count of open positions - remove child opens |
| 2025-12-14 | Guy M | adde C2P |


---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
