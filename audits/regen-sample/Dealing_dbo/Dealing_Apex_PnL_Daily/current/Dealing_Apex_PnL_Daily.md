# Dealing_dbo.Dealing_Apex_PnL_Daily

> Daily grain Apex Clearing LP PnL by instrument for Middle Office reconciliation (prior business day NOP to current day NOP); **same writer as WTD** — **data stale since June 2024**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Same as `Dealing_Apex_PnL` — Apex LP staging **`LP_APEX_EXT872_3EU_217314`** + **`LP_APEX_EXT982_3EU`**, internal **`PriceLog_History_CurrencyPrice`**, **`Dealing_DailyZeroPnL_Stocks`**, **`DWH_dbo.Dim_Instrument`** |
| **Refresh** | Daily (within `SP_Apex_PnL` daily logic path; WTD and equity tables loaded in the same SP run) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last pipeline update **2024-06-08 09:19**. Like the WTD table, this object is **frozen in time** for operational use unless the Apex feed and `SP_Apex_PnL` job are restored.

**Daily grain:** One row per **`(Date, AccountNumber, Symbol)`** for **one trading day’s** PnL bridge. Whereas **`Dealing_Apex_PnL`** uses **week-start NOP** (Friday prior), this table uses **previous business day NOP** as **`NOP_Start`** (the SP **skips weekends** — e.g. Monday’s **`NOP_Start`** reflects **Friday’s** close). Middle Office uses it for **day-over-day** reconciliation against Apex activity and marks.

**Business question:** **What was the daily PnL on each Apex-held symbol** using the same PnL bridge formula as WTD, but with **one-day** trade/dividend/fee windows?

**Operational context & freshness:** Written by **`Dealing_dbo.SP_Apex_PnL`** alongside **`Dealing_Apex_PnL`**, **`Dealing_Apex_PnL_EE`**, and **`Dealing_Apex_PnL_EE_Daily`**. **Phase 2** sampling confirmed **stale** data. Historical volume **~1.655M rows** with date range **2022-07-06 → 2024-06-07** (shorter history than WTD, which starts **2021-02-10** — implies daily path was introduced or backfilled later).

**Reconciliation:** Compare **`PnL`** (Apex marks) vs **`PnL_DBPrice`** (internal DB marks) the same way as the WTD table.

## 2. Business Logic

**Daily PnL formula** (same algebraic form as WTD; **NOP_Start** semantics differ):

```
PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees
PnL_DBPrice = NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees
```

- **`NOP_Start`:** **Prior business day EOD** NOP at **Apex** price (not last Friday unless the prior day was Friday).
- **`NOP_End`:** **This `Date` EOD** NOP at Apex.
- **`Trades` / `Dividends` / `AdditionalFees` / `Volume`:** **Intraday / daily** windows from Apex files (not week aggregates).
- **`Zero`:** **Daily** zero adjustment — positions **fully closed on this day**.

**Weekend rule:** On **Monday**, **`NOP_Start`** aligns to **Friday EOD** (no Saturday/Sunday NOP in the bridge).

