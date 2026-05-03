## Review: EXW_Wallet.Requests

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: Id, Gcid, RequestTypeId, DetailsJson, partition_date. All are passthroughs (or a CAST-derived column) from WalletDB.Wallet.Requests, which has **no upstream wiki** in the bundle. Tier 3 is the correct assignment for all. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are zero Tier 1 columns because no upstream wiki exists. The bundle explicitly confirms: "NO UPSTREAM WIKI was resolvable for any source listed in the lineage." This is not the writer's fault — the neutral score of 7 applies per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checklist items)

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL count (13/13) | YES |
| Every element has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has required fields | YES |
| Section 5.2 has ASCII pipeline diagram | YES |
| Footer has tier breakdown | YES |
| Section 1 has row count + date range | YES |
| Dictionary columns ≤15 values listed inline | PARTIAL — RequestTypeId lists all 10 values inline in the element description, but CryptoId only lists 4 sample values with "based on sample data" caveat rather than the full dictionary |
| review-needed does NOT contain `## 4. Elements` | YES |

Score: 9/10 → 8.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (crypto wallet operations), the row grain (single wallet operation request per customer), the production source (WalletDB.Wallet.Requests), the ETL pattern (Generic Pipeline, Append, daily), row count (5.0M), date range (July 2018–present), and the two downstream consumers with their specific filter predicates. An analyst can immediately determine when and why to query this table.

### Dimension 5 — Data Evidence: **7/10**

Strong data grounding: 5.0M row count, date range from 2018-07-11, per-type distribution with approximate counts (CreateWallet ~2.5M, SendTransaction ~1.3M, etc.), 100% NULL rates for DeviceId and etr_* columns, ~50% NULL for DetailsJson. Footer says "Phases: 11/14" implying 3 phases skipped, but the data claims are specific and internally consistent. Slight deduction for not having an explicit P2/P3 checkbox section.

### Dimension 6 — Shape Fidelity: **8/10**

Follows the golden shape well: numbered sections 1–8, tier legend in Section 4, three real SQL examples in Section 7 with proper JOINs, footer with quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section with checkboxes, and the quality score format is slightly abbreviated.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

**Verdict: PASS**

### Top 5 Issues

1. **CryptoId dictionary incomplete** (low) — Only 4 sample values listed (1=Bitcoin, 2=Ethereum, 6=Litecoin, 18=Cardano) with "based on sample data" qualifier. Should query EXW_Wallet.CryptoTypes for the full dictionary if ≤15 values.

2. **No Phase Gate Checklist section** (low) — The footer references "Phases: 11/14" but there's no explicit checklist showing which phases were completed vs. skipped. This makes it harder to audit data-claim provenance.

3. **partition_date tier classification** (minor) — partition_date is a CAST(Timestamp AS DATE) transform. One could argue this is Tier 2 (ETL-computed), not Tier 3. However, since the source column (Timestamp) itself has no upstream wiki, Tier 3 is defensible. Borderline.

4. **Section 8 is empty** (minor) — "No Atlassian sources searched (regen harness mode)" is honest but a missed opportunity. If Jira/Confluence has wallet-related documentation, it should eventually be linked.

5. **DetailsJson schema documentation** (minor) — The review-needed sidecar correctly flags this. The wiki lists schemas for types 1 and 4 but says "schema unknown" for types 2, 3, 5, 6, 7, 8, 9. This is honest but limits analyst utility.

### Regeneration Feedback

No regeneration required (PASS). For future improvement:
1. Query `EXW_Wallet.CryptoTypes` for the full CryptoId dictionary and list inline in the element description.
2. Add an explicit Phase Gate Checklist section with `[x]`/`[ ]` markers.
3. Consider upgrading partition_date to Tier 2 with note "CAST(Timestamp AS DATE), no upstream wiki for source column."

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "Requests",
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
      "column_or_section": "CryptoId",
      "problem": "Only 4 sample CryptoId values listed (1=Bitcoin, 2=Ethereum, 6=Litecoin, 18=Cardano) with 'based on sample data' caveat. Should query EXW_Wallet.CryptoTypes for the full dictionary if ≤15 entries."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] markers. Footer says 'Phases: 11/14' but does not identify which 3 phases were skipped, making data-claim provenance harder to audit."
    },
    {
      "severity": "minor",
      "column_or_section": "partition_date",
      "problem": "Tagged Tier 3 but is a CAST(Timestamp AS DATE) transform. Could be argued as Tier 2 (ETL-computed). Defensible as Tier 3 since source column has no upstream wiki, but borderline."
    },
    {
      "severity": "minor",
      "column_or_section": "Section 8",
      "problem": "Empty Atlassian section — regen harness skipped Jira/Confluence search. Wallet team documentation may exist but was not linked."
    },
    {
      "severity": "minor",
      "column_or_section": "DetailsJson",
      "problem": "JSON schema documented for RequestTypeId 1 and 4 only. Types 2, 3, 5, 6, 7, 8, 9 listed as 'schema unknown'. Limits analyst utility for parsing non-Send/Conversion requests."
    }
  ],
  "regeneration_feedback": "No regeneration required (PASS). For incremental improvement: (1) Query EXW_Wallet.CryptoTypes for full CryptoId dictionary and list inline. (2) Add explicit Phase Gate Checklist section. (3) Consider Tier 2 for partition_date.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "5.0M rows",
      "July 2018 to present",
      "CreateWallet ~2.5M rows",
      "SendTransaction ~1.3M",
      "DeviceId 100% NULL",
      "etr_* 100% NULL",
      "DetailsJson ~50% NULL"
    ],
    "skipped_phases": ["Phases 11/14 — 3 unidentified phases skipped"]
  }
}
</JUDGE_VERDICT>
