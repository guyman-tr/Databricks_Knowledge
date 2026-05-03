## Review: eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (AccountId, @WorkDate, CurrencyIson, SynapseUpdateDate, AccountStatusChangeDate). All tier assignments are correct. Business columns from FiatDwhDB with no upstream wiki are properly Tier 3. Pipeline-injected columns are properly Tier 2. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No upstream wiki exists for any source column. The bundle explicitly confirms `_no_upstream_found.txt` and "NO UPSTREAM WIKI was resolvable." Zero Tier 1 columns is the correct assignment. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 30 elements match 30 DDL columns exactly. Every element row has 5 cells with tier citation. Property table complete. ETL ASCII diagram uses real object names. Footer has tier breakdown. Section 1 has row count (1.52B) and date range (2022-04-11 to 2026-04-26). AccountStatus enum (≤15 values) lists inline codes. Review-needed sidecar does NOT contain `## 4. Elements`. 10/10 checklist items pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eMoney account snapshots from prod-banking), row grain (one account per work date), ETL consumer (SP_eMoney_Reconciliation_ETLs), refresh pattern (daily Append), row count, date range, status distribution with percentages, and currency breakdown. An analyst new to this table would know exactly what they're looking at.

**Dimension 5 — Data Evidence: 8/10**
Strong evidence of live data usage: row count with date range, AccountStatus distribution with percentages (A ~91%, S ~7%, B ~0.7%, P ~0.3%, R <0.1%), CurrencyIson distribution (EUR ~67%, GBP ~31%, AUD ~1.6%, DKK <0.1%), sample values for balances, dates, IDs. Footer says "Phases: 13/14" suggesting one phase was skipped, but data claims are well-supported. Minor deduction for status code labels (S/B/P/R) being inferred rather than confirmed.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, property table, ASCII pipeline diagram, footer with quality score and tier counts. Minor deviation: no explicit Phase Gate Checklist section; phase completion only referenced in footer.

### T1 Fidelity Table

No Tier 1 columns exist. The production source (FiatDwhDB.Tribe) has no upstream wiki in the bundle. This is correct and acknowledged in the review-needed sidecar.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns; no upstream wiki available |

### Top 5 Issues

1. **AccountStatus labels (S, B, P, R) are inferred** (Section 2.1, element #13): The writer states S=Suspended, B=Blocked, P=Pending, R=Restricted. Only "Active" for A is confirmed from AccountStatusDescription sample data. The other labels are guesses. The review-needed sidecar correctly flags this but the wiki presents them as fact.

2. **ProgramId business meaning unknown** (element #9): Values 175, 39, 177 are listed but their business meaning is unknown. The description says "Identifies the eMoney program the account belongs to" which is name-inferred. Correctly Tier 3 but the review-needed sidecar rightly flags this gap.

3. **ReservedBalance downstream claim imprecise** (element #23): Description says "Passed through to ETL_AccountSnapshot (not directly — enriched via bank account join)" — this parenthetical is confusing and may be inaccurate. If it's passed through, it's passed through; the "not directly" qualifier needs clearer grounding in the SP code.

4. **Missing explicit Phase Gate Checklist section**: The footer references "Phases: 13/14" but there's no dedicated section showing which phases were completed and which was skipped, making it harder to assess data claim reliability.

5. **@AccountsSnapshots@Id-509416 always equals @Id** (element #3): The wiki notes this is "observed to equal @Id in sample data" but doesn't strongly flag that this may be a data quality concern or structural invariant. The review-needed sidecar flags it more prominently.

### Regeneration Feedback

No regeneration needed — this wiki PASSES. For future improvement:
1. Qualify inferred status code labels (S, B, P, R) with "inferred" or "unconfirmed" in the element description rather than presenting them as established facts.
2. Clarify the ReservedBalance passthrough claim — remove the confusing "not directly" parenthetical or ground it in specific SP code lines.
3. Add an explicit Phase Gate Checklist section to make data provenance transparent.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.80
         = 8.85
```

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsSnapshots_AccountSnapshot-956050",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "AccountStatus (element #13, Section 2.1)",
      "problem": "Status code labels S=Suspended, B=Blocked, P=Pending, R=Restricted are inferred from common eMoney patterns, not confirmed from source data. Only A=Active is confirmed via AccountStatusDescription. Wiki presents all labels as established fact."
    },
    {
      "severity": "low",
      "column_or_section": "ProgramId (element #9)",
      "problem": "Values 175, 39, 177 observed but business meaning unknown. Description is name-inferred ('Identifies the eMoney program'). Should explicitly note meaning is unconfirmed."
    },
    {
      "severity": "low",
      "column_or_section": "ReservedBalance (element #23)",
      "problem": "Description says 'Passed through to ETL_AccountSnapshot (not directly — enriched via bank account join)' which is imprecise and potentially misleading. If it's not directly passed through, the parenthetical needs clearer grounding."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 13/14' but doesn't identify which phase was skipped, reducing transparency about data claim reliability."
    },
    {
      "severity": "low",
      "column_or_section": "@AccountsSnapshots@Id-509416 (element #3)",
      "problem": "Wiki notes value equals @Id in sample data but doesn't strongly flag this as a potential data quality concern or structural invariant requiring investigation."
    }
  ],
  "regeneration_feedback": "No regeneration required (PASS). Minor improvements: (1) Qualify inferred status code labels S/B/P/R with 'inferred' marker rather than presenting as confirmed. (2) Clarify ReservedBalance passthrough claim — remove or ground the 'not directly' parenthetical. (3) Add explicit Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 14 (unknown — not identified in footer)"]
  }
}
</JUDGE_VERDICT>
