## Adversarial Review: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

This is a static, manually-loaded reference table with no ETL SP, no upstream wikis, and 10 columns — a relatively straightforward object to document. Let me evaluate each dimension.

---

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: `Currency`, `InstrumentID`, `BuyCurrency`, `UpdateDate`, `CurrencyISO`.

The upstream bundle explicitly states: **"NO UPSTREAM WIKI was resolvable for any source."** There is no ETL SP. Data was manually inserted. Tier 2 ("known origin, no upstream wiki to inherit from") is the correct classification for all 10 columns. No mismatches. No paraphrasing failures possible since there are zero Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. The bundle confirms no upstream wikis exist. Per rubric: "No upstream wiki existed in the bundle → 7 (neutral)." Nothing to verify or fault.

### Dimension 3 — Completeness: **4/10**

Checklist walk:

| # | Check | Result |
|---|-------|--------|
| 1 | All 8 sections present (`## 1.` … `## 8.`) | **NO** — sections use descriptive headers (`## Overview`, `## Source System`) not numbered format |
| 2 | Element count matches DDL column count | **YES** — 10 = 10 |
| 3 | Every element row has 5 cells | **YES** |
| 4 | Every description ends with `(Tier N — source)` | **YES** |
| 5 | Property table has Production Source, Refresh, Distribution, UC Target | **NO** — missing `Production Source` and `Distribution` labels; has Writer SP, Load strategy instead |
| 6 | Section 5.2 ETL pipeline ASCII diagram | **NO** — diagram exists in lineage file only, not in the wiki itself |
| 7 | Footer has tier breakdown counts | **YES** |
| 8 | Section 1 contains row count and date range | **YES** |
| 9 | Dictionary columns ≤15 values list inline pairs | **YES** (N/A — no column has ≤15 distinct qualifying values) |
| 10 | `.review-needed.md` does NOT contain `## 4. Elements` | **YES** |

**7/10 → Score 4.**

### Dimension 4 — Business Meaning: **9/10**

The Overview is excellent for this type of table. It names the domain (eToro Money FX instruments), specifies the grain (currency × FX instrument pair), gives concrete examples (AUD/EUR, GBP/USD), states row count (145), load date (2022-11-21), and explains the purpose (lookup for SP-driven balance/account calculations). An analyst would immediately know what this table is and when to use it. No ETL SP exists to name (correctly omitted).

### Dimension 5 — Data Evidence: **5/10**

Positive: Row count (145), load date (2022-11-21), specific currency distribution table (21 currencies with exact pair counts), verified `InstrumentID = DWHInstrumentID` across all rows, specific ISO code examples (36=AUD, 840=USD). These claims look genuine and specific.

Negative: **No Phase Gate Checklist section exists at all.** P2 and P3 are neither marked `[x]` nor `[ ]` — the entire section is absent. The rubric says if P2+P3 skipped, score 2. However, the data claims are extremely specific and internally consistent — I'll split the difference at 5.

### Dimension 6 — Shape Fidelity: **5/10**

- Sections are descriptive, not numbered per the golden `## 1.` … `## 8.` format
- No tier legend block in the Column Inventory section
- No SQL sample section (would be Section 7)
- Quality score at top (`8.5/10`) but no phases-completed list in footer
- Content organization is logical and readable, but structurally non-conforming

---

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no upstream wikis were resolvable. Table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **HIGH — Sections not numbered**: Wiki uses `## Overview`, `## Source System`, etc. instead of the required `## 1. Purpose & Business Context`, `## 2. Source System` format. Every section header deviates.

2. **HIGH — No Phase Gate Checklist**: The entire Phase Gate section is absent. There is no record of whether P2 (live data sampling) or P3 (distribution analysis) were formally completed, even though data claims in the wiki suggest they were.

3. **MEDIUM — No ETL pipeline ASCII diagram in wiki**: The lineage file has a rudimentary diagram, but the wiki itself (Section 5.2 equivalent) lacks one. For a static manual-load table this is minor, but the template requires it.

