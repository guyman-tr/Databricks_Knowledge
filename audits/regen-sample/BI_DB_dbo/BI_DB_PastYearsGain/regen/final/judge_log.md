## Judge Review: BI_DB_dbo.BI_DB_PastYearsGain

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
All 5 columns examined. Date and Gain_y are passthroughs from DWH_GainDaily (upstream wiki available in bundle), yet both are tagged Tier 2 instead of Tier 1. CID is correctly Tier 1 (traced to Customer.CustomerStatic via Dim_Customer — root origin acceptable). Year1 (YEAR(Date)-1, ETL-computed) and UpdateDate (GETDATE()) are correctly Tier 2. Two mismatches out of 5.

**Dimension 2 — Upstream Fidelity: 5/10**
CID is the only tagged Tier 1 column and is verbatim from Dim_Customer wiki (minor addition of "Part of logical PK"). However, Date and Gain_y are missed inheritances — passthrough columns from DWH_GainDaily with available upstream wiki, wrongly tagged Tier 2. Two missed inheritances at -2 each.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (5) matches DDL (5). All element rows have 5 cells with tier tags. Property table has all required fields. ETL pipeline ASCII diagram uses real object names. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar has no Elements section. No dictionary columns with ≤15 values to list.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (PI Dashboard yearly performance), row grain (one customer per Jan 1 snapshot), ETL SP, refresh pattern (annual conditional), row count (~20.2M), date range (2007-2023), consumer (SP section 3.7 for Avg_Yearly_gain), and the historical Dec 1 → Jan 1 pattern shift.

**Dimension 5 — Data Evidence: 7/10**
Row count, date range, 17 distinct years, and historical pattern shift are all documented with specific values. No explicit Phase Gate Checklist with P2/P3 checkboxes in the wiki body, but the claims are plausible and specific enough to indicate live data was consulted.

**Dimension 6 — Shape Fidelity: 9/10**
All numbered sections present. Tier legend in Section 4. Three real SQL queries in Section 7. Footer has quality score, phases-completed, and tier breakdown. Minor: no star-based tier legend (uses text tiers only — acceptable variant).

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID)." | MINOR | Added "Part of logical PK" context — no semantic loss |
| Date (SHOULD BE T1) | "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key." (DWH_GainDaily.Date) | "Jan 1 snapshot date from which the trailing yearly gain was captured. Sourced from DWH_GainDaily.Date, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1. Historical rows (2007-2020) use Dec 1 instead. Part of logical PK (Date, CID)." | NO | Completely rewritten. Upstream wording not preserved. Tagged Tier 2 instead of Tier 1. |
| Gain_y (SHOULD BE T1) | "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service." (DWH_GainDaily.Gain_y) | "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily." | YES | Verbatim with context appended. But mistagged as Tier 2. |

---

### Top 5 Issues

1. **HIGH — Gain_y mistagged Tier 2**: Gain_y is a direct passthrough from DWH_GainDaily.Gain_y (no transform in SP section 3.4: `SELECT ... Gain_y ... FROM DWH_GainDaily`). DWH_GainDaily wiki is in the bundle. Should be `(Tier 1 — DWH_GainDaily)` with upstream description verbatim.

2. **HIGH — Date mistagged Tier 2**: Date is a passthrough from DWH_GainDaily.Date filtered by a WHERE clause (V_Dim_Date WHERE DayNumberOfYear=1). The column value is unchanged — only the row set is filtered. Should be `(Tier 1 — DWH_GainDaily)` with upstream description quoted verbatim. Current description is completely rewritten.

3. **MEDIUM — Date description not verbatim**: Even if re-tagged Tier 1, the description rewrites the upstream entirely ("Jan 1 snapshot date from which the trailing yearly gain was captured" vs upstream "Snapshot date for which gains were calculated"). The additional context about Jan 1 filtering and historical Dec 1 pattern is valuable but should appear as appended context after the verbatim upstream quote, not as a replacement.

