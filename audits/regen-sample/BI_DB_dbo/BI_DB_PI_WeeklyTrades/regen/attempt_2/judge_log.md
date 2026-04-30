## Judge Review: BI_DB_dbo.BI_DB_PI_WeeklyTrades

### Per-Dimension Scores

**D1 — Tier Accuracy: 10/10**
Sampled 5 columns (CID, Week1, NewTrades, UpdateDate, FirstDayOfWeek). All tier assignments are correct: 5 passthroughs from BI_DB_CID_WeeklyPanel_FullData correctly tagged Tier 1 (CID traces to root origin Customer.CustomerStatic, consistent with sibling PI tables), UpdateDate correctly tagged Tier 2. Zero mismatches.

**D2 — Upstream Fidelity: 9/10**
All 5 Tier 1 columns preserve the upstream description verbatim or with minor factual additions. No vendor names, NULL semantics, or specific values were dropped. CID adds PI population filter context; Week1/Year1 add rename notes; NewTrades adds consumer context; FirstDayOfWeek adapts index advice to this table's structure. No semantic losses.

**D3 — Completeness: 8/10**
9 of 10 checklist items pass. All 8 sections present; 6/6 elements match DDL; all element rows have 5 cells with tier tags; property table complete; ETL pipeline diagram present with real names; footer has tier breakdown; review-needed sidecar clean of Elements. Row count is estimated with explicit DMV-denial caveat (partial credit). No applicable dictionary columns.

**D4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (PI weekly trade counts shadow cache), row grain (one PI per calendar week), the ETL SP and both data paths (new PI backfill + daily incremental), the downstream consumer (Avg_weekly_trades in PI Dashboard), date range, and population size. A brand-new analyst could immediately understand when and why to query this table.

**D5 — Data Evidence: 7/10**
Writer ran live aggregation queries to obtain distinct CID count (~4,419) and distinct week count (~225). Date range confirmed from live data. DMV row-count denial properly flagged in review-needed sidecar. Estimates are clearly labeled. No fabricated precision.

**D6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL samples in Section 7, footer with quality score and phases-completed list. Minor: no explicit Phase Gate Checklist section, but this is a formatting preference not a structural failure.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). HASH distribution key." | MINOR | Added PI filter and distribution key context; core verbatim preserved |
| Week1 | "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear." (WeeklyPanel.SSWeekNumberOfYear) | "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear. Renamed from SSWeekNumberOfYear." | YES | None — rename note is an addition |
| Year1 | "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear." (WeeklyPanel.CalendarYear) | "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear. Renamed from CalendarYear." | YES | None — rename note is an addition |
| NewTrades | "Total positions opened across all instrument types during the week. SUM." (WeeklyPanel.NewTrades_Total) | "Total positions opened across all instrument types during the week. SUM. Renamed from NewTrades_Total. Used to compute Avg_weekly_trades in the PI Dashboard via AVG(NewTrades) over the last 52 weeks." | MINOR | Added rename note and consumer context; upstream quote preserved verbatim |
| FirstDayOfWeek | "Sunday date marking the start of the calendar week. Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for week slices." (WeeklyPanel.FirstDayOfWeek) | "Sunday date marking the start of the calendar week. Used as DELETE+INSERT key for daily incremental refresh. Primary grain column alongside CID." | MINOR | "leading CLUSTERED INDEX key" dropped (appropriate — this table has different index); adapted to this table's ETL context |

### Top 5 Issues

1. **Severity: low | FirstDayOfWeek** — Description adapts upstream rather than quoting verbatim. "Leading CLUSTERED INDEX key. Always filter on this column for week slices" was replaced with this-table-specific DELETE+INSERT context. Acceptable adaptation but not strict verbatim.

2. **Severity: low | Section 1 row count** — Total row count is estimated (~724K) from distinct CID × distinct week multiplication, with DMV access denial properly flagged. Not a writer error but a data access limitation.

3. **Severity: low | Phase Gate** — No explicit Phase Gate Checklist section with P2/P3 checkboxes. Data evidence exists but is not formally structured as a checklist.

4. **Severity: low | CID description length** — CID description is verbose (adds PI population filter details and HASH distribution key beyond the upstream quote). Not a loss but adds bulk.

5. **Severity: info | Section 3.4 Week1 numbering** — Good call documenting that Week1 uses SQL Server week numbering (not ISO). This is valuable analyst context not obvious from the column name alone.

### Regeneration Feedback

No regeneration needed — wiki passes all quality gates.

Minor improvements if revisiting:
1. Quote FirstDayOfWeek upstream description verbatim, then add this-table context as a separate sentence
2. Add an explicit Phase Gate Checklist section documenting which data validation steps were completed vs skipped

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_WeeklyTrades",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). HASH distribution key.",
      "match": "MINOR",
      "loss": "Added PI filter and distribution key context; core description verbatim preserved"
    },
    {
      "column": "Week1",
      "upstream_quote": "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear.",
      "wiki_quote": "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear. Renamed from SSWeekNumberOfYear.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Year1",
      "upstream_quote": "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear.",
      "wiki_quote": "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear. Renamed from CalendarYear.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "NewTrades",
      "upstream_quote": "Total positions opened across all instrument types during the week. SUM.",
      "wiki_quote": "Total positions opened across all instrument types during the week. SUM. Renamed from NewTrades_Total. Used to compute Avg_weekly_trades in the PI Dashboard via AVG(NewTrades) over the last 52 weeks.",
      "match": "MINOR",
      "loss": "Added rename note and consumer context; upstream quote preserved verbatim"
    },
    {
      "column": "FirstDayOfWeek",
      "upstream_quote": "Sunday date marking the start of the calendar week. Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for week slices.",
      "wiki_quote": "Sunday date marking the start of the calendar week. Used as DELETE+INSERT key for daily incremental refresh. Primary grain column alongside CID.",
      "match": "MINOR",
      "loss": "Dropped 'leading CLUSTERED INDEX key' (appropriate — this table has different index); replaced with this-table-specific ETL context"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "FirstDayOfWeek",
      "problem": "Description adapts upstream rather than quoting verbatim — 'leading CLUSTERED INDEX key. Always filter on this column for week slices' replaced with DELETE+INSERT context. Acceptable adaptation but not strict verbatim."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Total row count is estimated (~724K from 3,220 × 225) due to DMV access denial. Properly flagged in review-needed sidecar but not a precise verified figure."
    },
    {
      "severity": "low",
      "column_or_section": "Shape",
      "problem": "No explicit Phase Gate Checklist section with P2/P3 checkboxes. Data evidence exists but is not formally structured."
    },
    {
      "severity": "low",
      "column_or_section": "CID",
      "problem": "Description adds 45 words beyond the upstream quote (PI population filter, HASH distribution key). Not a loss but adds bulk beyond verbatim requirement."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4",
      "problem": "Good documentation of Week1 SQL Server week numbering vs ISO — valuable analyst context correctly surfaced."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
