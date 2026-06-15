# DDR Synapse↔Databricks divergence — forensic root-cause report
**Date:** 2026-06-14
**Probe DateID:** 20260613
**Files inspected:** Synapse `SP_DDR_Fact_*` (live via `sys.sql_modules`) + DBX `main.de_output.sp_ddr_fact_*` and their TVFs/views.

---

## TL;DR — three real bugs + one pipeline lag

| # | Table | Symptom | Root cause | Class |
|---|---|---|---|---|
| 1 | **Fact_AUM** | OptionsTotalEquity = 0 for current date; ~8k "ghost rows" in yesterday's partition | `tvf_ddr_fact_aum` FULL-OUTER-JOINs Options on `CID AND DateID`; Options lags 1 day so the equality is never true | **DBX logic bug** |
| 2 | **Fact_Revenue_Generating_Actions** | `CryptoToFiatFee` = 0 rows in DBX vs. 45/$42.72 in Synapse | The lake table `gold_..._exw_c2f_e2e` is **1 day behind** | **Pipeline lag (mirror)** |
| 3 | **Fact_Revenue_Generating_Actions** | `ConversionFee` -1,612 rows | DBX `v_ddr_revenues` only sets `d_IsRecurring` for `ConversionFeeDeposit`, drops the dimension for Withdraw/Reversal | **DBX logic bug** |
| 4 | **Fact_Revenue_Generating_Actions** | Metric `TicketFeeByPercent` missing in DBX (label changed to `TicketFee`) | DBX `v_ddr_revenues` collapses `v.TicketFeeOpen + v.TicketFeeClose` into a single `TicketFee` metric — Synapse has two distinct functions | **DBX logic bug** |
| 5 | **Fact_PnL** | -995 rows (0.02%) | Different `GROUP BY` granularity in `tvf_pnl_single_day` vs `Function_PnL_Single_Day` (NULL handling on close-then-reopen positions). Options is **NOT** the cause — neither system includes Options in PnL. | DBX TVF minor diff |
| 6 | **Fact_Trading_Volumes** | NetInvestedAmount delta | Acknowledged by user as "by design" — not investigated further | n/a |

---

## 1. Fact_AUM — Options never attaches (DBX TVF bug)

### What Synapse does
```sql
-- BI_DB_dbo.SP_DDR_Fact_AUM
DECLARE @OptionsMaxDate DATE = (SELECT max(cast(ProcessDate as DATE))
    FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT981_BuyPowerSummary);
DECLARE @OptionsMaxDateID INT = ...;

CREATE TABLE #OptionsBalance AS
SELECT ... FROM BI_DB_dbo.Function_AUM_OptionsPlatform(@OptionsMaxDateID, 0);

-- #equityPrep — note the join is CID-only:
FROM #ClientBalance cb
LEFT JOIN #vl       vl ON cb.CID = vl.CID
FULL OUTER JOIN #IBANbalance i   ON cb.CID = i.CID
FULL OUTER JOIN #OptionsBalance ob ON COALESCE(cb.CID, i.CID) = ob.RealCID   -- ← CID ONLY

-- Final SELECT hardcodes the DateID:
SELECT @dateID AS DateID, ...               -- ← always the run-date
FROM #final f
WHERE NOT (f.EquityGlobal = 0) ...
```

Two design decisions:
- (a) Options is joined to TP rows **on CID only** — DateID is not part of the predicate.
- (b) The output `DateID` is **forced to `@dateID`** (e.g. 20260613) regardless of whether the source row originated from yesterday's Options snapshot.

### What DBX does (the bug)
```sql
-- main.etoro_kpi_prep.tvf_ddr_fact_aum
opts_max_date AS (
    SELECT MAX(DateID) FROM main.etoro_kpi_prep.v_options_aum WHERE DateID <= p_dateID
),
opts AS (
    SELECT o.DateID, xw.cid, o.OptionsTotalEquity, o.OptionsCashEquity
    FROM v_options_aum o
    JOIN opts_max_date omd ON o.DateID = omd.max_opts_dateID
    JOIN v_dim_dataplatform_uuid xw ON o.GCID = xw.gcid
),

equity_prep AS (
    SELECT
        COALESCE(cb.DateID, iban.DateID, opts.DateID) AS DateID,          -- ⚠ row-level
        COALESCE(cb.CID, iban.CID, opts.CID) AS CID,
        ...
    FROM cb
    LEFT JOIN vl   ON cb.CID = vl.CID AND cb.DateID = vl.DateID
    FULL OUTER JOIN iban ON cb.CID = iban.CID AND cb.DateID = iban.DateID
    FULL OUTER JOIN opts
        ON COALESCE(cb.CID, iban.CID) = opts.CID
        AND COALESCE(cb.DateID, iban.DateID) = opts.DateID                  -- ⚠ never matches
)
```