4. **LOW — Tier legend lists only 2 tiers**: The legend says Tier 1 sources are "DWH_GainDaily, Dim_Customer" but only CID actually uses Tier 1. With corrections, Date and Gain_y would also be Tier 1 from DWH_GainDaily, making the legend accurate after fix.

5. **LOW — No Phase Gate Checklist**: The wiki has no explicit P2/P3 checkboxes. The footer says "Phases: 11/14" but doesn't enumerate which phases were completed vs skipped. Data evidence appears genuine but the formal checklist is missing.

---

### Regeneration Feedback

1. Re-tag `Date` as `(Tier 1 — DWH_GainDaily)`. Lead the description with the verbatim upstream quote: "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key." Then append the BI_DB_PastYearsGain-specific context (Jan 1 filter, historical Dec 1 pattern) after the verbatim quote.
2. Re-tag `Gain_y` as `(Tier 1 — DWH_GainDaily)`. The existing description is already verbatim — just change the tier tag from Tier 2 to Tier 1.
3. Update the tier legend and footer counts: should be 3 T1 (CID, Date, Gain_y), 2 T2 (Year1, UpdateDate).
4. Add a Phase Gate Checklist section (or note in footer) explicitly marking which data phases (P2 row counts, P3 distributions) were executed.

---

### Weighted Score Calculation

```
weighted = 0.25×5 + 0.20×5 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 1.25 + 1.00 + 2.00 + 1.35 + 0.70 + 0.90
         = 7.20
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PastYearsGain",
  "weighted_score": 7.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID).",
      "match": "MINOR",
      "loss": "Added 'Part of logical PK (Date, CID)' context — no semantic loss"
    },
    {
      "column": "Date (SHOULD BE T1)",
      "upstream_quote": "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key.",
      "wiki_quote": "Jan 1 snapshot date from which the trailing yearly gain was captured. Sourced from DWH_GainDaily.Date, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1. Historical rows (2007-2020) use Dec 1 instead. Part of logical PK (Date, CID).",
      "match": "NO",
      "loss": "Completely rewritten description. Upstream wording not preserved. Mistagged as Tier 2 instead of Tier 1."
    },
    {
      "column": "Gain_y (SHOULD BE T1)",
      "upstream_quote": "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service.",
      "wiki_quote": "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily.",
      "match": "YES",
      "loss": "Verbatim with appended context. But mistagged as Tier 2 instead of Tier 1."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Gain_y",
      "problem": "Tagged Tier 2 (DWH_GainDaily) but is a direct passthrough from DWH_GainDaily.Gain_y with no transform. DWH_GainDaily wiki is available in the bundle. Should be Tier 1 — DWH_GainDaily."
    },
    {
      "severity": "high",
      "column_or_section": "Date",
      "problem": "Tagged Tier 2 (DWH_GainDaily) but is a passthrough from DWH_GainDaily.Date (only filtered by WHERE clause, value unchanged). Should be Tier 1 — DWH_GainDaily with upstream description verbatim."
    },
    {
      "severity": "medium",
      "column_or_section": "Date",
      "problem": "Description completely rewritten from upstream. Upstream says 'Snapshot date for which gains were calculated' but wiki says 'Jan 1 snapshot date from which the trailing yearly gain was captured'. Verbatim upstream quote must lead, with BI_DB-specific context appended."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Tier Legend)",
      "problem": "Tier legend and footer counts state 1 T1 / 4 T2, but with corrections should be 3 T1 / 2 T2."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No Phase Gate Checklist with explicit P2/P3 checkboxes. Footer says 'Phases: 11/14' without enumerating completed vs skipped phases."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag Date as (Tier 1 — DWH_GainDaily) and lead description with verbatim upstream quote: 'Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key.' Then append Jan 1 filter and Dec 1 historical pattern as additional context. (2) Re-tag Gain_y as (Tier 1 — DWH_GainDaily) — description is already verbatim, just fix the tier tag. (3) Update tier legend and footer counts to 3 T1 (CID, Date, Gain_y), 2 T2 (Year1, UpdateDate). (4) Add explicit Phase Gate Checklist marking P2/P3 completion status.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present in wiki body"]
  }
}
</JUDGE_VERDICT>
