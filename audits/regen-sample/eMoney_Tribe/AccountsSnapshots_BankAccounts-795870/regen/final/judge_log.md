I'll review this wiki systematically against the DDL, lineage, upstream bundle, and review-needed sidecar.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (25%)

**Sampled columns**: `@Id`, `etr_ym`, `SynapseUpdateDate`, `Created`, `partition_date`

All 8 columns are tagged Tier 3. The upstream bundle explicitly states: "NO UPSTREAM WIKI was resolvable for any source listed in the lineage." This is a raw Tribe API landing table with no Synapse-resident upstream. Every Tier 3 assignment is correct.

0 mismatches out of 5. No paraphrasing failures possible (no Tier 1 columns).

**Score: 10**

### Dimension 2 — Upstream Fidelity (20%)

Zero Tier 1 columns. The bundle confirms no upstream wiki exists. This is the neutral case.

**Score: 7** (neutral — no upstream wiki existed in bundle)

### Dimension 3 — Completeness (20%)

| Check | Result |
|---|---|
| All 8 sections present | YES (1–8) |
| Element count = DDL column count | YES (8/8) |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count + date range | YES (1.52B, 2023-12-20 to 2026-04-26) |
| Dictionary columns ≤15 values list inline pairs | N/A — no true dictionary columns; `etr_y` could list its few populated values but it's a free-text date field |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES — review-needed has no Section 4 |

9/10 (the dictionary-values check is borderline N/A but I'll credit it as not applicable rather than missing).

**Score: 8**

### Dimension 4 — Business Meaning (15%)

Section 1 is strong for a raw landing table:
- Names domain: eToro Money Tribe platform BankAccounts entity
- States grain: bank-account-level record within an account snapshot
- Names ETL consumer: `SP_eMoney_Reconciliation_ETLs`
- Explains bridge/link role — no business attributes, just FK associations
- Row count (1.52B) and date range present
- Explains `etr_` fields are mostly empty
- Explains naming convention (`{EntityGroup}_{SubEntity}-{NumericId}`)

An analyst would immediately know this is a bridge table, not to expect business columns, and how to join it.

**Score: 9**

### Dimension 5 — Data Evidence (10%)

Claims made:
- 1.52B rows, date range 2023-12-20 to 2026-04-26
- `@Id` and parent FK 100% identical (verified on 231.8M Q1 2026 rows per review-needed)
- `etr_` fields mostly empty strings, populated only Dec 2023/Jan 2024
- Specific count query patterns in Section 7

Footer says "Phases: 11/14" — 3 phases skipped. The Phase Gate Checklist is not shown inline, so I can't confirm P2/P3 completion. The data claims are specific and internally consistent (the review-needed corroborates with exact row counts), suggesting live queries were run. However, without explicit P2/P3 confirmation, I deduct moderately.

**Score: 6**

### Dimension 6 — Shape Fidelity (10%)

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES
- Real SQL in Section 7 with bracket-quoted special-character columns: YES
- Footer with quality score + phases: YES
- Property table format: YES
- Minor: no explicit Phase Gate Checklist section (some templates include it)

**Score: 9**

---

## T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no upstream wiki was resolvable.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| *(none)* | — | — | — | — |

---

## Top 5 Issues

1. **Medium — Footer phases**: Footer claims "Phases: 11/14" but no Phase Gate Checklist is shown in the wiki body. Without knowing which 3 phases were skipped, data claims cannot be fully verified.

2. **Low — `etr_y` inline values**: The `etr_y` column has a small finite set of populated values (likely just `2023`, `2024`). These could have been enumerated inline per the dictionary-column guideline.

3. **Low — Section 7.2 column references**: Query 7.2 references `snap.AccountId`, `snap.HolderId`, `snap.AvailableBalance`, `bank.BankAccountIban`, `bank.BankAccountStatus` from related tables — these column names are assumed but not verified against any wiki or DDL. If those columns don't exist with those exact names, the sample query breaks.

4. **Low — Refresh cadence vagueness**: "Continuous via Tribe data pipeline" is imprecise. Is this hourly, daily, event-driven? For a 1.52B-row table, refresh granularity matters for query planning.

5. **Low — `partition_date` derivation**: Wiki says `partition_date` "aligns with the date portion of Created" but lineage says "Date partition key derived from Created." If this is a computed column, it should be Tier 2, not Tier 3. However, since the exact derivation mechanism is in the pipeline (not a Synapse SP), Tier 3 is defensible.

---

## Regeneration Feedback

1. Add an explicit Phase Gate Checklist section showing which phases were completed and which were skipped, so data claims can be audited.
2. Enumerate the few populated values for `etr_y` (e.g., `2023`, `2024`) inline in the element description.
3. Verify column names used in Section 7.2 sample query (`AccountId`, `HolderId`, etc.) against the actual DDL of the referenced tables, or caveat them as illustrative.
4. Clarify refresh cadence — replace "Continuous" with the actual schedule (daily snapshot, hourly, etc.).

---

## Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*6 + 0.10*9
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.90
         = 8.35
```

**Verdict: PASS**

This is a well-constructed wiki for a raw API landing table with no upstream documentation. The writer correctly identified all columns as Tier 3, provided specific data observations, and clearly explained the table's bridge/link role. The issues are minor — mostly about completeness of phase documentation and sample query verification.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsSnapshots_BankAccounts-795870",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 11/14' but no Phase Gate Checklist section is shown in the wiki body. Without knowing which 3 phases were skipped, data claims (row counts, distribution analysis, etr_ population rates) cannot be independently verified."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y",
      "problem": "etr_y has a small finite set of populated values (likely just '2023', '2024') that should be enumerated inline per the dictionary-column guideline."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7.2",
      "problem": "Sample query references columns from related tables (snap.AccountId, snap.HolderId, snap.AvailableBalance, bank.BankAccountIban, bank.BankAccountStatus) that are assumed but not verified against those tables' DDL. Could produce errors if column names differ."
    },
    {
      "severity": "low",
      "column_or_section": "Property table — Refresh",
      "problem": "'Continuous via Tribe data pipeline' is imprecise. For a 1.52B-row table, analysts need to know whether refresh is hourly, daily, or event-driven to plan query timing."
    },
    {
      "severity": "low",
      "column_or_section": "partition_date",
      "problem": "Wiki says partition_date 'aligns with the date portion of Created' suggesting a derivation/transform, which could arguably be Tier 2 rather than Tier 3. However, since the derivation occurs in the pipeline (not a Synapse SP), Tier 3 is defensible."
    }
  ],
  "regeneration_feedback": "Minor improvements only (wiki passes): (1) Add an explicit Phase Gate Checklist section showing which of the 14 phases were completed vs skipped. (2) Enumerate the few populated etr_y values inline (e.g., '2023', '2024'). (3) Verify column names in Section 7.2 sample query against actual DDL of AccountsSnapshots_AccountSnapshot-956050 and AccountsSnapshots_BankAccount-393561 tables. (4) Replace 'Continuous via Tribe data pipeline' with actual refresh schedule.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "1.52B rows (Section 1, element 8 description)",
      "date range 2023-12-20 to 2026-04-26 (Section 1)",
      "100% match between @Id and parent FK (Section 2.1)",
      "etr_ fields mostly empty, only Dec 2023/Jan 2024 populated (Section 2.2)"
    ],
    "skipped_phases": ["3 of 14 phases skipped per footer, specific phases unknown"]
  }
}
</JUDGE_VERDICT>
