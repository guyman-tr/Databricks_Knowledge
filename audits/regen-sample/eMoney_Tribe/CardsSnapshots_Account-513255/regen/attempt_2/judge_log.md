## Review: eMoney_Tribe.CardsSnapshots_Account-513255

### Dimension 1 — Tier Accuracy: 10/10
Sampled 5 columns: `AccountStatus`, `AccountLimitsGroupName`, `AvailableBalance`, `Created`, `@CardsSnapshots_Accounts@Id-350640`. All are passthroughs from `FiatDwhDB.Tribe.CardsSnapshots_Account-513255`, but the upstream bundle explicitly confirms **no upstream wiki was resolvable**. Tier 3 is the correct assignment for every column. 0 mismatches.

### Dimension 2 — Upstream Fidelity: 7/10
There are zero Tier 1 columns. The bundle confirms "NO UPSTREAM WIKI was resolvable for any source." This is the neutral case — no fidelity comparison is possible. Score 7 per rubric.

### Dimension 3 — Completeness: 8/10 (9/10 checks)
- [x] All 8 sections present
- [x] Element count matches DDL (25/25)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (86.4M) and date range (2023-12-20 to 2026-04-26)
- [x] Dictionary columns list inline values (AccountStatus: A=Active, etc.; AccountCurrency: GBP/EUR with %)
- [ ] `.review-needed.md` does NOT contain `## 4. Elements` — **passes** (no Section 4 present)

Actually all 10 pass. But one concern: there is no explicit Phase Gate Checklist section in the wiki body. The footer claims "Phases: 14/14" but the checklist itself isn't visible. Minor structural gap.

Score: 9 → mapped to 8 per rubric (I'll be generous and call it 9/10 checks = 8).

### Dimension 4 — Business Meaning: 9/10
Section 1 is specific and actionable. It names the domain (Tribe card provider), row grain (point-in-time snapshot of a single card-linked account), ETL pattern (Generic Pipeline, Append, daily), row count (86.4M), date range, downstream consumer (`SP_eMoney_Reconciliation_ETLs`), and the hierarchical JSON-shredded structure. A new analyst would know exactly when and how to use this table.

### Dimension 5 — Data Evidence: 7/10
Strong evidence of live data usage:
- Row count (86.4M) and date range in Section 1
- Specific enum distributions: AccountStatus (A ~94%, S ~4.1%, B ~1.1%, P ~0.5%, R ~0.08%), AccountCurrency (GBP ~77%, EUR ~23%), AccountLimitsGroupName (8 values with percentages)
- Empty-string observations for multiple columns
- Footer claims 14/14 phases, but no explicit Phase Gate Checklist section is rendered in the wiki body, making it impossible to verify P2/P3 completion independently. Slight deduction for opacity.

### Dimension 6 — Shape Fidelity: 8/10
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phase count. Minor deviations: no explicit Phase Gate Checklist section rendered; no tier legend in footer (just counts). Overall solid shape adherence.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns exist; all 25 columns are Tier 3 due to absent upstream wikis |

---

### Top 5 Issues

1. **Missing Phase Gate Checklist section** (Section or subsection): Footer claims "Phases: 14/14" but no Phase Gate Checklist is rendered in the wiki body. Reader cannot independently verify which phases were completed.

2. **`@Id` description claims it "shares the same value" as `@CardsSnapshots_Accounts@Id-350640`** (Element #1): This is a confusing claim. `@Id` is the record's own identifier; `@CardsSnapshots_Accounts@Id-350640` is an FK to the parent. These are different columns with different values. The writer may have confused the join semantics.

3. **Balance relationship stated without caveat** (Section 2.3): "CurrentBalance = AvailableBalance + BlockedAmount (logical relationship, not enforced)" — the review-needed sidecar correctly flags that SME should confirm whether ReservedBalance is included. The wiki should surface this uncertainty more prominently.

4. **AccountStatus code meanings are inferred** (Element #4): The values A=Active, S=Suspended, etc. are educated guesses from naming patterns. The review-needed sidecar flags this, but the wiki element description presents them as fact without qualification.

5. **No Section 8 content**: Section 8 (Atlassian Knowledge Sources) is empty. This is acceptable if genuinely no sources exist, but the writer should confirm this wasn't a search failure.

---

### Regeneration Feedback

1. Add an explicit Phase Gate Checklist subsection showing which phases (P1–P3) were completed with checkmarks.
2. Fix element #1 (`@Id`): remove the claim that it "shares the same value as @CardsSnapshots_Accounts@Id-350640" — these are structurally different columns. Clarify that `@Id` is the row's own GUID and `@CardsSnapshots_Accounts@Id-350640` is the FK to the parent.
3. Add qualification language to inferred enum meanings (AccountStatus codes) — e.g., "inferred from naming convention; SME confirmation needed."
4. Surface the ReservedBalance ambiguity from the review-needed sidecar into the main wiki's Section 2.3 or the element description.

---

### Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "CardsSnapshots_Account-513255",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist (missing section)",
      "problem": "Footer claims 'Phases: 14/14' but no Phase Gate Checklist section is rendered in the wiki body. Reader cannot verify which phases were completed."
    },
    {
      "severity": "medium",
      "column_or_section": "@Id (Element #1)",
      "problem": "Description claims @Id 'shares the same value as @CardsSnapshots_Accounts@Id-350640'. These are structurally different columns — @Id is the row's own GUID, while @CardsSnapshots_Accounts@Id-350640 is an FK to the parent table. Misleading to analysts."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.3 (Balance Snapshot)",
      "problem": "States 'CurrentBalance = AvailableBalance + BlockedAmount' as a logical relationship without noting uncertainty about whether ReservedBalance is included, despite the review-needed sidecar flagging this for SME validation."
    },
    {
      "severity": "low",
      "column_or_section": "AccountStatus (Element #4)",
      "problem": "Enum value meanings (A=Active, S=Suspended, B=Blocked, P=Pending, R=Restricted) are presented as fact but are inferred from naming conventions. Should include qualification language."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 (Atlassian Knowledge Sources)",
      "problem": "Section is empty. Acceptable if no sources exist, but should confirm this is not a search failure."
    }
  ],
  "regeneration_feedback": "Minor improvements only (wiki passes): (1) Add explicit Phase Gate Checklist subsection showing P1-P3 completion status. (2) Fix @Id description — remove false claim that it shares values with @CardsSnapshots_Accounts@Id-350640. (3) Add qualification language to inferred AccountStatus enum meanings. (4) Surface ReservedBalance ambiguity from review-needed sidecar into Section 2.3.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "AccountStatus: A ~94%, S ~4.1%, B ~1.1%, P ~0.5%, R ~0.08%",
      "AccountCurrency: GBP ~77%, EUR ~23%",
      "AccountLimitsGroupName: Green ~68%, Black ~14%, Black EU EUR ~13%, Green EU EUR ~4%",
      "Row count: 86.4M, date range: 2023-12-20 to 2026-04-26"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