**Aggregation intuition:** Summing **`Dealing_Apex_PnL_Daily.PnL`** across **weekdays in a week** should **approximately** match **`Dealing_Apex_PnL.PnL`** for the **same week-ending `Date`**; small differences may arise from **rounding**, **holiday calendars**, or **edge cases** — validate with Middle Office for official sign-off.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Distribution / index** | **ROUND_ROBIN**; **clustered on `Date`** — **filter `Date`** (or small ranges) in all queries. |
| **WTD vs daily** | Use **`Dealing_Apex_PnL_Daily`** for **DOD**; use **`Dealing_Apex_PnL`** for **WTD** packs. |
| **Monday rows** | Expect **`NOP_Start`** to reflect **Friday** — do not assume “yesterday” is calendar yesterday. |
| **Scale** | **~1.65M rows** — moderate; still avoid unbounded scans. |
| **Instrument join** | **`LEFT JOIN DWH_dbo.Dim_Instrument`** on **`InstrumentID`**; allow **NULLs** for unmatched Apex symbols. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** for the row — **one trading day** per **`AccountNumber` + `Symbol`**; not necessarily a Saturday (unlike WTD header date semantics). (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex LP account** identifier — same meaning as WTD table. (Tier 2 — SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | **Apex-reported symbol**; joins to **`DWH_dbo.Dim_Instrument`** via **`InstrumentID`** when matched. (Tier 2 — SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | **NOP at prior business day EOD**, **Apex price** — **Monday rows use Friday** as prior business day. (Tier 2 — SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | **Prior-day NOP** using **eToro DB** marks — pairs with `NOP_Start` for mark reconciliation. (Tier 2 — SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | **NOP at this day’s market close**, **Apex price**. (Tier 2 — SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | **Same-day NOP** using **eToro DB** bid × qty. (Tier 2 — SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | **Net trade notional for this day only** from Apex activity. (Tier 2 — SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | **Dividends credited on this day** for the symbol. (Tier 2 — SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | **Daily PnL (Apex marks):** `NOP_End - NOP_Start - Trades + Dividends + AdditionalFees`. (Tier 2 — SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | **Daily PnL** using **DB-priced NOP** start/end — isolate internal vs Apex mark variance. (Tier 2 — SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | **ETL row timestamp** from **`GETDATE()`** in `SP_Apex_PnL`. (Tier 2 — SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | **Resolved instrument key**; **NULL** when Apex identifiers do not map to **`Dim_Instrument`**. (Tier 2 — SP_Apex_PnL) |
| 14 | InstrumentDisplayName | varchar(100) | YES | **eToro-facing instrument name** for reporting. (Tier 2 — SP_Apex_PnL) |
| 15 | Price_Start | decimal(16,6) | YES | **Apex close** at **prior business day** (start mark for the daily bridge). (Tier 2 — SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | **eToro DB bid** at prior business day. (Tier 2 — SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | **Apex close** on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | **eToro DB bid** on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | **Fees/adjustments for the day** included in the PnL bridge. (Tier 2 — SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | **Traded units** for the symbol on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | **Daily zero PnL adjustment** for names **closed to zero on this day** (from **`Dealing_DailyZeroPnL_Stocks`** path in SP). (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

See **`Dealing_Apex_PnL_Daily.lineage.md`**. **Summary:** Same **Apex staging** inputs and **`SP_Apex_PnL`** writer as **`Dealing_Apex_PnL`**. The SP uses **daily temp pipelines** (e.g. **`#NOP_Daily`**, **`#Trades_ApexFiles_Daily`**) for **prior-day** NOP and **daily** activity instead of **WTD** aggregates. **Column mapping** is **parallel** to the WTD table; only **windowing** differs.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL`** | **WTD** sibling — **same columns**, **week-start NOP** logic; primary alternative grain for **weekly** packs. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Equity-level daily** from the same SP — use when **account totals** are needed without symbol detail. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE`** | **Equity WTD** — ties **account-level** to **symbol roll-ups** over a week. |
| **`Dealing_dbo.Dealing_DailyZeroPnL_Stocks`** | Feeds **`Zero`** at **daily** resolution. |
| **`DWH_dbo.Dim_Instrument`** | Instrument attributes for matched **`InstrumentID`**. |
| **Apex staging tables** | Same as WTD — **`LP_APEX_EXT872_3EU_217314`**, **`LP_APEX_EXT982_3EU`**. |

## 7. Sample Queries

**Confirm daily history depth vs WTD:**

```sql
SELECT 'Daily' AS tbl, MIN(Date) AS min_d, MAX(Date) AS max_d, COUNT(*) AS rows
FROM Dealing_dbo.Dealing_Apex_PnL_Daily
UNION ALL
SELECT 'WTD', MIN(Date), MAX(Date), COUNT(*)
FROM Dealing_dbo.Dealing_Apex_PnL;
```

**Day-over-day PnL for one symbol:**

```sql
SELECT Date, PnL, PnL_DBPrice, NOP_Start, NOP_End, Trades, Dividends, Zero
FROM Dealing_dbo.Dealing_Apex_PnL_Daily
WHERE AccountNumber = @AccountNumber
  AND Symbol = @Symbol
  AND Date BETWEEN @From AND @To
ORDER BY Date;
```

**Rough weekly check: sum of daily vs WTD row**

```sql
-- Sum daily PnL for US equity week Mon-Fri ending Saturday report date @WeekEnd
SELECT SUM(d.PnL) AS SumDailyPnL
FROM Dealing_dbo.Dealing_Apex_PnL_Daily AS d
WHERE d.AccountNumber = @AccountNumber
  AND d.Symbol = @Symbol
  AND d.Date > DATEADD(DAY, -7, @WeekEnd)
  AND d.Date <= @WeekEnd;

SELECT w.PnL AS WtdPnL
FROM Dealing_dbo.Dealing_Apex_PnL AS w
WHERE w.AccountNumber = @AccountNumber
  AND w.Symbol = @Symbol
  AND w.Date = @WeekEnd;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL_Daily | Type: Table | Production Source: LP external data*
