# DDR fact parity — Synapse PROD vs Databricks UC — DateID = 20260526

**Run:** 2026-05-28 05:00 UTC
**Side A:** `sql_dp_prod_we.BI_DB_dbo.*`
**Side B:** `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_*`

---

## 1. Headline counts

| Table | Syn rows | DBX rows | Δ rows | Δ % | Syn distinct CID | DBX distinct CID | Δ CID | Verdict |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `BI_DB_DDR_Fact_AUM` | 4,520,965 | 4,520,971 | +6 | +0.00013% | 4,520,965 | 4,520,971 | +6 | ✅ match |
| `BI_DB_DDR_Fact_PnL` | 4,649,417 | 4,648,416 | -1,001 | -0.02% | 2,754,051 | 2,754,051 | 0 | ✅ match (timing) |
| `BI_DB_DDR_Fact_MIMO_AllPlatforms` | 188,349 | 188,607 | +258 | +0.14% | 34,967 | 35,021 | +54 | ✅ match (timing) |
| `BI_DB_DDR_Fact_Revenue_Generating_Actions` | 1,380,230 | 1,374,308 | **-5,922** | -0.43% | 371,981 | 374,029 | **+2,048** | ⚠ structural diff |
| `BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` | 315,137 | 377,105 | **+61,968** | +19.66% | 209,521 | 209,521 | 0 | ⚠ grain + sign flip |

---

## 2. `Revenue_Generating_Actions` — what's different

Total amount **agrees within $129** ($3,203,604.20 Syn vs $3,203,474.76 DBX, Δ = -0.004%), so the dollar reality is the same. The row-count and metric-count differences come from how the DBX side **buckets RevenueMetricID and ActionTypeID**:

| Difference | What | Synapse | DBX | Impact |
|---|---|---|---|---|
| **1** | `RevenueMetricID = 4` (TicketFeeByPercent) is **merged into Metric 3** (TicketFee) on DBX | 68,950 rows / $743,473.64 separate | merged: Metric 3 has 116,744 rows / $909,907.64 | Math reconciles exactly: $166,434 + $743,474 = $909,908 ≈ DBX Metric 3 |
| **2** | `RevenueMetricID = 11` (C2F) **missing on DBX** | 64 rows / $129.44 | (absent) | This is exactly the $129 total-sum gap |
| **3** | `RevenueMetricID = 15` (InterestFee) is **net-new on DBX** | (absent) | 3,319 rows, NULL Amount sum | New unmaterialized metric |
| **4** | `ActionType = Reversal` appears under Metric 10 on DBX | (absent) | 1 row, $0.00 | Net-new corner case |
| **5** | `ActionTypeID = -1` on Synapse → `NULL` on DBX (for the non-trade fee rows) | -1 sentinel | NULL | Cosmetic, but breaks `COUNT(DISTINCT ActionTypeID)` parity |
| **6** | Minor per-bucket row drift (e.g. Metric 1 ManualPositionClose: Syn 113,326 vs DBX 113,323) | — | — | ETL completion drift |

