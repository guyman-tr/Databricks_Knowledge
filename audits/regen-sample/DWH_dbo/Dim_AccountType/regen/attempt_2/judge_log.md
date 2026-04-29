## Adversarial Review: DWH_dbo.Dim_AccountType

### Dimension 1 — Tier Accuracy: **10/10**

Sampled all 6 columns (only 6 exist). AccountTypeID and Name are passthroughs/renames from `etoro.Dictionary.AccountType`, but the only upstream wiki in the bundle is for `USABroker.Dictionary.AccountType` — a completely different system (Apex Clearing, 3 rows: CASH/MARGIN/OPTION). The writer correctly rejected that wiki and tagged both as Tier 3. DWHAccountTypeID (`[AccountTypeID] AS [DWHAccountTypeID]`), StatusID (hardcoded 1), UpdateDate (GETDATE()), InsertDate (GETDATE()) are all correctly tagged Tier 2 as ETL-computed. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns exist because no valid upstream wiki was available. The writer documented this explicitly in the review-needed sidecar and did not fabricate Tier 1 inheritance from the wrong system. This is the correct decision. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

No Tier 1 columns to evaluate. The writer correctly avoided inheriting from `USABroker.Dictionary.AccountType`, which describes Apex Clearing brokerage types (CASH/MARGIN/OPTION) — completely unrelated to eToro's 18-type account classification.

### Dimension 3 — Completeness: **9/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL column count (6=6) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES |
| Dictionary columns ≤15 values list key=value pairs | YES (AccountTypeID enumerates all 18+1) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

10/10 checks = score 10. However, I'm docking 1 point: the footer lacks an explicit Phase Gate Checklist with P2/P3 completion markers. Score: **9**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (eToro account classification), row grain (one row per account type), enumerates all 19 values with IDs, names the ETL SP (`SP_Dictionaries_DL_To_Synapse`), refresh pattern (daily TRUNCATE+INSERT), row count (19), sentinel behavior (0=N/A), and last refresh timestamp. A new analyst can immediately understand when and how to query this table.

One concern: Section 2.1's "Account Category Groups" (Retail, Corporate, Partner, Internal, Managed) are the writer's own invention — no SP code or upstream documentation defines these groupings. They're plausible but unverifiable and could mislead analysts into thinking these are official system categories. Minor deduction.

### Dimension 5 — Data Evidence: **7/10**

Row count (19) and last refresh timestamp (2026-04-27 02:11:39 UTC) are present. All 18 live account type values are enumerated with IDs — this is strong evidence of live data inspection. StatusID=1 always and UpdateDate=InsertDate behavior are correctly noted. No explicit Phase Gate Checklist with P2/P3 checkboxes appears in the wiki body, though the data claims appear grounded.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1-8 present. Tier legend in Section 4. Real SQL samples in Section 7 with plausible JOINs. Footer has quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section; footer format differs slightly from golden reference (uses prose-style quality scores rather than phases-completed list).

---

### Top 5 Issues

1. **Medium — Section 2.1 (Account Category Groups)**: The Retail/Corporate/Partner/Internal/Managed groupings are fabricated by the writer. No SP code, upstream wiki, or application source defines these categories. While plausible, they could mislead analysts into treating them as official classifications. Should be flagged as "analyst-suggested grouping" or removed.

2. **Low — Missing Phase Gate Checklist**: No explicit `### Phase Gate Checklist` with `[x] P1`, `[x] P2`, `[x] P3` markers. Data claims appear live-backed but completeness of validation phases is unverifiable.

3. **Low — Section 6.2 Referenced By**: The 12 downstream references are plausible but may be incomplete. No methodology is stated for how these were discovered (SSDT grep? manual?). Missing downstream references could leave analysts unaware of impact.

4. **Info — AccountTypeID=18 (Trust)**: Correctly flagged in gotchas as potentially undocumented upstream. This is honest and appropriate.

5. **Info — No Tier 1 possible**: Structural limitation — `etoro.Dictionary.AccountType` wiki doesn't exist. The writer handled this correctly by using Tier 3 with live data grounding rather than inheriting from the wrong system.

### Regeneration Feedback

1. Add a disclaimer to Section 2.1 that the account category groupings (Retail, Corporate, Partner, Internal, Managed) are **analyst-suggested** and not defined in any system or upstream source.
2. Add an explicit Phase Gate Checklist section with P1/P2/P3 completion status.
3. When `etoro.Dictionary.AccountType` wiki is eventually created, re-run to upgrade AccountTypeID and Name to Tier 1 with verbatim descriptions.
4. Consider documenting the methodology for Section 6.2 Referenced By (e.g., "discovered via SSDT full-text search for `Dim_AccountType`").

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*9 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 1.80 + 1.35 + 0.70 + 0.80
         = 8.55
```

**Verdict: PASS**

This is a well-executed wiki given the constraints. The writer's best decision was rejecting the misresolved upstream wiki (`USABroker.Dictionary.AccountType`) rather than blindly inheriting from it — that would have produced nonsensical Tier 1 descriptions about Apex Clearing CASH/MARGIN/OPTION accounts on an eToro dimension table.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_AccountType",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 2.1 (Account Category Groups)",
      "problem": "The Retail/Corporate/Partner/Internal/Managed groupings are fabricated by the writer. No SP code, upstream wiki, or application source defines these categories. Could mislead analysts into treating them as official system classifications."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section with P1/P2/P3 completion markers. Data claims appear live-backed but validation phases are unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2 (Referenced By)",
      "problem": "12 downstream references listed without stated discovery methodology. May be incomplete — missing references could leave analysts unaware of downstream impact."
    },
    {
      "severity": "info",
      "column_or_section": "AccountTypeID=18 (Trust)",
      "problem": "Correctly flagged in gotchas as potentially undocumented upstream. Honest handling of uncertain data."
    },
    {
      "severity": "info",
      "column_or_section": "AccountTypeID, Name",
      "problem": "Both columns are Tier 3 because no etoro.Dictionary.AccountType wiki exists. The bundle provided USABroker.Dictionary.AccountType (Apex Clearing, 3 rows: CASH/MARGIN/OPTION) which is the wrong system. Writer correctly rejected it."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add disclaimer to Section 2.1 that account category groupings (Retail, Corporate, Partner, Internal, Managed) are analyst-suggested, not system-defined. (2) Add explicit Phase Gate Checklist section with P1/P2/P3 markers. (3) When etoro.Dictionary.AccountType wiki is created, re-run to upgrade AccountTypeID and Name to Tier 1 with verbatim descriptions. (4) Document discovery methodology for Section 6.2 Referenced By.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 19 rows, last refresh 2026-04-27 02:11 UTC, UpdateDate range 2026-04-27 00:00:00 – 2026-04-27 02:11:39"
    ],
    "skipped_phases": [
      "Phase Gate Checklist section absent from wiki body"
    ]
  }
}
</JUDGE_VERDICT>
