# Dealing_dbo.Dealing_Apex_PnL

> Week-to-date (WTD) PnL reconciliation for eToro’s Apex Clearing LP account by instrument — Middle Office compares internal valuations to Apex statements; **data is stale (frozen since June 2024)**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing LP external files → `Dealing_staging.LP_APEX_EXT872_3EU_217314` (trades/dividends) + `LP_APEX_EXT982_3EU` (NOP/holdings) + `PriceLog_History_CurrencyPrice` + `Dealing_DailyZeroPnL_Stocks` |
| **Refresh** | Weekly (Saturday reporting date per `SP_Apex_PnL`; same SP also loads daily and equity variants) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last pipeline update **2024-06-08 09:19**. The table has had **no fresh loads for roughly nine months** (as of March 2026). Treat all figures as **historical** unless the Apex LP pipeline is reactivated; downstream consumers should confirm whether Apex Clearing remains the active US equities LP.

This table answers: **What was eToro’s net PnL on each symbol/instrument held at Apex for the week ending on `Date`?** Apex is a US clearing broker for US stocks and ETFs. Grain is **one row per `(Date, AccountNumber, Symbol)`** for **week-to-date** metrics. It supports **Dealing / Middle Office** in verifying that eToro’s internal position valuations match Apex’s statements.

**Data lineage & freshness (operational context):** The writer is **`Dealing_dbo.SP_Apex_PnL`**. Sources include Apex staging position and activity data, internal DB prices (`PriceLog_History_CurrencyPrice`), zero-position adjustments from **`Dealing_DailyZeroPnL_Stocks`**, and **`DWH_dbo.Dim_Instrument`** for symbol resolution. Refresh was intended as **weekly WTD** (Saturday date logic); **Phase 2 sampling confirmed stale data** and **bank-holiday handling in the SP** (NOP uses the previous business day on holidays). **PII:** No client CID — account-level LP data only.

**Price-reconciliation intent:** Non-`_DBPrice` amounts use **Apex closing prices**; `*_DBPrice` columns use **eToro’s internal database prices**. Comparing `PnL` vs `PnL_DBPrice` highlights valuation differences between Apex and eToro.

## 2. Business Logic

**WTD PnL formula** (from `SP_Apex_PnL`, Apex-priced path):

```
PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees
PnL_DBPrice = NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees
```

- **`NOP_Start` / `NOP_End`:** Net open position (market value) at **week start** (Friday EOD of the prior week) and **week end** (`Date`), using Apex marks.
- **`Trades`:** Net value of trades in the week (buys add, sells subtract) from Apex trade activity.
- **`Dividends`:** Dividend income from Apex for the symbol in the week.
- **`AdditionalFees`:** Apex fees/adjustments (e.g. borrow, corporate actions) included in PnL.
- **`Zero`:** Adjustment from **`Dealing_DailyZeroPnL_Stocks`** so PnL reflects positions that **opened and fully closed to zero** within the week (without this, WTD PnL can miss those names).

**Instrument mapping:** `InstrumentID` / `InstrumentDisplayName` come from matching Apex **Symbol / CUSIP / ISIN** to **`DWH_dbo.Dim_Instrument`**; **NULL `InstrumentID`** means the row could not be reconciled to the DWH instrument dimension.

