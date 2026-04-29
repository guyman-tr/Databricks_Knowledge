# Review Needed: Dealing_dbo.Dealing_HedgeCost

## Items Requiring Human Review

### 1. FullCommission Column Naming Mismatch
- The DDL column `FullCommission` is populated from `SUM(z.RealizedCommission)` from `Dealing_DailyZeroPnL_Stocks`, NOT from `Dim_Position.FullCommission`. The SP INSERT maps `f.RealizedCommission AS FullCommission`. This naming mismatch may confuse downstream consumers. Confirm if this is intentional or a bug.

### 2. Fact_CurrencyPriceWithSplit JOIN — No isvalid Filter
- The SP joins `Fact_CurrencyPriceWithSplit` on `OccurredDateID = @DateInt AND InstrumentID = f.InstrumentID` but does NOT filter `isvalid = 1`. This means the LEFT JOIN may match multiple price rows (valid + invalid) or pick an arbitrary row. The Fact_CurrencyPriceWithSplit wiki notes ~46% of rows are `isvalid=0`. Verify whether the JOIN consistently picks the correct price row.

### 3. LP HedgeServerID Mapping for 'Real' vs 'CFD'
- LP-side IsSettled uses a hardcoded list: `HedgeServerID IN (9,102,112,125,126) -> 'Real'`. Client-side uses `Dim_PositionChangeLog`. If new Real hedge servers are added (e.g., HedgeServerID=226 seen in recent data), the LP-side mapping would be wrong. Confirm if 226 is CFD or Real.

### 4. VariableSpread NULL Rate
- ~29% of 2026 rows have NULL VariableSpread. This means the LEFT JOIN to BI_DB_VarCommission found no match. Verify whether this is expected (some instruments/hedge servers not covered by VarCommission) or indicates a data quality issue.

### 5. No Reader SPs Found
- No downstream stored procedures were identified that read from this table. The DailyZeroPnL_Stocks wiki lists this as a downstream, but as a source relationship, not a reader. Confirm if any reports or dashboards consume this table directly.

---

*Generated: 2026-04-28*
