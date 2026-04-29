## Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`

### Dimension 1 — Tier Accuracy: **7/10**

Five random columns checked:

| Column | Wiki Tier | Verified Tier | Match? |
|--------|-----------|---------------|--------|
| Date | Tier 2 — SP_CEPDailyAudit | Tier 2 — `@Date` SP parameter | YES |
| Property | Tier 2 — SP_CEPDailyAudit | Tier 2 — dictionary JOIN in SP (`cp.Name` via `PropertyID`) | YES |
| TypeOfChange | Tier 2 — SP_CEPDailyAudit | Tier 2 — SP-derived string literal | YES |
| LoginName | Tier 2 — SP_CEPDailyAudit | Tier 2 — `COALESCE(AppLoginName, PreviousAppLoginName)` in SP | YES |
| **UpdateDate** | **Tier 4 — inferred** | **Tier 2** — `GETDATE()` is explicitly the 13th column in the Conditions INSERT block of `SP_CEPDailyAudit` | **NO** |

1 mismatch out of 5 → base score 7. `UpdateDate` is tagged `[UNVERIFIED] (Tier 4 — inferred)` but the SP INSERT at the very bottom (`GETDATE()` as the last SELECT column for the Conditions insert) makes this unambiguously Tier 2. No paraphrasing failures (no T1 columns exist).

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. The actual column sources are all `Dealing_staging` tables which are **unresolved** (no wikis in the bundle). The 6 upstream wikis in the bundle are **sibling** CEPDailyAudit tables — related objects, not column sources. There is nothing to inherit verbatim.

**T1 Fidelity Table:** Empty — no Tier 1 columns exist.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

Score: 7 (neutral — no upstream wiki existed for source columns).

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (13 = 13) | YES |
| Every element row has 5 cells | YES |
| Every description ends with tier tag | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (3,189) and date range (2023-12-12 to 2026-03-09) | YES |
| TypeOfChange (5 values) listed inline in element #9 | YES |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 = **10**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is strong: names the domain (CEP hedging rule engine), specifies the row grain (one condition attribute change per date), names the ETL SP (`SP_CEPDailyAudit`), describes DELETE+INSERT pattern, gives row count and date range, explains condition anatomy (Property/Operator/Value), and provides a CEP hierarchy diagram. An analyst could immediately understand when and why to query this table.

### Dimension 5 — Data Evidence: **5/10**

Row count (3,189) and date range are present. TypeOfChange enum values are listed. NULL semantics for Comments are documented. However, there is **no Phase Gate Checklist** anywhere in the wiki — no `[x] P2` / `[x] P3` markers. The footer mentions no phases completed. Without explicit P2/P3 confirmation, the data claims cannot be verified as live-sourced vs. fabricated. The numbers are plausible but unverifiable from the wiki alone.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present. Tier legend in Section 4. Real SQL in Section 7 (3 queries, all syntactically valid). Footer has quality score and tier breakdown. **Missing:** phases-completed list in footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`).

---

### Top 5 Issues

1. **HIGH — `UpdateDate` mistagged as Tier 4.** The SP's Conditions INSERT explicitly uses `GETDATE()` as the 13th column. This is visible SP code, not inference. Should be `(Tier 2 — SP_CEPDailyAudit)` without `[UNVERIFIED]`.

2. **MEDIUM — No Phase Gate Checklist.** The footer and body contain no P2/P3 completion markers. Data claims (row count, date range) are present but their provenance is unverifiable.

3. **MEDIUM — No phases-completed list in footer.** The golden shape expects a `Phases: P1 ✓ ...` line in the footer.

4. **LOW — Section 5 lacks subsection numbering.** The shape reference expects `5.1` / `5.2` subsections; the wiki has a flat Section 5 with inline diagram and summary.

5. **LOW — `Condition Deleted` logic subtlety undocumented.** The SP uses `WHERE RN=1 AND RN_Desc=1 AND SysStartDate=@Date` — meaning only single-record conditions qualify. The wiki's Section 2 says "Condition Deleted" without noting this edge-case constraint. Minor for analysts but relevant for debugging.

---

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — remove `[UNVERIFIED]` prefix. The SP's `GETDATE()` is directly visible in the INSERT block.
2. Add a Phase Gate Checklist section or footer annotation confirming whether P2 (row count query) and P3 (distribution analysis) were executed against live data.
3. Add a phases-completed list to the footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`).
4. Update footer tier counts from `1 T4` to `0 T4` after the UpdateDate fix (becomes `0 T1, 13 T2, 0 T3, 0 T4`).

---

### Weighted Score

```
weighted = 0.25×7 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×5 + 0.10×8
         = 1.75 + 1.40 + 2.00 + 1.35 + 0.50 + 0.80
         = 7.80
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_Conditions",
  "weighted_score": 7.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but SP_CEPDailyAudit's INSERT INTO Dealing_CEPDailyAudit_Conditions explicitly uses GETDATE() as the 13th SELECT column. This is directly visible Tier 2 SP code, not inference."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No Phase Gate Checklist present anywhere in the wiki. Data claims (3,189 rows, date range 2023-12-12 to 2026-03-09) cannot be verified as live-sourced vs fabricated without P2/P3 completion markers."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Missing phases-completed list in footer (e.g., 'Phases: P1 ✓, P2 ✓, P3 ✓'). Golden shape expects this annotation."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5",
      "problem": "Section 5 lacks 5.1/5.2 subsection numbering per the golden reference shape. Content is present but flat."
    },
    {
      "severity": "low",
      "column_or_section": "TypeOfChange / Condition Deleted",
      "problem": "SP uses WHERE RN=1 AND RN_Desc=1 AND SysStartDate=@Date for 'Condition Deleted' — only single-temporal-record conditions qualify. This edge-case constraint is not documented in Section 2."
    }
  ],
  "regeneration_feedback": "1. Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) and remove [UNVERIFIED] — GETDATE() is explicit in the SP INSERT block. 2. Add Phase Gate Checklist or footer annotation confirming P2/P3 execution status. 3. Add phases-completed list to footer. 4. Update footer tier counts to 0 T1, 13 T2, 0 T3, 0 T4 after UpdateDate fix.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
