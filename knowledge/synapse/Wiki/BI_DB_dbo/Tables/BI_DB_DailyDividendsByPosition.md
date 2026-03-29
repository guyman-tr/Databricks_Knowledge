# BI_DB_dbo.BI_DB_DailyDividendsByPosition

## 1. Overview

**Position-level dividend** rows for a single calendar day. Unlike `BI_DB_Daily_Dividends` (instrument-level aggregates), this table keeps **one row per position (and customer)** that received a dividend credit, with hedge server, settlement, tax codes, and dividend event metadata for reconciliation and tax reporting.

**Row grain**: `DateID` + `PositionID` + dividend action (natural key implied by the INSERT from `#Final`; upstream DISTINCT/joins limit duplication).

---

## 2. Business Context

`SP_DailyDividendsByPosition` selects **dividend customer actions** from `Fact_CustomerAction` where `ActionTypeID = 35` and `IsFeeDividend = 2` for `@DateID`, joins **positions** and **customer snapshot** for the report date, resolves **IsSettled** using the first `Dim_PositionChangeLog` row after the report date (`ChangeTypeID = 13`), and enriches **hedge server** from `Dim_PositionHedgeServerChangeLog_Snapshot`.

**Index dividend** attributes (`Status`, `EventType`, `TaxCode`, `BuyTax`, `SellTax`, `PositionType`, `DividendValueInCurrency`, `DividendCurrencyID`) come from a **LEFT JOIN** to `#IndexDiv`, built from `etoro_Trade_PositionsProcessedForIndexDividnds` joined to `etoro_Trade_IndexDividends` for processed rows on the payment window.

**Key business rules**:

- **Open filter**: `Dim_Position.OpenDateID <= @DateID`.
- **Index dividends source**: `etoro_Trade_IndexDividends.Status = 2` and `ProcessTime` between `@Date` and next day.
- **Currency display**: `Currency` = `Dim_Instrument.SellCurrency` where `InstrumentTypeID IN (5,6)`, matched on `DividendCurrencyID = SellCurrencyID` (can be NULL if no match).
- **DELETE-INSERT**: `DELETE WHERE Date = @Date` then full reload for that date.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 26 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live data verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-20** against Azure Synapse dedicated pool (ODBC; equivalent to `synapse_sql` MCP `execute_sql_read_only`).

