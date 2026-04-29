## Adversarial Review: eMoney_dbo.eMoney_Dictionary_AccountProgram

This is a 3-column, 3-row dictionary table — about as simple as they come. The writer had clean upstream documentation from `FiatDwhDB.Dictionary.AccountPrograms` and a straightforward Generic Pipeline ETL with no writer SP. The question is whether they executed the basics correctly.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 3 columns sampled (the entire table). AccountProgramID and AccountProgram are passthroughs from Dictionary.AccountPrograms with upstream wiki available → correctly Tier 1. UpdateDate is ETL metadata with no upstream column → correctly Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 9/10**
Both Tier 1 columns preserve the upstream description verbatim and append live enum values. No paraphrasing, no semantic loss, no dropped vendor names or NULL semantics. The additions (`0=Unknown, 1=card, 2=iban`) are sourced from live data and are strictly additive. One trivial formatting note: upstream uses "CODE-BACKED" confidence tier while the wiki uses "Tier 1" — this is expected schema translation, not a fidelity issue.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (3) matches DDL column count (3). Every element row has 5 cells with proper tier annotations. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (3) and date (2023-06-12). Dictionary values are listed inline. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checklist items.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToro Money fiat platform), row grain (one row per program type), exact values (card, iban, Unknown), ETL source (FiatDwhDB via Generic Pipeline Bronze), refresh status (static since 2023-06-12), and downstream consumers. A new analyst would immediately know what this table is and when to use it.

**Dimension 5 — Data Evidence: 7/10**
P2 (sample) is checked and data claims are consistent (3 rows, 0/1/2 values). P3 (distribution) is skipped, which is defensible for a 3-row dictionary but means no NULL-rate analysis was performed. All three columns are marked NULL in the DDL despite the upstream having NOT NULL on Id and Name — the wiki doesn't call out this discrepancy. Row count and enum values appear credible.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed list. Clean adherence to the golden shape. Minor: no explicit "Tier Legend" header text (uses "Confidence Tier Legend" which is acceptable).

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| AccountProgramID | "Lookup identifier. Primary key." | "Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban." | MINOR | None — upstream text preserved verbatim; live enum values appended |
| AccountProgram | "Human-readable name for this value." | "Human-readable name for this value. 0=Unknown, 1=card, 2=iban." | MINOR | None — upstream text preserved verbatim; live enum values appended |

---

### Top Issues

1. **(low) DDL nullability vs upstream**: DDL defines `AccountProgramID` and `AccountProgram` as `NULL`, but the upstream source has them as `NOT NULL` with a clustered PK on `Id`. The wiki doesn't flag this nullability widening, which could matter if analysts assume non-null guarantees.

2. **(low) P3 skipped**: Distribution analysis not performed. For a 3-row table this is reasonable, but the wiki asserts "should be rare in active data" about Unknown (0) without evidence from a distribution check.

3. **(info) UpdateDate static claim**: Wiki asserts "Static since 2023-06-12" based on P2 sample. If Generic Pipeline is still scheduled, this could change — the review-needed sidecar correctly flags this.

---

### Regeneration Feedback

No regeneration needed. If iterating:
1. Add a note in Section 3.4 or Section 4 that the DDL widens nullability from the upstream (source `Id` is `NOT NULL PK`, DWH `AccountProgramID` is `NULL`).
2. Consider running P3 to confirm no NULL values exist in AccountProgramID/AccountProgram despite the DDL allowing them.

---

### Weighted Score

```
0.25×10 + 0.20×9 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
= 2.50 + 1.80 + 2.00 + 1.35 + 0.70 + 0.90 = 9.25
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Dictionary_AccountProgram",
  "weighted_score": 9.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "AccountProgramID",
      "upstream_quote": "Lookup identifier. Primary key.",
      "wiki_quote": "Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban.",
      "match": "MINOR",
      "loss": "None — upstream text preserved verbatim; live enum values appended"
    },
    {
      "column": "AccountProgram",
      "upstream_quote": "Human-readable name for this value.",
      "wiki_quote": "Human-readable name for this value. 0=Unknown, 1=card, 2=iban.",
      "match": "MINOR",
      "loss": "None — upstream text preserved verbatim; live enum values appended"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "AccountProgramID, AccountProgram",
      "problem": "DDL defines both columns as NULL but upstream source has them as NOT NULL with a clustered PK on Id. The nullability widening is not documented in the wiki."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "Wiki asserts '0=Unknown should be rare in active data' but P3 distribution analysis was skipped — this claim is not evidence-backed."
    },
    {
      "severity": "info",
      "column_or_section": "UpdateDate",
      "problem": "Static-since-2023-06-12 claim is based on P2 sample only. Generic Pipeline may still be scheduled; review-needed sidecar correctly flags this."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3", "P5", "P6", "P7", "P9", "P9B", "P10"]
  }
}
</JUDGE_VERDICT>
