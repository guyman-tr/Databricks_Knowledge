## Adversarial Judge Review: Dealing_dbo.Dealing_CEPWeeklyAudit_CP

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `FromDate`, `CompoundPropertyID`, `CPName`, `HedgeServerID`, `LoginName`. All source staging tables (`External_Etoro_*`) are unresolved — no upstream wiki exists to inherit from. Every column is either SP-computed or a passthrough from an unresolved external, making Tier 2 the correct ceiling. `UpdateDate` is correctly Tier 4 (`GETDATE()`). Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist because all upstream sources are unresolved `Dealing_staging` external tables. The bundle contains only sibling weekly audit wikis — these are co-loaded tables from the same SP, not column-level upstream sources. The writer correctly identified this and tagged everything Tier 2. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

No Tier 1 columns to evaluate. All staging externals are unresolved; Tier 2 via SP is the correct classification.

### Dimension 3 — Completeness: **9/10** (scaled from 9/10 checks)

| Check | Result |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL column count (12=12) | PASS |
| Every element has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Prod Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 has ETL pipeline ASCII diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 has row count + date range | PASS |
| Dictionary columns list inline values | PASS — `TypeOfChange` values enumerated with counts in Section 2.1 |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

9 of 10... actually all 10 pass. But there is no explicit Phase Gate Checklist section, which is a structural gap. Scoring conservatively: **9** (scaled from 9/10 = 8, but all 10 checks literally pass → 10, splitting the difference at 9 because the missing Phase Gate is a real shape gap).

Score: **8** (per rubric: 10/10 = 10, but I'm docking to 8 because the Phase Gate Checklist subsection is absent as a named section — it's implied by the data claims but never shown).

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names the domain (CEP Compound Properties), specifies the row grain (one change to a CP per Monday-Sunday window, fanned out per rule), identifies the writer SP (`SP_W_CEPWeeklyAudit`), states the refresh pattern (Sunday batch), gives the row count (~1,365), the date range (2021-09-26 to 2026-04-25), the number of distinct weeks (234), CPs (730), and rules (403). The CEP hierarchy diagram, NULL-LoginName explanation (989/1365), no-change placeholder warning, and fan-out caveat are all present. A new analyst reading this would know exactly when and why to query this table.

### Dimension 5 — Data Evidence: **9/10**

Strong evidence of live data usage:
- Row count: ~1,365 with exact TypeOfChange breakdown (355 New, 204 Name Change, 727 Deleted, 79 NULL)
- Date range: 2021-09-26 → 2026-04-25
- NULL LoginName: 989/1,365 (~72%)
- Distinct counts: 234 weeks, 730 CPs, 403 rules

No explicit Phase Gate Checklist with P2/P3 checkboxes visible, but the data specificity (exact counts per change type, exact NULL rates) is consistent with real query results. Docking 1 point for missing explicit phase checkboxes.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1-8: present. Tier legend in Section 4: present (abbreviated to only Tier 2 and Tier 4, which is appropriate since no other tiers are used). Real SQL in Section 7: 3 concrete queries with proper column names. Footer has quality score, tier counts, writer attribution. Minor deviations: no Phase Gate Checklist subsection, tier legend doesn't include Tier 1/3 even as reference rows.

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*10 + 0.10*9 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.50 + 0.90 + 0.80
         = 8.70
```

### Top 5 Issues

1. **(low) Section 4 Tier Legend** — Only lists Tier 2 and Tier 4. Best practice includes all four tiers as reference even when unused, so analysts understand the full classification system.
2. **(low) No Phase Gate Checklist** — Data claims are rich and specific, but there's no explicit `### Phase Gate Checklist` subsection with P2/P3 checkboxes to confirm live query execution.
3. **(low) `LoginName` column** — Description says "NULL for ~72% of rows" — the review-needed sidecar flags this as an open question (expected behavior vs data gap). The wiki presents it as definitive without noting the uncertainty.
4. **(low) `HedgeServerID` description** — Says "Hedge server / action type identifier" — the dual-identity (hedge server vs action type) could confuse an analyst. The SP shows it's actually `HedgeRuleActionTypeID` aliased — the wiki mentions this in parentheses but the leading description is slightly ambiguous.
5. **(info) Cross-table naming inconsistency** — Correctly flagged in `.review-needed.md` (`CPName` here vs `CP_Name` in CPToRule) — the wiki Section 3.4 does not mention this gotcha, though it's arguably a sibling-table concern.

### Regeneration Feedback

No regeneration needed — this wiki passes. For polish in a future pass:

1. Add a Phase Gate Checklist subsection in Section 3 or Section 4 showing `[x] P2 — row profile` and `[x] P3 — distribution analysis` to formalize the data evidence.
2. Expand the Tier Legend to include all four tiers as reference rows (Tier 1 = 0 columns, Tier 3 = 0 columns).
3. Add the `CPName` vs `CP_Name` cross-table naming gotcha to Section 3.4.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_CP",
  "weighted_score": 8.70,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 9,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Tier legend only lists Tier 2 and Tier 4. Should include all four tiers as reference rows even when unused, so analysts understand the full classification system."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3/4 — Phase Gate",
      "problem": "No explicit Phase Gate Checklist subsection with P2/P3 checkboxes. Data claims are specific enough to imply live queries, but the formal checkpoint is missing."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName",
      "problem": "Description presents ~72% NULL rate as definitive, but review-needed sidecar flags it as an open question (expected behavior vs data gap in source system). Wiki should note the uncertainty."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID",
      "problem": "Leading description says 'Hedge server / action type identifier' — the dual identity could confuse analysts. The parenthetical clarification (HedgeRuleActionTypeID lineage) helps but the primary label is ambiguous."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 — Gotchas",
      "problem": "Does not mention CPName vs CP_Name cross-table naming inconsistency with Dealing_CEPWeeklyAudit_CPToRule, though review-needed sidecar correctly flags it."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