**Takeaway:** Money totals reconcile. The grain definition has diverged — DBX has consolidated TicketFee/TicketFeeByPercent and added InterestFee. **Anyone using `WHERE RevenueMetricID IN (3, 4)` on DBX will silently miss revenue** (because `4` doesn't exist there). And `RevenueMetricID = 15` (InterestFee) needs an owner before it's trusted.

---

## 3. `Trading_Volumes_And_Amounts` — what's different

This one is the real concern. Per instrument type:

| InstrumentTypeID | Δ rows | Syn VolumeOpen | DBX VolumeOpen | Syn InvestedOpen | DBX InvestedOpen | Syn InvestedClose | DBX InvestedClose | Syn NetInvested | DBX NetInvested |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | +157 | 84,068,972 | 84,069,283 | 2,642,998.06 | 2,642,998.06 | 2,646,476.67 | 2,656,512.25 | **-3,479** | **-13,514** |
| 2 | +685 | 625,842,670 | 625,842,900 | 44,404,179.78 | 44,422,226.70 | 43,497,653.96 | 44,181,374.34 | **906,526** | **240,852** |
| 4 | +2,612 | 515,791,664 | 515,803,775 | 26,316,607.25 | 26,320,357.13 | 26,740,446.38 | 26,586,377.51 | **-423,839** | **-266,020** |
| 5 | **+53,000** | 363,297,681 | 363,298,965 | 236,207,477.77 | 236,207,477.77 | 222,772,820.52 | 240,869,950.24 | **13,434,657** | **-4,662,472** ⚠ SIGN FLIP |
| 6 | +5,672 | 34,844,039 | 34,844,130 | 24,368,641.40 | 24,368,641.40 | 24,067,092.48 | 25,318,611.17 | **301,549** | **-949,970** ⚠ SIGN FLIP |
| 10 | -158 | 8,655,180 | 8,655,179 | 7,201,878.39 | 7,201,878.39 | 9,473,126.51 | 8,641,119.05 | **-2,271,248** | **-1,439,241** |

**Pattern:**
- `CountTotalTransactions` is **identical to the row** on both sides (2,850,049 each) — so the same business events are present.
- `VolumeOpen`, `VolumeClose`, `InvestedAmountOpen` are essentially identical (drift <0.001%).
- `InvestedAmountClosed` is **materially different** for InstType 5 (+$18.1M on DBX), InstType 6 (+$1.25M), InstType 10 (-$832K).
- `NetInvestedAmount` follows `Open - Close` on both sides — the formula isn't different, but because `InvestedAmountClosed` is wrong on DBX, the net sign flips for InstType 5 and InstType 6.

**Most likely root cause** (worth confirming with whoever owns the DBX materialization):
- Same set of business events, but DBX is **splitting them across finer grain rows** (61,968 extra rows; +25% on InstType 5 alone, +12% on InstType 6).
- The extra grain rows carry incremental `InvestedAmountClosed` values that don't exist on the Synapse side.
- One hypothesis: late-arriving close events that on the Synapse side are folded back into the original open's daily grain, but on DBX get their own row with the late-update close amount, double-booking the close.

**Impact:**
- Daily KPIs sourced from this table on DBX will report **negative net flows for stocks (InstType 5)** when Synapse reports +$13M positive. That's a real-world reporting divergence on a flagship instrument type.
- This is much bigger than the $129 in Revenue_Generating_Actions.

---

## 4. Recommended next steps

| Priority | Action | Owner |
|---|---|---|
| 1 | Flag `Trading_Volumes_And_Amounts` sign-flip for InstType 5/6 to whoever owns the DBX materialization (DDR team). Reproduce with a single-CID drill-down. | DDR / DE |
| 2 | Confirm whether `RevenueMetricID = 4` (TicketFeeByPercent) was intentionally merged into `3` on DBX. If yes — document it. If no — restore the grain. | Revenue domain |
| 3 | Trace `RevenueMetricID = 15` (InterestFee) — what's the source SP? Why is `Amount` NULL? | DDR / DE |
| 4 | Trace `RevenueMetricID = 11` (C2F) — why missing on DBX? | DDR / DE |
| 5 | Standardize `ActionTypeID = -1` ↔ `NULL` convention across Syn/DBX (probably should be NULL everywhere). | DDR / DE |
| 6 | The 3 timing-drift tables (AUM, PnL, MIMO) — no action needed beyond noting that the 8 hours of difference between the Synapse PROD load completion and the DBX gold materialization explains the <0.15% delta. | — |

---

## 5. Files

| File | Contents |
|---|---|
| `report.md` | This document |
| `counts.csv` | Row + CID counts per table per side |
| `revenue_generating_by_metric.csv` | Per-(RevenueMetricID, ActionType) breakdown both sides |
| `trading_volumes_by_instrument.csv` | Per-InstrumentTypeID breakdown both sides |
