Let me verify the production wiki that the review-needed sidecar mentions was found independently.
Now let me verify the SP reference to confirm the writer's claims about how this table is consumed.
Good — the SP usage is verified. Now let me do the full evaluation.

---

## Adversarial Wiki Review: eMoney_Tribe.CardsSnapshots_BankAccounts-83854

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns:

| Column | Claimed Tier | Verified Tier | Correct? |
|--------|-------------|---------------|----------|
| `@Id` | Tier 1 (Tribe source) | Passthrough from production wiki (which documents it as "PK. Referenced by BankAccount-341626.") | YES |
| `@CardsSnapshots_Account@Id-513255` | Tier 3 (no matching prod column) | Production has `@CardsSnapshots@Id-890718` (FK to root), not this column. Genuinely Synapse-specific. | YES |
| `etr_y` | Tier 3 (Generic Pipeline) | Pipeline-injected partition marker, no upstream wiki | YES |
| `Created` | Tier 1 (Tribe source) | Passthrough from production wiki ("Source timestamp.") | YES |
| `partition_date` | Tier 3 (Generic Pipeline) | Pipeline-derived, no upstream wiki | YES |

0 mismatches. No paraphrasing failures on Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **9/10**

Critical context: The upstream bundle declared "NO UPSTREAM WIKI was resolvable," but the writer independently located the production wiki at `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccounts-83854.md`. This was correct and proactive — the harness resolver missed the BankingDBs path.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| `@Id` | "PK. Referenced by BankAccount-341626." | "PK. Referenced by BankAccount-341626. Distribution key and clustered index. Contains GUIDs (e.g. '6381bdf9-...'). In sampled data, always equals @CardsSnapshots_Account@Id-513255." | YES | None — upstream text preserved verbatim at start; Synapse-specific context appended |
| `Created` | "Source timestamp." | "Source timestamp. Used by SP_eMoney_Reconciliation_ETLs as part of the incremental load watermark (MAX(Created)) in the card snapshot reconciliation pipeline." | YES | None — upstream text preserved verbatim at start; SP consumption context appended |

Both Tier 1 columns faithfully reproduce the upstream description verbatim, then append additional Synapse-specific context. No semantic loss. Score 9 rather than 10 because the appended text could make it harder to distinguish what's inherited vs. added — a minor style concern, not a fidelity failure.

### Dimension 3 — Completeness: **9/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present (## 1 … ## 8) | YES |
| Element count = DDL column count (8 = 8) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (86.4M, 2023-12-20 to 2026-04-26) |
| Dictionary columns ≤15 values list key=value pairs | N/A (no such columns) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 checks pass (1 N/A). Score: 9.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent for a bridge/collection table:
- Names the domain (eToro Money / Tribe card issuer platform)
- Clearly articulates row grain ("bank accounts collection record linked to a card snapshot account")
- Shows the full hierarchy diagram with this table's position
- Names the ETL SP consumer and how it uses the table (LEFT JOIN bridge)
- Includes row count (86.4M) and date range
- Describes the refresh pattern (daily Append via Generic Pipeline)
- Flags the 1:1 relationship anomaly and etr_* population gap

A brand-new analyst could immediately understand when to query this table and how it fits the card snapshot chain.

### Dimension 5 — Data Evidence: **7/10**

Positive:
- Row count (86.4M) and date range cited in Section 1
- Specific GUID example values
- 1:1 relationship observation backed by sampled data
- etr_* population pattern (populated 2023-12, empty 2024+) noted with specifics

Missing:
- No explicit Phase Gate Checklist with P2/P3 completion markers
- Footer says "Phases: 11/14" but doesn't enumerate which phases
- NULL-rate claims not systematically presented

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1-8: YES
- Tier legend in Section 4: YES
- Real SQL samples in Section 7: YES (3 practical queries)
- Footer with quality score and phases: YES
- Property table well-structured: YES
- Minor deviations: No Phase Gate Checklist section; Section 8 is "Atlassian Knowledge Sources" rather than a standard format

