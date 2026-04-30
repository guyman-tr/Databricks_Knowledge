MCP PRE-FLIGHT: PASS

Now let me read the required rule files and the previous attempt's output.
Now let me read the previous attempt's files to understand what needs to be fixed.
Good, I have the previous attempt and the judge's feedback. Now let me run the Phase 2 and Phase 3 queries.
Good - live data confirms the 8,400 max value. Now let me check the actual NewTrades_Total description in the WeeklyPanel wiki more carefully since the bundle was truncated.
Now I have the exact upstream description. Let me now proceed with the phases and write the corrected output. The key fixes from the judge:

1. **Week1** → Tier 1, quote: "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear."
2. **Year1** → Tier 1, quote: "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear."
3. **NewTrades** → Tier 1, quote: "Total positions opened across all instrument types during the week. SUM." + rename note. Remove AirDrop exclusion claim and range claim.
4. **FirstDayOfWeek** → Tier 1, quote: "Sunday date marking the start of the calendar week."
5. Flag row counts as estimates since DMV failed.

PHASE 1 CHECKPOINT: PASS (DDL from bundle)
PHASE 2 CHECKPOINT: PASS (live sample + aggregates)
PHASE 3 CHECKPOINT: PASS (no categorical columns match the regex — Status|Type|Code|Country|Region|Currency|Category — skipped per cap rule)

Now let me proceed through the remaining phase gates and write the corrected files.

PHASE GATE — BI_DB_dbo.BI_DB_PI_WeeklyTrades:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (no categorical columns match regex)
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing the three output files with corrections applied.
All three files written. Final checklist:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PI_WeeklyTrades:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_2/BI_DB_PI_WeeklyTrades.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_2/BI_DB_PI_WeeklyTrades.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_2/BI_DB_PI_WeeklyTrades.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 5    Tier2: 1    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**Changes from attempt 1 addressing all judge feedback:**

1. **Week1** → Re-tagged Tier 1, verbatim quote: "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear." Added rename note.
2. **Year1** → Re-tagged Tier 1, verbatim quote: "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear." Added rename note.
3. **NewTrades** → Re-tagged Tier 1, verbatim quote: "Total positions opened across all instrument types during the week. SUM." Added rename note (NewTrades_Total → NewTrades). Removed unverified AirDrop exclusion claim and "0-8400 range" claim from description.
4. **FirstDayOfWeek** → Re-tagged Tier 1, verbatim quote: "Sunday date marking the start of the calendar week."
5. **Section 1 & throughout** → Row counts and CID/week numbers flagged as estimates with "(estimates; DMV row count unavailable)" and "estimated" qualifiers.
6. **Footer** → Updated tier breakdown from "1 T1, 5 T2" to "5 T1, 1 T2".
7. **Lineage file** → Updated all four columns to Tier 1 with rename transforms noted.
