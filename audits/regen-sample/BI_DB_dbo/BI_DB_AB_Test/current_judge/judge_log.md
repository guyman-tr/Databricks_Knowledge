## Adversarial Review: BI_DB_dbo.BI_DB_AB_Test

This is a table with **no writer SP, no upstream wikis, and no active pipeline** — a genuinely difficult documentation target. The writer leaned heavily on live data sampling and domain inference. Let me evaluate whether that was done well.

---

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: DateID, RealCID, IsControl, Name, UpdateDate.

- **DateID** → Tier 3. No upstream wiki, no writer SP. Correct.
- **RealCID** → Tier 3. No upstream wiki resolvable. Correct.
- **IsControl** → Tier 3. No upstream wiki. Correct.
- **Name** → Tier 3. No upstream wiki. Correct.
- **UpdateDate** → Tier 5 (propagation). ETL load timestamp — appropriate use of Tier 5.

The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable for any source." All columns correctly tagged Tier 3 or Tier 5. Zero mismatches, zero paraphrasing failures (no Tier 1 columns exist to paraphrase).

---

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns**. The upstream bundle confirms no upstream wikis were available. The writer correctly did not fabricate Tier 1 attributions. Score is neutral per rubric.

#### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained no resolvable upstream wikis.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Dimension 3 — Completeness: **9/10** (scaled from 9/10 checklist)

- [x] All 8 sections present (1–8)
- [x] Element count matches DDL: 8 columns in DDL, 8 elements in wiki
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (314,240) and date range (2020-06-10 to 2023-04-29)
- [x] Dictionary columns list values inline: `IsControl` has `1=control, 0=treatment`; `Name` lists both test names; `BI_Owner` and `Business_Owner` list observed values
- [ ] `.review-needed.md` does NOT contain `## 4. Elements` — **PASS** (it does not)

9/10 checklist → Score 8 per rubric. However, re-examining: all 10 items pass. 10/10 → **Score 10**.

Correcting: I'll give **10/10** — all checklist items satisfied.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent for this class of table:
- Names the domain (A/B experiment assignment)
- States row grain (customer-test-day)
- Gives row count (314,240) and date range
- Names both specific experiments with ownership, cohort sizes, and control/treatment splits
- Notes staleness (no data since 2023-04-30)
- References the companion table with distinction

No ETL SP exists, so its absence is correctly noted rather than fabricated. One could argue it's slightly verbose, but the detail is genuinely useful for an analyst encountering this table cold.

---

### Dimension 5 — Data Evidence: **7/10**

Live data evidence is strong:
- Row count: 314,240 with last-updated date
- Per-test breakdowns with exact customer counts and date ranges
- IsControl distribution per test (33,840 control vs 205,346 treatment for lead_conv)
- Specific owner names observed

Footer states P3 skipped (among others). P2 is NOT listed as skipped, so the "P2+P3 both skipped → fabricated" penalty does not apply. The data claims appear grounded in actual sampling. Deducting slightly because NULL-rate analysis is absent and P3 (deep distribution) was skipped.

---

### Dimension 6 — Shape Fidelity: **9/10**

- Numbered sections 1–8: ✓
- Tier legend in Section 4: ✓
- Real SQL samples in Section 7 (3 queries, all syntactically valid): ✓
- Footer with quality score (7.5/10), phases completed (8/14), tier breakdown: ✓
- Property table is comprehensive (14 rows): ✓

Minor deviation: Section 8 is "Atlassian Knowledge Sources" rather than a more standard heading, but content is appropriate.

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS**

---

### Top 5 Issues

1. **Medium — Section 5.1 speculative sourcing**: The Production Sources table presents "etoro production (Customer)" as RealCID's source and "experiment management tool" for several columns. These are reasonable inferences but stated as if traced. The lineage file correctly marks them "Unknown" but Section 5.1 in the wiki presents them more assertively.

2. **Low — No NULL-rate reporting**: None of the 8 columns (all nullable) have NULL-rate statistics. For a table with live data access, this would strengthen the documentation.

3. **Low — Section 3.3 speculative join**: The join to `Fact_CustomerAction` is hypothetical — no evidence this table exists or uses the assumed schema. The `LIKE '%' + b.TestName + '%'` pattern for joining to `BI_DB_AB_Test_Data` is fragile and untested.

4. **Low — varchar length warnings are repeated**: The varchar(14/15/25) tightness is mentioned in element descriptions, Section 2.3, AND Section 3.4 Gotchas. Redundant.

5. **Cosmetic — Footer quality self-score**: The writer gave itself 7.5/10 which matches the judge threshold exactly. Convenient but ultimately irrelevant to documentation quality.

---

### Regeneration Feedback

No regeneration required — the wiki passes. For optional improvement:

1. Add NULL-rate statistics for all 8 columns (all are nullable — are any actually NULL in practice?)
2. Tone down Section 5.1 Production Sources from assertive to explicitly speculative (e.g., "Likely from etoro production" → "Unknown; RealCID pattern suggests customer system origin")
3. Remove the `Fact_CustomerAction` join example from Section 3.3 or explicitly mark it as hypothetical
4. Deduplicate the varchar length warnings — mention once in Elements, reference from Gotchas

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AB_Test",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 5.1",
      "problem": "Production Sources table presents speculative origins assertively (e.g., 'etoro production (Customer)' for RealCID) despite the upstream bundle confirming no upstream wiki was resolvable. Lineage file correctly says 'Unknown' but the wiki Section 5.1 does not."
    },
    {
      "severity": "low",
      "column_or_section": "All columns",
      "problem": "No NULL-rate statistics reported for any of the 8 nullable columns despite live data access being available."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3",
      "problem": "Join to Fact_CustomerAction is hypothetical — no evidence this table exists with the assumed schema. The LIKE-based join to BI_DB_AB_Test_Data is fragile and untested."
    },
    {
      "severity": "low",
      "column_or_section": "BI_Owner, Business_Owner, Name",
      "problem": "varchar length warnings repeated in element descriptions, Section 2.3, and Section 3.4 Gotchas — redundant."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Self-assessed quality score of 7.5/10 is cosmetic but conveniently lands on the pass threshold."
    }
  ],
  "regeneration_feedback": "No regeneration required. Optional improvements: (1) Add NULL-rate stats for all 8 columns. (2) Mark Section 5.1 sources as explicitly speculative. (3) Label Fact_CustomerAction join as hypothetical. (4) Deduplicate varchar length warnings.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3", "P5", "P7", "P9", "P9B", "P10"]
  }
}
</JUDGE_VERDICT>
