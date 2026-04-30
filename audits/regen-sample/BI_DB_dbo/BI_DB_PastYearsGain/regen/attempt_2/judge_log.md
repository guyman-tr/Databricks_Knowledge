I'll review this wiki systematically against the rubric.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (25%)

Sampling all 5 columns (table only has 5):

| Column | Lineage says | Actual source (SP code) | Wiki claims | Correct? |
|--------|-------------|------------------------|-------------|----------|
| Date | DWH_GainDaily.Date passthrough | `SELECT Date FROM DWH_GainDaily` — passthrough | Tier 1 — DWH_GainDaily | YES |
| CID | DWH_GainDaily.CID passthrough | `SELECT CID FROM DWH_GainDaily` — passthrough | Tier 1 — Customer.CustomerStatic | **NO** — wrong origin. Immediate upstream is DWH_GainDaily, not Customer.CustomerStatic |
| Gain_y | DWH_GainDaily.Gain_y passthrough | `SELECT Gain_y FROM DWH_GainDaily` — passthrough | Tier 1 — DWH_GainDaily | YES |
| Year1 | ETL-computed YEAR(Date)-1 | `(YEAR(Date)-1) AS Year1` | Tier 2 — SP | YES |
| UpdateDate | ETL-computed GETDATE() | `GETDATE() AS UpdateDate` | Tier 2 — SP | YES |

1 mismatch (CID): base score **7**. CID description quotes Dim_Customer wiki text instead of DWH_GainDaily wiki text — this is a paraphrasing failure (wrong source entirely): **-2**. Score: **5**.

### Dimension 2 — Upstream Fidelity (20%)

### T1 Fidelity Table

| Column | Upstream quote (DWH_GainDaily wiki) | Wiki quote | Match | Loss |
|--------|-------------------------------------|-----------|-------|------|
| Date | "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key." | "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key. In BI_DB_PastYearsGain, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1; historical rows (2007–2020) use Dec 1 instead. Part of logical PK (Date, CID)." | MINOR | Upstream core text preserved verbatim; additional local context appended |
| CID | "Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key." | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID)." | NO | Completely different description. Writer quoted Dim_Customer.RealCID wiki instead of DWH_GainDaily.CID wiki. Lost: FK reference, one-row-per-day semantics, HASH distribution key. |
| Gain_y | "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service." | "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily." | YES | None — upstream text verbatim, "Passthrough" appended |

CID has wrong tier origin (skipped immediate upstream DWH_GainDaily, quoted distant root Dim_Customer). Score: **3**.

### Dimension 3 — Completeness (20%)

- [x] All 8 sections present
- [x] Element count matches DDL (5/5)
- [x] Every element row has 5 cells
- [x] Every description ends with (Tier N — source)
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (~20.2M) and date range (2007–2023)
- [x] No dictionary columns with ≤15 values applicable (Year1 has 17 values)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 → Score: **10**.

### Dimension 4 — Business Meaning (15%)

