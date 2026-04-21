---
object: eMoney_Panel_Retention_Monthly
schema: eMoney_dbo
type: Table
lineage_version: 1
generated: "2026-04-20"
---

# Column Lineage — eMoney_Panel_Retention_Monthly

## §1 Source Objects

Same source objects as `eMoney_Panel_Retention_Daily` — this table is rebuilt from Daily at the end of each SP run.

| Alias | Object | Role |
|-------|--------|------|
| Daily | eMoney_dbo.eMoney_Panel_Retention_Daily | Direct source; EOM rows selected per month |
| #RelDays | SP temp table | GROUP BY year*100+month, EOM_Date; provides the end-of-month date for each year-month |

Upstream sources for all metric columns are identical to Daily — see `eMoney_Panel_Retention_Daily.lineage.md` §1.

## §2 ETL Pattern

- Writer SP: `SP_eMoney_Panel_Retention` (same SP as Daily)
- Pattern: TRUNCATE + full rebuild after Daily WHILE loop completes
- Source: `eMoney_Panel_Retention_Daily`
- `#RelDays`: `SELECT year(Report_Date)*100+month(Report_Date) AS YearMonth, MAX(Report_Date) AS EOM_Date FROM eMoney_Panel_Retention_Daily GROUP BY year(Report_Date)*100+month(Report_Date)`
- `#FinalMonthly`: `eMoney_Panel_Retention_Daily JOIN #RelDays ON Report_Date = EOM_Date`
- INSERT: `Report_Month = #RelDays.YearMonth`, `Date_for_Report = Report_Date`, all other columns passthrough from Daily

## §3 Column-Level Lineage

Columns 3–86 are identical to `eMoney_Panel_Retention_Daily` columns 3–86 (GCID through UpdateDate).

| # | Column | Source Object | Source Column / Expression | Tier |
|---|--------|--------------|---------------------------|------|
| 1 | Report_Month | SP computed | year(Report_Date)*100+month(Report_Date) from #RelDays | Tier 2 |
| 2 | Date_for_Report | eMoney_Panel_Retention_Daily | Report_Date (the EOM date = MAX(Report_Date) per calendar month) | Tier 2 |
| 3–86 | (all remaining) | eMoney_Panel_Retention_Daily | Passthrough from Daily EOM row | Tier 2 |

For full column-level lineage of columns 3–86, see `eMoney_Panel_Retention_Daily.lineage.md` §3 (rows 3–86, offset by +0 ordinal position for GCID onwards).

## §4 Tier 1 Coverage Summary

- Tier 1: 0 (same as Daily — DWH-native analytics table)
- Tier 2: 86 columns (SP-computed or passthrough from Daily)

## §5 UC External Lineage

UC Target: `_Not_Migrated` (eMoney_dbo tables are Synapse-only)