### Why nothing attaches
- `cb.DateID = 20260613` (today's TP snapshot).
- `opts.DateID = 20260612` (latest Options snapshot — confirmed: `SELECT MAX(DateID) FROM v_options_aum` → 20260612).
- `cb.DateID = opts.DateID` → **always false** → `opts.*` side becomes NULL → `OptionsTotalEquity` always coalesces to 0 for any CID present in `cb` or `iban`.

### Why ghost rows appear
- For CIDs present **only** in Options (no `cb`, no `iban`), the FULL OUTER JOIN produces a row with `cb.DateID = NULL, iban.DateID = NULL, opts.DateID = 20260612`.
- `COALESCE(...) AS DateID` → **20260612**, not 20260613.
- The SP's `DELETE WHERE DateID = p_dateID` only deletes 20260613 → these ghost rows survive in **yesterday's partition** and accumulate every run.

**Confirmed empirically** for DateID 20260613 run:
```
DateID   rows    cids   sum(OptionsTotalEquity)
20260611 16060   8030   $8,787,248
20260612 24108   8050   $13,511,596
20260613 ----   ----   $0          ← what we observed
```

### Patch
In `tvf_ddr_fact_aum`:

```sql
-- 1. Force DateID to run-date (drop COALESCE on DateID)
SELECT
    p_dateID AS DateID,
    COALESCE(cb.CID, iban.CID, opts.CID) AS CID,
    ...

-- 2. Drop the DateID equality on the opts join
FULL OUTER JOIN opts
    ON COALESCE(cb.CID, iban.CID) = opts.CID
   -- (no DateID predicate — opts is the "latest snapshot" by design)
```

Also recommend the same `p_dateID AS DateID` simplification on the iban and vl joins (Synapse already does this) — that closes the `~225 CID daily-status drift` reported earlier.

---

## 2. Fact_Revenue — `CryptoToFiatFee` is **not a bug**, it's a mirror lag

### What Synapse sees
```sql
SELECT COUNT(*), COUNT(DISTINCT RealCID), SUM(TotalFeeUSD), MIN(LastModificationDateID), MAX(LastModificationDateID)
FROM BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F(20260613, 20260613, 0);
-- → 45 rows, 40 CIDs, $42.72, [20260613, 20260613]
```

### What DBX sees
```sql
SELECT COUNT(*), SUM(TotalFeeUSD)
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
WHERE ConversionCycle = 'Full Cycle'
  AND CAST(DATE_FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime,
       ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT) = 20260613;
-- → 0 rows
```

But the upstream lake mirror only has data **up to 06-12**:
```
MIN(LastModificationDate) = 2026-06-10
MAX(LastModificationDate) = 2026-06-12     ← yesterday, not today
rows_in_range = 218 (203 'Full Cycle')
```

### Conclusion
`main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` is the lake mirror of Synapse's `EXW_dbo.EXW_C2F_E2E`. It lags **1 day** behind Synapse. The DBX SP can only "see what the lake mirrors". Rerunning the SP today produces 0 C2F rows for today's date by definition.

### Fix options (pick one)
- **(a) Wait for catch-up + re-run** — easiest. Once the EXW_C2F_E2E mirror catches up to 06-13, the SP will pick up its 45 rows on the next run.
- **(b) Investigate the mirror's daily cadence** — same pipeline pattern almost certainly affects Options (Apex SOD recon, item 1's `External_Sodreconciliation_apex_EXT981_BuyPowerSummary` → `v_options_aum`) which we already proved lags 1 day. Find the owner of the EXW + Apex generic mirror jobs; align cadence to TP cb/iban.
- **(c) Read directly from Synapse** — not recommended; defeats the whole UC migration.

---

## 3. Fact_Revenue — ConversionFee row gap (-1,612 rows): granularity bug

### Synapse
```sql
SELECT ..., ISNULL(frcf.IsRecurring,0) AS IsRecurring
FROM Function_Revenue_ConversionFee(@dateID, @dateID, 0) frcf
GROUP BY DateID, CID, TransactionType, ISNULL(frcf.IsRecurring,0);
--                                     ^ IsRecurring split for ALL three transaction types
```

### DBX `v_ddr_revenues.dimensioned`
```sql
CASE WHEN MetricName IN (..., 'ConversionFeeDeposit') THEN IsRecurring END AS d_IsRecurring,
--                       ^ ONLY Deposit. Withdraw + Reversal collapse to NULL → fewer groups.
```

ConversionFeeWithdraw and ConversionFeeReversal lose their IsRecurring split, collapsing rows that Synapse keeps separate.

