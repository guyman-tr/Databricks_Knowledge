# BI_DB_CopyMilestone — Review Needed

**Generated**: 2026-04-23  
**Reviewer**: BI / PI Analytics team  

---

## Issues Requiring Human Review

### 1. `Up5Percent30Days` / `Down5Percent30Days` use monthly Gain_m, not 30-day rolling return
**Severity**: Low (naming confusion, no data correctness issue)  
The column names suggest a trailing 30-day window, but the SP uses `DWH_GainDaily.Gain_m` (month-to-date gain from the 1st of the current month). The effective window shortens at the start of a month (e.g., on April 2 it covers only 1 day, not 30). Consumers using these flags as "30-day" performance indicators may be misled.  
**Recommended action**: Confirm with the PI Analytics team whether this is intentional (MTD is the intended definition) or a bug (a trailing 30-day window was intended).

### 2. Historical high-water mark logic prevents re-triggering of crossing flags
**Severity**: Low (by-design risk)  
The `PI_Passing_*` and `CopyPortfolio_Passing_*` flags fire only when a PI's copier count enters a threshold band for the first time vs. all historical prior rows. A PI who peaked at 1,200 copiers (triggering `PI_Passing_1000_Copiers`), then dropped to 500, then recovered to 1,100 will NOT trigger `PI_Passing_1000_Copiers` again. Consumers expecting the flag to fire on all copier threshold crossings (not just the historical first) should join directly to `BI_DB_CopyDailyData` for yesterday/today deltas.  
**Recommended action**: Document this one-directional milestone logic in any dashboard using these flags.

### 3. `PI_Passing_1500_Copiers`, `PI_Passing_2500_Copiers`, `PI_Passing_3500_Copiers` are nullable while original thresholds are NOT NULL
**Severity**: Low (schema inconsistency)  
The three intermediate-band thresholds (1.5K, 2.5K, 3.5K) were added as nullable columns after the initial table design. Their NOT NULL counterparts (1K, 2K, 3K, 4K) default to 0 via `ISNULL()` in the SP, but the later additions are inserted as returned (NULL when the CID has no 7-day-ago record). Analytics comparing across thresholds should use `ISNULL(PI_Passing_1500_Copiers, 0)`.

### 4. `DWH_GainDaily` has no wiki — streak logic is opaque
**Severity**: Low (documentation gap)  
The streak calculations (Months6InRow, Month12InRow, Year3/4/5InRow) depend entirely on `BI_DB_dbo.DWH_GainDaily.Gain_m` and `Gain_y`. These metrics are not yet documented. The exact definitions of Gain_m and Gain_y (monthly return calculation methodology) should be confirmed with the Data Engineering team before trusting the streak flags for compliance or client reporting.