4. **MEDIUM — Property table missing standard labels**: Uses `Writer SP` / `Load strategy` instead of `Production Source` / `Distribution`. The Distribution (ROUND_ROBIN, HEAP) is mentioned in the Overview paragraph but not in the property table.

5. **LOW — No SQL sample section**: No Section 7 equivalent with example queries. For a static lookup table, a sample JOIN pattern showing how consuming SPs use this table would be valuable.

---

### Regeneration Feedback

1. **Renumber all sections** to use the `## 1.` … `## 8.` golden format (1=Purpose, 2=Source System, 3=ETL/Load, 4=Column Inventory, 5=Lineage/Pipeline, 6=Business Rules, 7=Sample Queries, 8=Open Questions).
2. **Add a Phase Gate Checklist** section with `[x]` for P1 (DDL parse), P2 (live data sample), P3 (distribution analysis) if data was actually queried, or `[ ]` if skipped.
3. **Add a tier legend** block at the top of the Column Inventory section explaining Tiers 1–4.
4. **Add the ETL pipeline ASCII diagram** (even if trivial: `Manual INSERT → eMoney_Currency_Instrument_Mapping_Static → SP consumers`) directly in the wiki body.
5. **Standardize the property table** to include `Production Source`, `Refresh`, `Distribution`, `UC Target` labels per template.
6. **Add a Section 7 with sample SQL** — e.g., a JOIN pattern showing how `SP_eMoney_Snapshot_Settled_Balance` uses this table.

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×4 + 0.15×9 + 0.10×5 + 0.10×5
         = 2.50 + 1.40 + 0.80 + 1.35 + 0.50 + 0.50
         = 7.05
```

**Verdict: FAIL** (7.05 < 7.5)

The content quality is strong — tier accuracy is perfect, business meaning is excellent, and the writer handled a manual-load table appropriately. The failure is purely structural: non-standard section numbering, missing Phase Gate Checklist, missing in-wiki diagram, and property table label mismatches. A template-conformance pass would likely push this to PASS.

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Currency_Instrument_Mapping_Static",
  "weighted_score": 7.05,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 4,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "All sections",
      "problem": "Sections use descriptive headers (## Overview, ## Source System) instead of the required numbered format (## 1. Purpose & Business Context, ## 2. Source System, etc.). Every section header deviates from the golden template."
    },
    {
      "severity": "high",
      "column_or_section": "Missing section",
      "problem": "No Phase Gate Checklist section exists. P2 (live data sampling) and P3 (distribution analysis) are neither marked completed nor skipped, despite data claims (145 rows, 21 currencies, specific pair counts) appearing throughout the wiki."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5.2 equivalent",
      "problem": "No ETL pipeline ASCII diagram in the wiki body. The lineage file has a rudimentary diagram but the wiki itself lacks one."
    },
    {
      "severity": "medium",
      "column_or_section": "ETL / Load Pattern table",
      "problem": "Property table uses non-standard labels (Writer SP, Load strategy) instead of required labels (Production Source, Distribution). Distribution (ROUND_ROBIN, HEAP) is mentioned in Overview text but not in the property table."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7 equivalent",
      "problem": "No sample SQL section. A JOIN pattern showing how consuming SPs (SP_eMoney_Snapshot_Settled_Balance, SP_eMoney_Calculated_Balance) reference this table would help analysts understand usage."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Renumber all sections to ## 1. … ## 8. golden format. (2) Add Phase Gate Checklist section with P1/P2/P3 completion status. (3) Add tier legend block at top of Column Inventory. (4) Embed ETL pipeline ASCII diagram in wiki body (even trivial: Manual INSERT → table → SP consumers). (5) Standardize property table labels to Production Source, Refresh, Distribution, UC Target. (6) Add Section 7 with sample SQL JOIN pattern.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3", "Phase Gate Checklist section entirely absent"]
  }
}
</JUDGE_VERDICT>