Section 1 is excellent: names the domain (PI Dashboard), row grain (each customer's trailing 365-day compound return on Jan 1 of each year), ETL SP (SP_PI_Dashboard_COPYDATA_RuningSideBySide section 3.4), refresh pattern (annual, append-only, conditional on Jan 1), row count (~20.2M), date range (Year1 2007–2023), downstream consumer (section 3.7 for AVG yearly gain), and the historical pattern shift (Dec 1 → Jan 1). A new analyst could immediately know when and why to query this table.

Score: **9**.

### Dimension 5 — Data Evidence (10%)

- Row count and date range in Section 1: YES (~20.2M rows, 17 years, 4,958,580 CIDs)
- Specific values listed for enums: Year1 range documented
- Phase Gate: P2 [x], P3 [-] (skipped with reason — no categorical columns)
- Historical pattern shift documented with specific date boundaries

P3 skipped means some data claims (NULL rates) are not backed by distribution analysis. Score: **7**.

### Dimension 6 — Shape Fidelity (10%)

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES (simplified format, no stars column)
- Real SQL samples in Section 7: YES (3 queries)
- Footer with quality score and phases-completed: YES
- Phase Gate Checklist: YES

Score: **9**.

### Weighted Total

```
weighted = 0.25×5 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 1.25 + 0.60 + 2.00 + 1.35 + 0.70 + 0.90
         = 6.80
```

6.80 < 7.5 → **FAIL**

---

## Top 5 Issues

1. **CID wrong tier origin (high)**: CID is tagged `(Tier 1 — Customer.CustomerStatic)` but the immediate upstream is DWH_GainDaily. The writer skipped the direct source and quoted the Dim_Customer wiki description verbatim instead of the DWH_GainDaily wiki description. DWH_GainDaily.CID says "Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key." — none of this appears in the wiki.

2. **CID description is from wrong table (high)**: The CID description ("platform-internal primary key. Assigned at registration. Unique within etoro DB.") is copied from `Dim_Customer.RealCID`, not from `DWH_GainDaily.CID`. This is a verbatim-fidelity failure on the only column where it matters most for joins.

3. **Date description extended beyond upstream (low)**: The Date description appends BI_DB_PastYearsGain-specific context to the DWH_GainDaily upstream quote. While the core text is preserved, the additions blur the boundary between upstream-inherited semantics and local ETL context.

4. **Section 3.4 gotcha about Year1=2020 gap is speculative (medium)**: The gotcha "No Date=2021-01-01 row exists" is an inference about the transition pattern that should be flagged as unverified in review-needed, not stated as fact in the main wiki without P2 evidence.

5. **Lineage file lists CID source as DWH_GainDaily but wiki Elements section cites Customer.CustomerStatic (medium)**: Internal inconsistency — the lineage file correctly says `CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough | Tier 1` but the Elements table says `(Tier 1 — Customer.CustomerStatic)`.

---

## Regeneration Feedback

1. Re-tag CID as `(Tier 1 — DWH_GainDaily)` and use the DWH_GainDaily wiki description verbatim: "Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key."
2. For Date description, lead with the DWH_GainDaily upstream quote verbatim, then add local context after a clear separator (e.g., "In this table: filtered to Jan 1 dates…").
3. Resolve the inconsistency between lineage file (CID → DWH_GainDaily) and Elements table (CID → Customer.CustomerStatic) — both must agree.
4. Move the Year1=2020 gap claim to review-needed if not backed by P2 sample data.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PastYearsGain",
  "weighted_score": 6.80,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Date",
      "upstream_quote": "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key.",
      "wiki_quote": "Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key. In BI_DB_PastYearsGain, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1; historical rows (2007–2020) use Dec 1 instead. Part of logical PK (Date, CID).",
      "match": "MINOR",
      "loss": "Upstream core text preserved verbatim; additional local context appended after it"
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key.",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID).",
      "match": "NO",
      "loss": "Completely wrong source quoted. Writer used Dim_Customer.RealCID description instead of DWH_GainDaily.CID description. Lost: FK reference to Dim_Customer.RealCID, one-row-per-day semantics, PK component, HASH distribution key."
    },
    {
      "column": "Gain_y",
      "upstream_quote": "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service.",
      "wiki_quote": "Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CID",
      "problem": "Tagged Tier 1 — Customer.CustomerStatic but immediate upstream is DWH_GainDaily. SP section 3.4 does SELECT CID FROM DWH_GainDaily. Writer skipped the direct source and traced to a distant root origin, quoting Dim_Customer wiki text instead of DWH_GainDaily wiki text."
    },
    {
      "severity": "high",
      "column_or_section": "CID",
      "problem": "CID description ('platform-internal primary key. Assigned at registration. Unique within etoro DB.') is verbatim from Dim_Customer.RealCID wiki, not from DWH_GainDaily.CID wiki ('Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key.'). Complete fidelity failure."
    },
    {
      "severity": "medium",
      "column_or_section": "CID (lineage vs elements)",
      "problem": "Internal inconsistency: lineage file correctly lists CID source as BI_DB_dbo.DWH_GainDaily with Tier 1, but Elements table says (Tier 1 — Customer.CustomerStatic). These must agree."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 (Gotchas)",
      "problem": "Claim 'No Date=2021-01-01 row exists' about the Year1=2020 transition gap is stated as fact without P2 sample evidence. Should be in review-needed if unverified."
    },
    {
      "severity": "low",
      "column_or_section": "Date",
      "problem": "Date description appends BI_DB_PastYearsGain-specific filtering context beyond the DWH_GainDaily upstream quote. While upstream core is preserved, the extension blurs the Tier 1 verbatim boundary."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag CID as (Tier 1 — DWH_GainDaily) using verbatim text from DWH_GainDaily wiki: 'Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key.' (2) Resolve lineage-vs-elements inconsistency — both must cite DWH_GainDaily as CID source. (3) For Date, lead with upstream quote verbatim then add local context after a separator. (4) Move Year1=2020 gap claim to review-needed unless backed by P2 data.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3 Dist (no categorical columns match regex)"]
  }
}
</JUDGE_VERDICT>
