I'll review the wiki systematically against the rubric. Let me first verify a few upstream wiki descriptions for the Tier 1 fidelity check.
Now let me check the NewTrades_Total column specifically in the WeeklyPanel wiki to see if it's documented.
Good - `NewTrades_Total` IS documented in the WeeklyPanel wiki. Now let me check the specific descriptions for SSWeekNumberOfYear, CalendarYear, FirstDayOfWeek in the WeeklyPanel wiki.
Now I have all the information needed to complete the review. Let me verify the upstream descriptions for the columns that should be Tier 1.
Now I have all the information I need. Here is my complete review.

---

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: **3/10**

I sampled all 6 columns (only 6 exist). Verified against SP code section 4.1:

| Column | SP Source | Upstream Wiki Present? | Should Be | Wiki Claims | Match? |
|--------|----------|----------------------|-----------|-------------|--------|
| CID | WeeklyPanel.CID | Yes (WeeklyPanel) | Tier 1 | Tier 1 — Customer.CustomerStatic | Acceptable (traced to root) |
| Week1 | WeeklyPanel.SSWeekNumberOfYear | Yes (WeeklyPanel #3) | Tier 1 | **Tier 2** | MISMATCH |
| Year1 | WeeklyPanel.CalendarYear | Yes (WeeklyPanel #4) | Tier 1 | **Tier 2** | MISMATCH |
| NewTrades | WeeklyPanel.NewTrades_Total | Yes (WeeklyPanel #64) | Tier 1 | **Tier 2** | MISMATCH |
| FirstDayOfWeek | WeeklyPanel.FirstDayOfWeek | Yes (WeeklyPanel #28) | Tier 1 | **Tier 2** | MISMATCH |
| UpdateDate | GETDATE() | N/A | Tier 2 | Tier 2 | OK |

4 mismatches out of 5 data columns. All passthrough columns from `BI_DB_CID_WeeklyPanel_FullData` (which has a wiki in the bundle) are tagged Tier 2 instead of Tier 1. The tier rules are clear: "Passthrough or rename WITH upstream wiki present → must be Tier 1."

### Dimension 2 — Upstream Fidelity: **3/10**

Only CID is tagged Tier 1.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer) | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). HASH distribution key." | MINOR | Additions (PI filter context, HASH key) but core verbatim. |

CID itself is acceptable. However, 4 columns that should be Tier 1 (Week1, Year1, NewTrades, FirstDayOfWeek) are tagged Tier 2, constituting 4 missed inheritances from the WeeklyPanel wiki which was available in the bundle. The upstream descriptions from the WeeklyPanel are:
- SSWeekNumberOfYear: "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear."
- CalendarYear: "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear."
- NewTrades_Total: "Total positions opened across all instrument types during the week. SUM."
- FirstDayOfWeek: "Sunday date marking the start of the calendar week. Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for week slices."

None of these were quoted. Score: 3 (wrong tier origin — relay-level source cited instead of documented upstream).

### Dimension 3 — Completeness: **10/10**

All 10 checklist items pass:
- [x] All 8 sections present
- [x] 6 elements match 6 DDL columns
- [x] Every element row has 5 cells
- [x] Every description ends with (Tier N — source)
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row estimate (~4,419 CIDs, 225 weeks, Dec 2019–Apr 2024)
- [x] No dictionary columns with ≤15 values applicable
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent: names domain (PI-specific shadow cache), row grain (one row per active PI/CopyFund per calendar week), ETL SP name, refresh pattern (delete-insert + backfill), estimated population (~4,419 CIDs), date range (Dec 2019–Apr 2024), consumer context (Avg_weekly_trades for PI Dashboard), and data staleness note. Only missing an exact total row count (DMV failed).

### Dimension 5 — Data Evidence: **5/10**

Row count estimate present (~724K estimated from ~3,220 rows/week × 225 weeks) but DMV query failed (review-needed confirms "permission denied"). NewTrades range "0 to 8,400 observed" suggests some data access. P2/P3 phase completion not explicitly marked in footer ("Phases: 11/14" without listing which). The "observed" ranges may or may not be from live queries — given DMV failure, some skepticism warranted.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7 (3 queries), footer with quality score and phases list. Minor deviation: tier legend uses simple table instead of stars convention.

---

## Weighted Total

```
weighted = 0.25×3 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×5 + 0.10×8
         = 0.75 + 0.60 + 2.00 + 1.35 + 0.50 + 0.80
         = 6.00
```

**Verdict: FAIL** (6.00 < 7.5)

---

## Top 5 Issues

1. **HIGH — Week1, Year1, NewTrades, FirstDayOfWeek all mistagged Tier 2**: These are direct passthroughs from `BI_DB_CID_WeeklyPanel_FullData`, which has a wiki in the bundle. They should be Tier 1 with verbatim upstream descriptions.

2. **HIGH — Upstream descriptions not quoted for 4 passthrough columns**: The WeeklyPanel wiki documents SSWeekNumberOfYear, CalendarYear, NewTrades_Total, and FirstDayOfWeek with specific descriptions. The writer paraphrased all four instead of quoting verbatim.

3. **MEDIUM — NewTrades description inaccurate**: Wiki says "Total number of new trades (positions opened) by this PI during the calendar week." The upstream WeeklyPanel says NewTrades_Total is "Total positions opened across all instrument types during the week. SUM." The wiki also claims "Includes manual and copy positions, excludes AirDrop" and "Range: 0 to 8,400 observed" — the WeeklyPanel wiki makes no such claims for NewTrades_Total specifically (that detail applies to the DailyPanel's ActiveOpen flag, not the trade count).

4. **MEDIUM — DMV row count failure not reflected in Section 1**: Section 1 confidently states "~4,419 distinct CIDs across 225 distinct weeks" but the review-needed sidecar admits the row count query failed. These numbers should be flagged as estimates.

5. **LOW — Footer tier counts inconsistent with actual tier assignments**: Footer claims "1 T1, 5 T2" but with correct tiering it should be "5 T1, 1 T2" (only UpdateDate is genuinely ETL-computed).

---

## Regeneration Feedback

1. Re-tag `Week1` as `(Tier 1 — BI_DB_CID_WeeklyPanel_FullData)` using the verbatim description from the WeeklyPanel wiki for SSWeekNumberOfYear: "SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear."
2. Re-tag `Year1` as `(Tier 1 — BI_DB_CID_WeeklyPanel_FullData)` using the verbatim description: "Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear."
3. Re-tag `NewTrades` as `(Tier 1 — BI_DB_CID_WeeklyPanel_FullData)` using the verbatim description: "Total positions opened across all instrument types during the week." Add the column rename note (NewTrades_Total → NewTrades).
4. Re-tag `FirstDayOfWeek` as `(Tier 1 — BI_DB_CID_WeeklyPanel_FullData)` using the verbatim description: "Sunday date marking the start of the calendar week."
5. Flag row count and distinct CID/week numbers as estimates in Section 1 (DMV access failed).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_WeeklyTrades",
  "weighted_score": 6.0,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). HASH distribution key. (Tier 1 — Customer.CustomerStatic)",
      "match": "MINOR",
      "loss": "Additions (PI filter context, HASH distribution key) but core description is verbatim from Dim_Customer wiki."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Week1, Year1, NewTrades, FirstDayOfWeek",
      "problem": "All four passthrough columns from BI_DB_CID_WeeklyPanel_FullData are tagged Tier 2 but should be Tier 1. The WeeklyPanel wiki was available in the bundle and documents SSWeekNumberOfYear (#3), CalendarYear (#4), NewTrades_Total (#64), and FirstDayOfWeek (#28) with specific descriptions."
    },
    {
      "severity": "high",
      "column_or_section": "Week1, Year1, NewTrades, FirstDayOfWeek",
      "problem": "Upstream WeeklyPanel descriptions were not quoted verbatim. Writer paraphrased all four columns instead of inheriting the documented descriptions. E.g., WeeklyPanel says 'Total positions opened across all instrument types during the week. SUM.' for NewTrades_Total but wiki says 'Total number of new trades (positions opened) by this PI during the calendar week.'"
    },
    {
      "severity": "medium",
      "column_or_section": "NewTrades",
      "problem": "Wiki claims 'Includes manual and copy positions, excludes AirDrop' and 'Range: 0 to 8,400 observed' — neither claim is present in the WeeklyPanel upstream wiki for NewTrades_Total. The 'excludes AirDrop' semantic applies to ActiveOpen flags, not the NewTrades_Total count column. These may be fabricated data claims."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "Section 1 states '~4,419 distinct CIDs across 225 distinct weeks' confidently, but review-needed sidecar confirms DMV row count query failed (permission denied). Numbers should be flagged as estimates, not presented as observed facts."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer tier breakdown '1 T1, 5 T2' is consistent with the wiki's (incorrect) tier assignments but should be '5 T1, 1 T2' after correcting the tier misclassifications."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag Week1 as Tier 1 — BI_DB_CID_WeeklyPanel_FullData, quoting verbatim: 'SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear.' (2) Re-tag Year1 as Tier 1 — BI_DB_CID_WeeklyPanel_FullData, quoting: 'Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear.' (3) Re-tag NewTrades as Tier 1 — BI_DB_CID_WeeklyPanel_FullData, quoting: 'Total positions opened across all instrument types during the week. SUM.' Add rename note (NewTrades_Total → NewTrades). Remove unverified claims about AirDrop exclusion and 0-8400 range unless confirmed by live data query. (4) Re-tag FirstDayOfWeek as Tier 1 — BI_DB_CID_WeeklyPanel_FullData, quoting: 'Sunday date marking the start of the calendar week.' (5) Flag row counts and distinct CID/week numbers as estimates in Section 1 since DMV access failed.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "NewTrades: 'Range: 0 to 8,400 observed' — unverifiable, DMV access failed",
      "Section 1: '~4,419 distinct CIDs across 225 distinct weeks' — DMV failed per review-needed",
      "Section 1: '~3,220 rows per weekly slice' — derived estimate, not queried"
    ],
    "skipped_phases": [
      "Phase 10 (Atlassian) — skipped by regen harness",
      "Phase 12-14 — implied skipped (11/14 completed)",
      "DMV row count query failed (permission denied per review-needed)"
    ]
  }
}
</JUDGE_VERDICT>
