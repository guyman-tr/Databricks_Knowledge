# Review Needed — BI_DB_dbo.BI_DB_CashRiskMatrix

> Items requiring human or domain-expert review before this wiki can be marked VERIFIED.

---

## 1. TotalCash AVG Aggregation Semantics

**Column**: `TotalCash`

**Issue**: The SP uses `AVG(vl.TotalCash)` in the GROUP BY query that aggregates multiple positions per customer. While `AVG` of a constant (same TotalCash per CID per date) is mathematically equivalent to `MAX` or `MIN`, this aggregation choice is unusual and could produce unexpected results if V_Liabilities returns multiple rows per CID+DateID (e.g., if there are duplicate rows or if the date join is imprecise).

**Action needed**: Confirm whether V_Liabilities ever returns >1 row per CID+DateID and whether the AVG is truly safe, or if it should be MAX/MIN.

---

## 2. Scenario Column Interpretation — Stop vs Limit Logic

**Columns**: All `UnitsNOP+N%` and `UnitsNOP-N%` columns

**Issue**: The SP scenario logic uses **LimitRate** for buy-side upside and **StopRate** for buy-side downside, and vice versa for sell-side. This is consistent with standard TP/SL semantics. However, the "units triggered" interpretation is non-obvious:

- For upside buy scenarios, the column represents "units whose take-profit would fire" — these units would **close** if the price reached that level.
- For downside buy scenarios, the column represents "units whose stop-loss would fire" — these units would also close.

**Action needed**: Domain expert to confirm: does the Risk desk interpret these columns as "positions that would close" (reducing exposure) or "positions that survive the shock" (retained exposure)? The column name `UnitsNOP+N%` suggests the NOP surviving at that level, but the CASE logic suggests it is the NOP whose order fires. Clarify the intended interpretation.

---

## 3. NULL Bid/Ask/ConversionRate Rows

**Columns**: `Bid`, `Ask`, `ConversionRate`

**Issue**: 208 rows per day (production as of 2025-10-05) have NULL Bid, Ask, and ConversionRate. These are positions where `LEFT JOIN #Prices` found no matching price. The UnitsNOP and scenario columns for these rows still have values (position units), but USD conversion is impossible.

**Action needed**: Confirm how the Risk desk handles these rows in their reporting. Are they excluded, imputed, or flagged separately? Also, confirm whether the ~208 count is expected/acceptable or represents a data quality issue.

---

## 4. UC Registration Status

**Issue**: The table has no UC Target registered (`_Not yet registered_`). This means the BI_DB_CashRiskMatrix is not currently surfaced in Databricks Unity Catalog.

**Action needed**: Confirm whether this table should be registered in UC, and if so, what the target catalog/schema/table name should be, and whether it should be partitioned by Date.

---

## 5. Crypto Instruments Not in Scope

**Issue**: The SP filters `InstrumentID < 100000`. Live data confirms only ETF, Stocks, Currencies, Commodities, and Indices appear. No Crypto Currencies appear in this table. If crypto InstrumentIDs are ≥ 100000, this is by design. If not, it may be a gap.

**Action needed**: Confirm whether crypto instruments are intentionally excluded (their IDs are ≥ 100000) and whether this is the expected behavior for the risk matrix.

---

## 6. IsSettled=0 — Futures Exclusion Unclear

**Issue**: The SP filters `IsSettled=0` (CFD-only). Futures instruments (IsFuture=1 in Dim_Instrument) can be either settled or CFD. Live data shows no `Crypto Currencies` but also no explicit `Futures` InstrumentType in the data sample (they would appear as Commodities or other types with IsFuture=1).

**Action needed**: Confirm whether futures are included or excluded, and whether the `IsSettled=0` filter is sufficient to distinguish CFD futures from real-asset futures.