### Patch (DBX)
```sql
CASE WHEN MetricName IN (
    'FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee',
    'AdminFee','SpotPriceAdjustment',
    'ConversionFeeDeposit','ConversionFeeWithdraw','ConversionFeeReversal'   -- ADD these
) THEN IsRecurring END AS d_IsRecurring
```

(Or, equivalently, drop IsRecurring split for ConversionFeeDeposit in Synapse if that's the intended canonical behavior — but DBX side is cheaper to change.)

---

## 4. Fact_Revenue — TicketFee vs TicketFeeByPercent: information loss

### Synapse (two streams)
```sql
-- Function_Revenue_TicketFee → 'TicketFee' metric (fixed-per-trade variant)
FROM BI_DB_dbo.Function_Revenue_TicketFee(@dateID, @dateID, 0)

-- Function_Revenue_TicketFeeByPercent → 'TicketFeeByPercent' metric (percentage variant)
FROM BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@dateID, @dateID, 0)
```
Two physically distinct revenue components, two metric labels.

### DBX `v_ddr_revenues.base` (single stream, mislabeled)
```sql
v.TicketFeeOpen + v.TicketFeeClose AS TicketFee     -- collapsed into one
...
'TicketFee', CASE WHEN b.ActionTypeID = 35 AND b.IsFeeDividend = 4
                  THEN CAST(b.TicketFee AS DOUBLE) END,
```

For 20260613 the DBX `TicketFee` (11,247 rows / $93,530.33) **exactly equals** Synapse's `TicketFeeByPercent` (same numbers). So the DBX label `TicketFee` is actually the **percentage** variant. The Synapse `TicketFee` (fixed-fee) row set isn't represented in DBX at all on this date.

### Patch (DBX)
Option A — rename + add the missing stream (preferred):
1. In `v_ddr_revenues.base`, split: `v.TicketFeeOpen + v.TicketFeeClose AS TicketFeeByPercent`.
2. Find the fixed-per-trade column in `v_fact_customeraction_w_metrics` (the equivalent of what `Function_Revenue_TicketFee` returns) and add it as a separate `TicketFee` metric.
3. Update the STACK array to emit both metrics.

Option B (less ideal) — collapse Synapse `TicketFee` and `TicketFeeByPercent` into a single `TicketFee` metric on the Synapse side. Loses an analytic dimension.

The right path depends on whether downstream consumers (dashboards, KPIs) reference `TicketFeeByPercent` separately. If yes → A. If no → either.

---

## 5. Fact_PnL — confirmed Options is **not** the cause

Both stored procedures source from `Function_PnL_Single_Day` / `tvf_pnl_single_day`, **both of which pull only Trading Platform PnL** (`BI_DB_PositionPnL` / `bdppl`) — Options PnL is not included in either system.

- Synapse `count(frfc.PositionID)` vs DBX `COUNT(DISTINCT pnl.PositionID)` → affects `CountPositions` only, not row count.
- The -995 row difference comes from DBX's `FINAL` CTE GROUP BY (`DateID, CID, PositionID, InstrumentID, MirrorID, Leverage, IsBuy, IsSettled, HedgeServerID, SettlementTypeID, ClosedOnDate, IsFuture, IsCopyFund, IsMarginTrade`) — this collapses some duplicate positions that Synapse's `Function_PnL_Single_Day` keeps separate. Likely NULL handling on close-then-reopen rows or settlement-type transitions.
- Magnitude: 995 / 4.6M = 0.02% — acceptable. Defer unless a specific KPI depends on it.

---

## Recommended remediation order

1. **AUM TVF fix** (item 1) — highest impact, biggest data gap, fix is 3 lines of SQL. Patch `main.etoro_kpi_prep.tvf_ddr_fact_aum`.
2. **EXW + Apex mirror cadence** (item 2 + bg fix for AUM) — wider issue: any DBX SP that depends on a lagging mirror will keep showing 0 today and "self-heal" tomorrow when the mirror catches up. Talk to data platform.
3. **ConversionFee granularity** (item 3) — 1-line view patch in `v_ddr_revenues`.
4. **TicketFee split** (item 4) — needs a decision: split into 2 metrics or accept the merge. Then patch view.
5. **PnL granularity** (item 5) — optional cleanup; small.

---

## Files & lineage of evidence
- Synapse SP bodies — `sys.sql_modules` (read at 2026-06-14T15:00Z).
- DBX SP bodies — `system.information_schema.routines` (read at 2026-06-14T15:00Z).
- DBX TVF/view bodies — `DESCRIBE FUNCTION EXTENDED` / `SHOW CREATE TABLE`.
- Source-table probe — `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e`, `main.etoro_kpi_prep.v_options_aum`.
- Fact target table probe — `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` (ghost-row inventory).
