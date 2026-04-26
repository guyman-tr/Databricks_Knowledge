# Review Needed: BI_DB_US_Stocks_MAU_DAU_KPI

**Batch:** 36  
**Date:** 2026-04-22  
**Confidence:** High overall; one historical break to flag.

## Items for Review

### 1. RegulationID 7 added 2022-09-15 — time series break (HIGH visibility)
- **Claim**: Before 2022-09-15, CryptoPotential only counted NYDFS (RegulationID=8) customers. After this date, NFA (RegulationID=7) customers were added. This creates a ~100K+ step change in CryptoPotential.
- **Evidence**: SP changelog: "Regulation 7 was added, Monthly Logic was fixed" on 2022-09-15.
- **Action**: Any trend analysis of CryptoPotential spanning September 2022 must account for this definitional change. Consider adding a data annotation in dashboards that use this metric. StocksPotential is not affected (always RegulationID=8 only).

### 2. Monthly_* metrics are cumulative within the month (CLARIFY for consumers)
- **Claim**: Monthly_RealStocks_Activity on the 15th reflects customers active from the 1st through the 15th. It does NOT reflect the final monthly MAU until month-end.
- **Action**: Confirm with dashboard consumers that they are taking the last row per month for MAU reporting. Pulling any mid-month row as "the monthly MAU" will understate the final figure.

### 3. "Activity" definition includes positions closed on @Date (LOW risk, document only)
- **Claim**: A customer with a position opened in January and closed on @Date counts as "active" on @Date via `CloseDateID=@DateID`. This is a legitimate design choice but may differ from some teams' intuition of "active = opened today".
- **Action**: No change needed — the definition is consistent with "any trading action" on the day. Confirm this is the intended definition with the US KPIs team.

### 4. HEAP index — no clustered index (INFO)
- **Observation**: The table uses HEAP (no clustered index). This is unusual for BI_DB tables and makes full-table scans the access pattern.
- **Impact**: With only ~1,600 rows, performance is not a concern. No action needed.
