## Review: eMoney_Tribe.AccountsSnapshots_BankAccount-393561

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 23 columns are Tier 3. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable." Sampled 5 columns (@Id, BankAccountStatus, BankAccountIban, SynapseUpdateDate, partition_date) — all correctly Tier 3. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available. This is the correct outcome per the bundle. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10 (9/10 checklist)**
All 8 sections present. Element count 23 matches DDL 23. All element rows have 5 cells with tier tags. Property table complete. ASCII pipeline diagram uses real names. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar does not contain `## 4. Elements`. Minor gap: `EpmMethodId` lists values 4, 5 but no key=value meanings (admittedly unknown — acceptable for Tier 3).

**Dimension 4 — Business Meaning: 9/10**
Section 1 is concrete and actionable: names the domain (eMoney/Tribe banking), defines row grain (individual bank account within account snapshot), names the consumer SP (`SP_eMoney_Reconciliation_ETLs`), describes refresh (daily append via Generic Pipeline #552), gives row count (~1.6B) and date range (2023-12-20 to 2026-04-26), and explains the parent-child hierarchy. Status distribution (A ~90%, B ~10%, S <0.01%) adds real analytical value.

**Dimension 5 — Data Evidence: 7/10**
Row count and date range present. Specific enum values documented (BankAccountStatus with percentages, BankAccountBankProviderId with BIC/IBAN associations like MRMIGB22XXX and CFTEMTM1). NULL patterns noted for sparse columns. Footer claims "Phases: 13/14" but no explicit Phase Gate Checklist section with `[x]` checkboxes — it's impossible to verify which phases were actually completed vs. claimed.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: no standalone Phase Gate Checklist section (phases only referenced in footer). Otherwise structurally clean.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle confirmed no upstream wiki was resolvable. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **`EpmMethodId` (Section 4, element #20)**: Values 4 and 5 observed but no key=value meanings provided. The review-needed sidecar flags this but the wiki should more clearly mark this as "meaning unknown" rather than just listing values.

2. **Phase Gate Checklist missing as explicit section**: Footer says "Phases: 13/14" but there is no visible checklist showing which phases were completed. This makes it impossible to verify whether data-dependent claims (row counts, status distributions, BIC codes) are from live queries or fabricated.

3. **`BankAccountBankStateBranch` and `BankAccountBankBranchCode` (elements #22, #23)**: Described as "all NULL in sampled data" — if the sample was small, these could be populated for specific providers/regions. The writer should note the sample size.

4. **`@Id` type mismatch note (element #1)**: DDL says `varchar(255)` but the wiki describes it as a "GUID". GUIDs are typically 36 chars — the 255 limit is unusual. The writer doesn't flag this discrepancy.

5. **Section 8 placeholder**: "No Atlassian sources searched (regen-harness mode)" is an honest admission but adds no value. Could note the Freshservice reference more prominently or omit the section body.

### Regeneration Feedback

This wiki scores well and passes. For a future iteration:

1. Add an explicit Phase Gate Checklist section showing `[x]`/`[ ]` for each phase (P1-P3) to validate data claims.
2. Note sample size when claiming columns are "all NULL in sampled data" (BankAccountBankStateBranch, BankAccountBankBranchCode).
3. Flag the `@Id` `varchar(255)` vs GUID semantic mismatch — is 255 intentional or over-allocated?
4. Mark `EpmMethodId` values as "meaning unknown — requires Tribe team clarification" explicitly in the element description.

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsSnapshots_BankAccount-393561",
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
      "severity": "low",
      "column_or_section": "EpmMethodId",
      "problem": "Values 4 and 5 observed but no key=value meanings provided. Should explicitly state 'meaning unknown — requires Tribe team clarification'."
    },
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist",
      "problem": "No explicit Phase Gate Checklist section with checkboxes. Footer claims 'Phases: 13/14' but individual phase completion is unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "BankAccountBankStateBranch, BankAccountBankBranchCode",
      "problem": "Described as 'all NULL in sampled data' without noting sample size. Could be populated for specific providers or regions not in the sample."
    },
    {
      "severity": "low",
      "column_or_section": "@Id",
      "problem": "DDL type is varchar(255) but described as 'GUID'. GUIDs are 36 chars — the 255 limit is not flagged as unusual or explained."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "'No Atlassian sources searched (regen-harness mode)' is a placeholder that adds no analytical value."
    }
  ],
  "regeneration_feedback": "Wiki passes. Minor improvements: (1) Add explicit Phase Gate Checklist section with [x]/[ ] checkboxes. (2) Note sample size for NULL claims on BankAccountBankStateBranch and BankAccountBankBranchCode. (3) Flag varchar(255) vs GUID semantic note on @Id. (4) Mark EpmMethodId values as 'meaning unknown'.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["BankAccountStatus distribution (A ~90%, B ~10%, S <0.01%)"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