---

### Top 5 Issues

1. **(Low) Missing Phase Gate Checklist** — The footer claims "Phases: 11/14" but no explicit checklist shows which phases were completed. Without P2/P3 visibility, data claims can't be audited against the writer's methodology.

2. **(Low) etr_* columns — could note the partition value** — The etr_y/etr_ym/etr_ymd descriptions correctly note they're populated for 2023-12 only, but don't mention whether any downstream UC consumers might depend on these being populated (they don't appear to, but worth a sentence).

3. **(Info) Harness bundle miss** — The upstream bundle failed to resolve `Tribe.CardsSnapshots_BankAccounts-83854.md` from the BankingDBs path. The writer correctly found it independently. This is a harness issue, not a wiki issue, but future runs should fix the resolver.

4. **(Low) Section 5.2 pipeline diagram scope** — The diagram extends past the table's own lineage into its downstream consumption chain (ETL_CardSnapshot → UC Bronze). While informative, the UC Bronze export line at the bottom maps to this table's own bronze export, which is correct.

5. **(Info) @CardsSnapshots_Account@Id-513255 Tier 3 rationale** — Well-documented in both the wiki and review-needed sidecar. The production-to-Synapse FK divergence (root vs. intermediate) is clearly called out. No action needed.

### Regeneration Feedback

No regeneration required. Minor improvements for a future pass:
1. Add an explicit Phase Gate Checklist section showing which phases (P1-P3) were completed
2. Consider visually separating the verbatim upstream quote from the appended Synapse context in Tier 1 descriptions (e.g., with a semicolon or "Additionally: ...")
3. Fix the upstream bundle resolver to search BankingDBs paths

### Weighted Score

```
weighted = 0.25×10 + 0.20×9 + 0.20×9 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.80 + 1.80 + 1.35 + 0.70 + 0.80
         = 8.95
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "CardsSnapshots_BankAccounts-83854",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "@Id",
      "upstream_quote": "PK. Referenced by BankAccount-341626.",
      "wiki_quote": "PK. Referenced by BankAccount-341626. Distribution key and clustered index. Contains GUIDs (e.g. \"6381bdf9-108b-4554-b8a2-bd94f1ad2fad\"). In sampled data, always equals @CardsSnapshots_Account@Id-513255.",
      "match": "YES",
      "loss": "None — upstream text preserved verbatim at start; Synapse-specific context appended"
    },
    {
      "column": "Created",
      "upstream_quote": "Source timestamp.",
      "wiki_quote": "Source timestamp. Used by SP_eMoney_Reconciliation_ETLs as part of the incremental load watermark (MAX(Created)) in the card snapshot reconciliation pipeline.",
      "match": "YES",
      "loss": "None — upstream text preserved verbatim at start; SP consumption context appended"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 11/14' but no explicit Phase Gate Checklist section enumerates which phases were completed, making it impossible to audit P2/P3 data-gathering claims."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Descriptions correctly note population for 2023-12 only, but don't confirm no downstream UC consumers depend on these fields being populated."
    },
    {
      "severity": "info",
      "column_or_section": "Upstream Bundle",
      "problem": "Harness bundle resolver failed to find Tribe.CardsSnapshots_BankAccounts-83854.md at knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/. Writer correctly found it independently. Harness resolver should be updated to search BankingDBs paths."
    },
    {
      "severity": "info",
      "column_or_section": "@CardsSnapshots_Account@Id-513255",
      "problem": "Tier 3 is correct — production has @CardsSnapshots@Id-890718 (FK to root) while Synapse has @CardsSnapshots_Account@Id-513255 (FK to intermediate Account-513255). Structural divergence well-documented in review-needed sidecar."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 86.4M and date range 2023-12-20 to 2026-04-26 in Section 1",
      "1:1 relationship between @Id and @CardsSnapshots_Account@Id-513255 noted from sampled data",
      "etr_* population pattern (2023-12 only, empty 2024+) from data observation"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
