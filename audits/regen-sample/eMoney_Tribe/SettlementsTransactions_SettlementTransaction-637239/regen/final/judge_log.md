## Review: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: TransactionAmount (#26, Tier 3 passthrough from FiatDwhDB.Tribe — correct, no upstream wiki), etr_y (#105, Tier 2 Generic Pipeline — correct, computed from Created), MerchantCity (#63, Tier 3 — correct), partition_date (#109, Tier 2 — correct, derived by pipeline), CardPresent (#68, Tier 3 — correct). All 5 match. The bundle confirms **zero upstream wikis** were resolvable, so Tier 3 for all business columns and Tier 2 for framework columns is the only defensible assignment.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist. The upstream bundle explicitly states: "NO UPSTREAM WIKI was resolvable for any source listed in the lineage." This is a legitimate neutral scenario — the writer cannot inherit what does not exist. The review-needed sidecar correctly flags this as a future action item.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

No Tier 1 columns exist. All 107 business columns are Tier 3 (no upstream wiki), and 5 framework columns are Tier 2 (Generic Pipeline). This is correct given the bundle contents.

### Dimension 3 — Completeness: **9/10** → score 8

Checklist:
- [x] All 8 sections present (`## 1.` through `## 8.`)
- [x] Element count matches DDL: 112/112
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (2,942,573) and date range (2021-09-05 to 2026-04-25)
- [x] Dictionary columns list inline values (TransactionClass with percentages, EntryModeCode with code=value, CardPresent with values)
- [ ] `.review-needed.md` does NOT contain `## 4. Elements` — passes ✓

One minor miss: no explicit Phase Gate Checklist section within the body (footer says "Phases: 11/14" but the checklist itself is absent as a visible section).

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the specific domain (eMoney Tribe settlement transactions / card payment clearing), row grain (single settlement transaction), production source with server name (`prod-banking`), ETL pattern (Generic Pipeline #538, Append, daily, parquet), downstream consumer (`SP_eMoney_Reconciliation_ETLs` with JOIN pattern), row count (2.9M), and date range. The "Data characteristics" paragraph adds the all-varchar caveat and the Visa-only BIN. A new analyst would know exactly when and how to query this table.

### Dimension 5 — Data Evidence: **7/10**

Strong evidence of live data usage: specific row count (2,942,573), date range, TransactionClass distribution with percentages (Domestic 94%, Interregional 5%, Regional <1%, Unknown <0.1%), specific sampled values for FeeGroupName ("eToro Green", "eToro Black"), BIN ("459688"), ProgramName ("eToro Money UK GBP"), CycleFileId format ("20220505-08-459688"). However, the footer says "Phases: 11/14" suggesting 3 phases were skipped, and no explicit Phase Gate Checklist is present in the body to confirm which data-validation phases completed.

### Dimension 6 — Shape Fidelity: **8/10**

All numbered sections present, tier legend in Section 4, real SQL in Section 7 (three queries with proper bracket-escaping for the hyphenated table name), footer has quality score, tier breakdown, and phases-completed. Minor deviation: Section 8 is "Atlassian Knowledge Sources" rather than a more standard references section, and no explicit Phase Gate Checklist section appears in the body.

### Weighted Total

```
0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
= 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
= 8.35
```

**Verdict: PASS**

### Top 5 Issues

1. **No Phase Gate Checklist section** — Footer claims "Phases: 11/14" but the body never shows which phases were completed or skipped, making it impossible to verify data evidence claims.
2. **@Created vs Created ambiguity** — Two columns exist: `@Created` (#1, datetime2) and `Created` (#111, datetime2). The wiki says `@Created` is "DWH ingestion timestamp" and `Created` is "source system timestamp," but both have identical types and unclear differentiation. The etr_y/etr_ym/etr_ymd columns reference "Created timestamp" without specifying which one.
3. **SettlementFlag values unexplained** — Values "8" and "0" are listed but their business meaning is unknown. The review-needed sidecar flags this correctly.
4. **MtiCode description may be inaccurate** — Wiki says sampled value "0100" is "authorization request," but this is a *settlement* file — MTI 0100 would be unusual in settlement data (more likely 0220/0230 for presentments). This looks like the writer applied ISO 8583 knowledge without verifying context.
5. **Redundant index not flagged in Section 3 properties** — The gotchas section correctly notes duplicate `@Id` indexes, but the property table lists all 4 NCIs without noting the redundancy.

### Regeneration Feedback

1. Add an explicit Phase Gate Checklist section showing which phases (P1–P14) were completed and which were skipped, so data evidence claims can be verified.
2. Clarify the distinction between `@Created` (element #1) and `Created` (element #111) — specify which one the Generic Pipeline uses as the source for `etr_y`/`etr_ym`/`etr_ymd`/`partition_date`.
3. Verify the MtiCode sampled value "0100" — in a settlement file context, the expected MTI would typically be 0220/0230 (presentment/advice), not 0100 (authorization request). If "0100" is genuinely in the data, note that it appears anomalous for settlement records.
4. When upstream FiatDwhDB.Tribe wiki becomes available, re-run to promote Tier 3 columns to Tier 1 with verbatim descriptions.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "SettlementsTransactions_SettlementTransaction-637239",
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
      "column_or_section": "Section body (missing Phase Gate Checklist)",
      "problem": "Footer claims 'Phases: 11/14' but no Phase Gate Checklist section exists in the body to show which phases were completed or skipped. Data evidence claims cannot be independently verified."
    },
    {
      "severity": "medium",
      "column_or_section": "@Created (#1) vs Created (#111)",
      "problem": "Two datetime2(7) columns with similar names. Wiki says @Created is 'DWH ingestion timestamp' and Created is 'source system timestamp', but etr_y/etr_ym/etr_ymd descriptions reference 'Created timestamp' ambiguously — unclear which column is the actual source for the partition derivation."
    },
    {
      "severity": "low",
      "column_or_section": "SettlementFlag (#94)",
      "problem": "Values '8' and '0' listed but business meaning unknown. Review-needed sidecar flags this correctly but the wiki description provides no interpretation."
    },
    {
      "severity": "low",
      "column_or_section": "MtiCode (#19)",
      "problem": "Wiki states sampled value '0100' is 'authorization request' but this is a settlement file — MTI 0100 is unusual in settlement context (expected 0220/0230 for presentments). May be an incorrect domain-knowledge inference."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3 / Synapse Index property",
      "problem": "Property table lists all 4 NCIs without noting the redundancy of ClusteredIndex_ST_637239 and idx_637239_Id (both on @Id). Gotchas section mentions it but the property row does not."
    }
  ],
  "regeneration_feedback": "No regeneration needed (PASS). For future improvement: (1) Add explicit Phase Gate Checklist section. (2) Clarify which 'Created' column (@Created vs Created) feeds etr_y/etr_ym/etr_ymd/partition_date. (3) Verify MtiCode '0100' is genuinely present in settlement data. (4) Re-run when FiatDwhDB.Tribe upstream wiki becomes available to promote Tier 3 to Tier 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "TransactionClass: Domestic 94%, Interregional 5%, Regional <1%, Unknown <0.1%"
    ],
    "skipped_phases": ["3 of 14 phases skipped per footer — specific phases unknown"]
  }
}
</JUDGE_VERDICT>