| Check | Result |
|--------|--------|
| **Row count** | 722,609,785 |
| **`Status` distribution** | `2` 688,026,183; `NULL` 32,373,825; `1` 2,209,777 |
| **`EventType` (summary)** | `Cash Dividend` largest bucket (~651M rows); **many** spelling/casing variants of the same corporate-action concepts (e.g. `Cash dividend`, `Cash Dividend - Franked`); `NULL` aligns with rows without `#IndexDiv` match (~32.4M) |
| **Recent sample (`TOP 5` by `Date` DESC)** | `2026-03-19` rows: `Status = 2`, `EventType = Cash Dividend`, `HedgeServerID = 112`, `IsComputeForHedge = 1`, `Currency = USD` |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | DateID | int | YES | YYYYMMDD key for the dividend action day. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.DateID) |
| 2 | Date | date | YES | Calendar date from `CAST(fca.Occurred AS DATE)`. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.Occurred) |
| 3 | HedgeServerID | int | YES | Effective hedge server: snapshot override when active for `@DateID`, else `Dim_Position.HedgeServerID`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID / Dim_Position.HedgeServerID) |
| 4 | PositionID | bigint | YES | Position identifier. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.PositionID) |
| 5 | RealCID | int | YES | Customer identifier on the action. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.RealCID) |
| 6 | IsBuy | int | YES | Position side flag from `Dim_Position`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.IsBuy) |
| 7 | InstrumentID | int | YES | Instrument on the position. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.InstrumentID) |
| 8 | Amount | money | YES | Dividend amount credited (customer action amount). (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.Amount) |
| 9 | IsValidCustomer | int | YES | From snapshot for report date. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.IsValidCustomer) |
| 10 | IsCreditReportValidCB | int | YES | Credit-report validity for CB reporting. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 11 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 12 | Regulation | varchar(50) | YES | Regulation name. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Regulation.Name) |
| 13 | DividendID | int | YES | Corporate action / index dividend id on the action. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.DividendID) |
| 14 | Status | int | YES | Index dividend processing status from `#IndexDiv` when matched (`etoro_Trade_IndexDividends.Status`); NULL when no index-dividend join. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.Status) |
| 15 | EventType | varchar(100) | YES | Raw event type string from index dividends when matched; NULL otherwise. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.EventType) |
| 16 | TaxCode | varchar(10) | YES | Tax code from index dividends when matched. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.TaxCode) |
| 17 | BuyTax | varchar(10) | YES | Buy-side tax from processed row or dividend default `ISNULL(p.BuyTax, d.BuyTax)`. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_PositionsProcessedForIndexDividnds.BuyTax / etoro_Trade_IndexDividends.BuyTax) |
| 18 | SellTax | varchar(10) | YES | Sell-side tax, same coalesce pattern. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_PositionsProcessedForIndexDividnds.SellTax / etoro_Trade_IndexDividends.SellTax) |
| 19 | PositionType | int | YES | Dividend position type from index dividends when matched. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.PositionType) |
| 20 | DividendValueInCurrency | money | YES | Dividend value in dividend currency from index master. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.DividendValueInCurrency) |
| 21 | DividendCurrencyID | int | YES | Currency id for dividend denomination. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.DividendCurrencyID) |
| 22 | Currency | varchar(50) | YES | Display currency code: `Dim_Instrument.SellCurrency` for type 5/6 instruments matching `DividendCurrencyID`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Instrument.SellCurrency) |
| 23 | UpdateDate | datetime | YES | Batch timestamp `GETDATE()` in `#Final`. (Tier 3 -- SP_DailyDividendsByPosition, GETDATE()) |
| 24 | PlayerLevelID | int | YES | Snapshot player level. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.PlayerLevelID) |
| 25 | PlayerStatusID | int | YES | Snapshot player status. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.PlayerStatusID) |
| 26 | IsComputeForHedge | bit | YES | Hedge computation flag from position. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.IsComputeForHedge) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|---------------|
| Fact_CustomerAction | DWH_dbo | Dividend actions (35 / IsFeeDividend=2) |
| Fact_SnapshotCustomer | DWH_dbo | Validity, player ids, regulation id |
| Dim_Range | DWH_dbo | Snapshot date range |
| Dim_Position | DWH_dbo | Position / instrument / hedge / compute flag |
| Dim_Instrument | DWH_dbo | Instrument join / filter |
| Dim_PositionChangeLog | DWH_dbo | IsSettled adjustment (ChangeTypeID 13) |
| Dim_PositionHedgeServerChangeLog_Snapshot | DWH_dbo | HedgeServerID as-of |
| Dim_Regulation | DWH_dbo | Regulation name |
| etoro_Trade_PositionsProcessedForIndexDividnds | DWH_dbo | Processed index dividend link |
| etoro_Trade_IndexDividends | DWH_dbo | Dividend master (status, tax, currency) |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DailyDividendsByPosition |
| **Author** | Jenia; Adi Farber (logging); Adar (indexes / columns) |
| **ETL Pattern** | DELETE-INSERT by `Date` |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Date` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Date / DateID** | Clustered index on `Date`; filter both for consistency. |
| **LEFT index metadata** | Tax/event columns NULL when no `#IndexDiv` match -- expected. |
| **EventType** | Treat as raw source strings; normalize externally if comparing event kinds. |
| **Downstream** | Consumed by `SP_RollOverFee_Dividends`, tax reports, alerts. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Dividends |
| **Sub-domain** | Position-level dividend detail |
| **Sensitivity** | Customer + position + amounts |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
