## Review: eMoney_Tribe.AccountsActivities_AccountActivity-833937

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (@Created, TransactionCode, EpmMethodId, SynapseUpdateDate, HolderCurrencyAlpha). The upstream bundle confirms zero upstream wikis exist — every column is correctly tagged Tier 3. No mismatches, no paraphrasing failures possible.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns because no upstream wiki was resolvable in the bundle. This is the correct outcome per the rubric's "No upstream wiki existed in the bundle → 7 (neutral)" rule. The writer did not fabricate Tier 1 claims, which is the right call.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items pass:
- All 8 sections present (1–8)
- Element count: 116 DDL columns = 116 wiki elements
- All element rows have 5 cells
- All descriptions end with `(Tier N — source)`
- Property table has Production Source, Refresh, Distribution, UC Target
- Section 5.2 has real ASCII diagram with SP_eMoney_FiatDwhETL, real table names
- Footer has tier breakdown counts
- Section 1 has row count (~29.7M) and date range (Sep 2021 to present)
- Enum columns list values inline (TransactionCode 5 values, Action 2 values, CardPresent 2 values, TransactionClass 4 values with percentages)
- `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToro Money card/payment platform, GPS/Modulr), row grain (single transaction event by GUID), ETL SP (SP_eMoney_FiatDwhETL), refresh pattern (daily incremental append by @Created), row count with yearly growth trajectory, and currency distribution. An analyst knows exactly when to query this table.

**Dimension 5 — Data Evidence: 7/10**
Strong data grounding: row count (~29.7M) with year-by-year breakdown (505K→11.5M growth), currency distribution (75% EUR, 21% GBP), TransactionClass percentages, LoadType percentages, specific sample values throughout. Footer claims "Phases: 14/14" but no explicit Phase Gate Checklist section with `[x]` markers is visible. Data claims appear genuine given the specificity.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section with checkboxes; the footer just states "Phases: 14/14".

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirmed no upstream wikis were resolvable for the eMoney Platform (GPS/Modulr) external source.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Section: Footer/Shape** — No explicit Phase Gate Checklist with `[x]` / `[ ]` markers for P1–P3. Footer says "Phases: 14/14" but this is not verifiable from the wiki structure alone.

2. **Column: EpmTransactionStatus (#81)** — Description says "Sample: '1'" but the column is named "Status" suggesting human-readable text. The value '1' looks like the status *code*, not the status *description*. Possible conflation with EpmTransactionStatusCode (#73).

3. **Section 3.4 Gotchas** — States "Two WorkDate columns" and "Two Created columns" but doesn't give a definitive recommendation on which to use for each purpose beyond "prefer @WorkDate for date operations." Could be more prescriptive.

4. **Column: LoadType (#67)** — Values 0, 1, 2 are documented with percentages but no business meaning. The review-needed sidecar flags this, but the wiki description could explicitly state "meaning unknown — see review-needed."

5. **Section 2.1** — TransactionCode mapping (1=LOAD, 2=POS, 4=UNLOAD, 56=EPM_OUTBOUND, 57=EPM_INBOUND) is stated as fact but was inferred from sample data. Gaps in the sequence (3, 5–55) suggest potentially missing codes.

### Regeneration Feedback

1. Add an explicit Phase Gate Checklist section (or subsection) with `[x]`/`[ ]` markers for P1, P2, P3 to match the golden shape.
2. Verify EpmTransactionStatus (#81) vs EpmTransactionStatusCode (#73) — confirm whether '1' in #81 is actually a human-readable status or just another numeric code.
3. Add a note to LoadType (#67) and EpmMethodId (#69) explicitly marking the value mappings as "inferred from sample data — not confirmed."
4. In Section 3.4, add a definitive recommendation: "Use `@WorkDate` for all date operations, use `@Created` as the authoritative creation timestamp."
5. Add a missing-codes caveat to the TransactionCode mapping in Section 2.1 (gaps 3, 5–55 suggest undocumented types may exist).

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsActivities_AccountActivity-833937",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer/Shape",
      "problem": "No explicit Phase Gate Checklist with [x]/[ ] markers for P1-P3. Footer states 'Phases: 14/14' but the checklist section is missing from the wiki body."
    },
    {
      "severity": "medium",
      "column_or_section": "EpmTransactionStatus (#81)",
      "problem": "Description says 'Sample: 1' but column name suggests human-readable status text. Value '1' looks like a numeric code, potentially conflated with EpmTransactionStatusCode (#73)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 Gotchas",
      "problem": "Documents duplicate WorkDate and Created columns but lacks a definitive prescriptive recommendation on which is authoritative for each use case."
    },
    {
      "severity": "low",
      "column_or_section": "LoadType (#67)",
      "problem": "Values 0, 1, 2 documented with percentages but no business meaning assigned. Should explicitly note meanings are unknown and inferred from sample data only."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1 Transaction Direction",
      "problem": "TransactionCode mapping (1,2,4,56,57) stated as fact but inferred from sample. Gaps in sequence (3, 5-55) suggest potentially undocumented transaction types."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add explicit Phase Gate Checklist section with [x]/[ ] markers. (2) Verify EpmTransactionStatus vs EpmTransactionStatusCode — confirm whether '1' is a readable status or numeric code. (3) Mark LoadType and EpmMethodId value mappings as 'inferred from sample data — not confirmed'. (4) Add prescriptive recommendation for which WorkDate and Created column is authoritative. (5) Add missing-codes caveat to TransactionCode mapping.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