**Typical filters:** `WHERE Date = @ReportDate AND AccountNumber = @Acct` or by `Symbol` for a single-name check.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Distribution** | **ROUND_ROBIN** — no hash key; large scans are driven by **`Date`** and predicates on **`AccountNumber`** / **`Symbol`**. |
| **Clustering** | **Clustered on `Date` ASC** — **always filter `Date`** (or a tight date range) to limit scans. |
| **Joins** | Join to **`DWH_dbo.Dim_Instrument`** on **`InstrumentID`** when you need instrument attributes (expect **NULL InstrumentID** for unmatched Apex symbols). |
| **Scale** | Approximately **~3.0M rows** historically (2021-02-10 through 2024-06-07); acceptable for date-scoped reporting but avoid full-table scans in ad hoc work. |
| **Stale data** | Do not assume “current week” — confirm **`MAX(Date)`** and **`UpdateDate`** before publishing numbers. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Report date** — the **Saturday / end-of-week** date for which this **week-to-date** PnL row applies; aligns with SP WTD calendar logic. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex LP account number** (e.g. eToro’s account at Apex Clearing); groups all symbols under the same clearer account. (Tier 2 — SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | **Instrument symbol as Apex reports it** (e.g. `AAPL`, `SPY`); used with CUSIP/ISIN to resolve **`DWH_dbo.Dim_Instrument`**. (Tier 2 — SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | **Net open position at week start** (prior Friday EOD), valued at **Apex’s closing price** — opening mark for the WTD bridge. (Tier 2 — SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | **NOP at week start** using **eToro internal DB price** × quantity — pairs with Apex NOP for **mark-to-market reconciliation**. (Tier 2 — SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | **Net open position at week end** (`Date`), **Apex closing price** — closing mark for the WTD bridge. (Tier 2 — SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | **NOP at week end** using **eToro DB bid** × quantity — internal mark at the same point as `NOP_End`. (Tier 2 — SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | **Net traded notional** for the week from Apex activity (buys vs sells); enters the PnL formula with a **minus** sign. (Tier 2 — SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | **Dividend income** credited via Apex for this **symbol** during the week. (Tier 2 — SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | **Week-to-date PnL using Apex prices:** `NOP_End - NOP_Start - Trades + Dividends + AdditionalFees` — primary “statement-side” PnL. (Tier 2 — SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | **WTD PnL using eToro DB prices** on NOP start/end — compare to **`PnL`** to isolate **price-source** differences vs Apex. (Tier 2 — SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | **Row load timestamp** from the ETL (`GETDATE()` in `SP_Apex_PnL`) — when this row was last written. (Tier 2 — SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | **eToro instrument key** from **`DWH_dbo.Dim_Instrument`** when Apex identifiers match; **NULL** if no match. (Tier 2 — SP_Apex_PnL) |
| 14 | InstrumentDisplayName | varchar(100) | YES | **eToro display name** for the instrument — may differ from Apex **`Symbol`**. (Tier 2 — SP_Apex_PnL) |
| 15 | Price_Start | decimal(16,6) | YES | **Apex closing price** at **week start** (prior Friday EOD). (Tier 2 — SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | **eToro DB bid** at week start — supports **price-level** reconciliation alongside `Price_Start`. (Tier 2 — SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | **Apex closing price** at **week end** (`Date`). (Tier 2 — SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | **eToro DB bid** at week end — pairs with `Price_End`. (Tier 2 — SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | **Additional Apex fees/adjustments** (borrow, corp actions, etc.) **included** in the published PnL bridge. (Tier 2 — SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | **Total traded volume in units** at Apex for the symbol during the week. (Tier 2 — SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | **Zero PnL adjustment** aggregated from **`Dealing_DailyZeroPnL_Stocks`** for the week — captures names **fully closed to zero** so WTD PnL is complete. (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

Authoritative column-level mapping and the full ETL chain are documented in **`Dealing_Apex_PnL.lineage.md`** (do not duplicate here). Summary:

- **External:** Apex LP files land in **`Dealing_staging.LP_APEX_EXT872_3EU_217314`** (trades/dividends) and **`LP_APEX_EXT982_3EU`** (NOP/holdings).
- **Internal:** **`PriceLog_History_CurrencyPrice`** supplies DB marks; **`Dealing_DailyZeroPnL_Stocks`** feeds **`Zero`**; **`DWH_dbo.Dim_Instrument`** resolves **`InstrumentID`**; **`DWH_dbo.Dim_Date`** supports calendar/holiday logic in the SP.
- **Writer:** **`Dealing_dbo.SP_Apex_PnL`** — **no Generic Pipeline** mapping; lineage is **LP external staging**, not a standard warehouse pipeline code path.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL_Daily`** | **Same SP** (`SP_Apex_PnL`), **same column layout** — **daily** grain (prior business day NOP vs week-start NOP). Use daily for **DOD** checks; use this table for **WTD**. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE`** | **Equity-level WTD** total for the Apex account (no symbol split); reconciles **account equity** vs this **per-symbol** roll-up. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Equity-level daily** counterpart (same SP family). |
| **`Dealing_dbo.Dealing_DailyZeroPnL_Stocks`** | **Source of `Zero`** column (sum over the week). |
| **`DWH_dbo.Dim_Instrument`** | **Instrument resolution** for `InstrumentID` / display name. |
| **`Dealing_staging.LP_APEX_EXT872_3EU_217314`** | Apex **activity** staging (trades/dividends). |
| **`Dealing_staging.LP_APEX_EXT982_3EU`** | Apex **position/NOP** staging. |

**Cross-check:** Summing **symbol-level `PnL`** across all symbols for a date should **approximate** **`Dealing_Apex_PnL_EE.PnL`** after **transfers and presentation differences** — investigate gaps with Middle Office.

## 7. Sample Queries

**Latest available WTD snapshot (stale-aware):**

```sql
SELECT MAX(Date) AS LastReportDate, MAX(UpdateDate) AS LastLoad
FROM Dealing_dbo.Dealing_Apex_PnL;
```

**Single week, single account — symbol-level PnL vs DB-priced PnL:**

```sql
SELECT Symbol, InstrumentID, PnL, PnL_DBPrice,
       PnL - PnL_DBPrice AS PnL_VsDB_MarkDiff
FROM Dealing_dbo.Dealing_Apex_PnL
WHERE Date = '2024-06-07'
  AND AccountNumber = @AccountNumber
ORDER BY ABS(PnL - PnL_DBPrice) DESC;
```

**Attach instrument attributes for matched rows:**

```sql
SELECT p.Date, p.Symbol, p.PnL, i.InstrumentDisplayName
FROM Dealing_dbo.Dealing_Apex_PnL AS p
LEFT JOIN DWH_dbo.Dim_Instrument AS i
  ON i.InstrumentID = p.InstrumentID
WHERE p.Date = @ReportDate
  AND p.AccountNumber = @AccountNumber;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL | Type: Table | Production Source: LP external data*
