## Adversarial Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_Rules`

---

### Dimension 1 — Tier Accuracy: **7/10**

I sampled 5 columns: `Date`, `RuleID`, `TypeOfChange`, `LoginName`, `UpdateDate`.

- **Date** (`@Date` SP param) → Tier 2. Wiki: Tier 2. **Correct.**
- **RuleID** (passthrough from staging, no upstream wiki) → Tier 2. Wiki: Tier 2. **Correct.**
- **TypeOfChange** (CASE/UNION derivation in SP) → Tier 2. Wiki: Tier 2. **Correct.**
- **LoginName** (`COALESCE(AppLoginName, PreviousAppLoginName)` in SP) → Tier 2. Wiki: Tier 2. **Correct.**
- **UpdateDate** — Wiki tags `[UNVERIFIED] (Tier 4 — inferred)`, but the SP INSERT statement at line ~280 explicitly passes `GETDATE()` as column 11. The writer even *describes* it as "DWH insert time via GETDATE() in the SP" — then tags it Tier 4 anyway. This is **Tier 2**, not Tier 4. **Wrong.**

1 mismatch out of 5 → base score 7. No Tier 1 paraphrasing failures (0 T1 columns). **Score: 7.**

---

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

The wiki claims **0 Tier 1** columns. This is correct: the direct upstream sources (`External_Etoro_CEP_Rules`, `External_Etoro_History_Rules`) are both **unresolved** — no wiki exists for them. The upstream wikis in the bundle are **sibling** CEPDailyAudit tables (CP, Conditions, etc.), not sources for the Rules table's own columns.

No Tier 1 columns → no fidelity table to build → neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

**Score: 7** (neutral — no upstream wiki existed for direct column sources).

---

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL column count (11 = 11) | YES |
| Every element row has 5 cells | YES |
| Every element description ends with tier tag | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5 has ETL pipeline ASCII diagram with real names | YES (but labeled as inline flow, not `### 5.2`) |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | YES |
| Dictionary columns (≤15 values) list inline values | YES (`TypeOfChange` lists all 8 values in element #7) |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

9/10 → **Score: 8.** The only miss is the `5.2` subsection label convention — minor structural deviation.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names:
- The domain (CEP Rule changes in the hedging rule engine)
- Row grain ("one rule-level event on business date `Date`")
- All 8 `TypeOfChange` event types
- The ETL SP (`SP_CEPDailyAudit`)
- Load pattern (DELETE + INSERT)
- Scale (~1,003 rows, 2023-12-13 to 2026-03-09)
- Weekly sibling comparison (`Dealing_CEPWeeklyAudit_Rules`)
- PII status (no PII)

A new analyst could immediately understand when to use this table. **Score: 9.**

---

### Dimension 5 — Data Evidence: **5/10**

- Row count (~1,003) and date range (2023-12-13 to 2026-03-09) appear in Section 1. ✓
- `TypeOfChange` enum values listed inline. ✓
- **No Phase Gate Checklist** anywhere in the wiki. Cannot verify whether P2 (sample queries against live data) or P3 (distribution/NULL analysis) were actually executed. The data claims *look* plausible but are unverifiable without the checklist.
- No NULL-rate or distribution claims beyond the row count.

**Score: 5.**

---

### Dimension 6 — Shape Fidelity: **7/10**

- Numbered sections 1–8: ✓
- Tier legend in Section 4: ✓
- Real SQL samples in Section 7 (3 queries): ✓
- Footer with quality score and tier breakdown: ✓
- Missing: Phase Gate Checklist section, `5.2` subsection label
- Footer has quality score but no explicit "phases-completed" checklist with `[x]` marks

Minor deviations from golden reference. **Score: 7.**

---

### Weighted Total

```
weighted = 0.25×7 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×5 + 0.10×7
         = 1.75  + 1.40  + 1.60  + 1.35  + 0.50  + 0.70
         = 7.30
```

**7.30 < 7.5 → FAIL**

---

### Top 5 Issues

1. **HIGH — `UpdateDate` mistagged Tier 4.** The SP INSERT at the Rules section explicitly passes `GETDATE()` as column 11. The writer describes the source correctly ("DWH insert time via GETDATE() in the SP") but then contradicts themselves with `[UNVERIFIED] (Tier 4 — inferred)`. This is Tier 2.

2. **MEDIUM — No Phase Gate Checklist.** The rubric requires P2/P3 phase markers. Without them, data claims (row count, date range, enum values) cannot be verified as live-sourced vs fabricated.

3. **LOW — Section 5 structure.** Missing the `### 5.2 ETL Pipeline` subsection header convention. The diagram content is correct.

4. **LOW — Footer missing phases-completed list.** Footer has tier counts but no `[x] P1 / [x] P2 / [x] P3` style checklist.

5. **LOW — `IsActive` column semantics.** The wiki mentions `IsActive` in Section 2 business logic but doesn't clarify that `IsActive` is NOT a column in this table — it's only used in the SP for change detection. Could confuse analysts scanning the logic section.

---

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — remove `[UNVERIFIED]` tag. The SP clearly shows `GETDATE()`.
2. Add a Phase Gate Checklist section (or subsection in Section 4) with `[x]`/`[ ]` markers for P1 (DDL + SP review), P2 (sample queries), P3 (distribution analysis).
3. Add `### 5.2 ETL Pipeline` subsection label to match golden reference shape.
4. Add phases-completed markers to the footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`).
5. Clarify in Section 2 that `IsActive` is a source column used for change detection, not a column in this table.

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_Rules",
  "weighted_score": 7.30,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but SP INSERT explicitly passes GETDATE() as column 11. Writer describes the source correctly in the description text but contradicts with the tier tag. Should be (Tier 2 — SP_CEPDailyAudit)."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 / Footer",
      "problem": "No Phase Gate Checklist present. Cannot verify whether P2 (live sample queries) or P3 (distribution/NULL analysis) were executed. Data claims (row count ~1,003, date range, TypeOfChange enum values) are unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5",
      "problem": "Missing ### 5.2 ETL Pipeline subsection header — diagram content is correct but structure deviates from golden reference shape."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer has tier counts and quality score but no phases-completed checklist (e.g., P1/P2/P3 markers)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2",
      "problem": "Mentions IsActive in business logic context without clarifying it is a source column used for change detection, not a column in this table. Could mislead analysts."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit), removing [UNVERIFIED] — SP INSERT clearly shows GETDATE(). (2) Add Phase Gate Checklist section with P1/P2/P3 checkboxes. (3) Add ### 5.2 ETL Pipeline subsection label. (4) Add phases-completed markers to footer. (5) Clarify in Section 2 that IsActive is a source column for change detection, not present in this table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
