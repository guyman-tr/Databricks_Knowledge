## Adversarial Review: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239

### Core Finding

The upstream bundle explicitly states: **"NO UPSTREAM WIKI was resolvable for any source listed in the lineage."** Yet the writer tagged 4 columns as Tier 1 (`@Created`, `@Id`, `@SettlementsTransactions@Id-333243`, `Created`). These descriptions are writer-composed, not verbatim quotes from any upstream wiki — because no upstream wiki exists. All 4 should be Tier 3.

---

### Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled 5 columns: `@Id` (tagged T1, should be T3 — no upstream wiki), `TransactionAmount` (T3, correct), `etr_y` (T2, correct), `Created` (tagged T1, should be T3), `MerchantName` (T3, correct). 2 mismatches out of 5. All 4 claimed Tier 1 columns are incorrect — the bundle is unambiguous that no upstream wiki was available. No paraphrasing deduction applies (there's nothing TO paraphrase from).

**Dimension 2 — Upstream Fidelity: 5/10**
The writer fabricated Tier 1 status for 4 columns. The descriptions attributed as "(Tier 1 — FiatDwhDB.Tribe...)" are entirely writer-composed content, not verbatim quotes. The neutral score of 7 applies when the writer *correctly* identifies there's no upstream and uses Tier 3. Here, the writer misrepresented the situation.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 112 elements match DDL's 112 columns exactly. Every element row has 5 cells. Every description ends with tier annotation. Property table complete. ASCII pipeline diagram present with real names. Footer has tier breakdown. Section 1 has row count (2,942,573) and date range (2021-09-05 to 2026-04-25). Enum values listed inline for TransactionClass, CardPresent, EntryModeCode, etc. Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eMoney Tribe card payment settlements), row grain (single settlement transaction), ETL pattern (Generic Pipeline #538, Append, daily), downstream consumer (SP_eMoney_Reconciliation_ETLs with INNER JOIN), data characteristics (all varchar(max), Visa-only, predominantly GBP domestic). An analyst reading this knows exactly when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (2,942,573) and date range present. Specific enum distributions given (TransactionClass: Domestic 94%, Interregional 5%). Sampled values cited throughout (BIN 459688, FeeGroupName values, MCC examples). Footer says "Phases: 11/14" but doesn't explicitly confirm P2/P3 completion status. Distribution percentages appear credible but unverifiable from this review.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend, real SQL in Section 7, footer with quality score and phases. Section 8 is thin (just a Freshservice reference). Minor: no explicit Phase Gate Checklist section.

---

### T1 Fidelity Table

All 4 claimed Tier 1 columns are invalid — no upstream wiki existed in the bundle to quote from.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| @Created | *No upstream wiki exists* | "DWH timestamp." | NO | Fabricated Tier 1 — no upstream wiki was available; should be Tier 3 |
| @Id | *No upstream wiki exists* | "PK. Unique GUID identifier for this settlement transaction record..." | NO | Fabricated Tier 1 — writer-composed description tagged as upstream verbatim |
| @SettlementsTransactions@Id-333243 | *No upstream wiki exists* | "FK to parent. Links to the parent SettlementsTransactions-333243 container record..." | NO | Fabricated Tier 1 — no upstream wiki was available; should be Tier 3 |
| Created | *No upstream wiki exists* | "Source timestamp. Timestamp of when the settlement record was created in the source system..." | NO | Fabricated Tier 1 — writer-composed description tagged as upstream verbatim |

---

### Top 5 Issues

1. **HIGH — @Created, @Id, @SettlementsTransactions@Id-333243, Created (Tier misattribution)**: All 4 columns tagged Tier 1 but the upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable." These must be Tier 3. The writer fabricated a Tier 1 origin that doesn't exist.

2. **MEDIUM — Tier legend text is misleading**: The Tier 1 legend says "Verbatim from upstream production wiki (FiatDwhDB.Tribe)" — but no such wiki exists. The legend itself is honest, but the writer then violated it by tagging columns as Tier 1 anyway.

3. **LOW — Footer tier counts are wrong**: Footer claims "4 T1" — should be "0 T1, 5 T2, 107 T3" after correction.

4. **LOW — review-needed sidecar contradicts wiki**: The review-needed file (Section 1) acknowledges the upstream wiki "only documents 4 columns explicitly" — but the bundle says NO wiki was resolvable at all. The writer may have accessed a wiki outside the bundle, which is not the ground truth for this review.

5. **LOW — Duplicate index documentation**: The wiki correctly identifies the duplicate NCIs on `@Id` (ClusteredIndex_ST_637239 and idx_637239_Id) in both Section 3 and the Gotchas — good catch, but this is an observation, not a wiki deficiency.

---

### Regeneration Feedback

1. **Re-tag all 4 Tier 1 columns as Tier 3**: Change `@Created`, `@Id`, `@SettlementsTransactions@Id-333243`, and `Created` to `(Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki)`. No upstream wiki was provided in the bundle.
2. **Update footer tier counts**: Change from "4 T1, 5 T2, 103 T3" to "0 T1, 5 T2, 107 T3".
3. **Update Tier 1 legend**: Either remove the Tier 1 row from the legend or note that no Tier 1 columns exist for this table.
4. **Keep all other content as-is**: The business meaning, completeness, evidence, and shape are strong. Only the tier misattribution needs correction.

---

### Weighted Score Calculation

```
weighted = 0.25*5 + 0.20*5 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 1.25 + 1.00 + 2.00 + 1.35 + 0.70 + 0.80
         = 7.10
```

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "SettlementsTransactions_SettlementTransaction-637239",
  "weighted_score": 7.10,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "@Created",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "DWH timestamp. (Tier 1 — FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239)",
      "match": "NO",
      "loss": "Fabricated Tier 1 — no upstream wiki was available; should be Tier 3"
    },
    {
      "column": "@Id",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "PK. Unique GUID identifier for this settlement transaction record. Indexed by ClusteredIndex_ST_637239 and idx_637239_Id. Used as the primary JOIN key to sibling tables (RiskActions-236807, SecurityChecks-426253) and parent table (SettlementsTransactions-333243). (Tier 1 — FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239)",
      "match": "NO",
      "loss": "Fabricated Tier 1 — writer-composed description attributed as upstream verbatim; no upstream wiki exists"
    },
    {
      "column": "@SettlementsTransactions@Id-333243",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "FK to parent. Links to the parent SettlementsTransactions-333243 container record. Contains identical GUID values to @Id in sampled data (1:1 relationship). Indexed by ClusteredIndex_ST_637239_c2. (Tier 1 — FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239)",
      "match": "NO",
      "loss": "Fabricated Tier 1 — no upstream wiki was available; should be Tier 3"
    },
    {
      "column": "Created",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "Source timestamp. Timestamp of when the settlement record was created in the source system (FiatDwhDB.Tribe). Used as the incremental load watermark by SP_eMoney_Reconciliation_ETLs (WHERE @Created >= @SettlementsTransactions_DATE). (Tier 1 — FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239)",
      "match": "NO",
      "loss": "Fabricated Tier 1 — writer-composed description attributed as upstream verbatim; no upstream wiki exists"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "@Created, @Id, @SettlementsTransactions@Id-333243, Created",
      "problem": "All 4 columns tagged Tier 1 but the upstream bundle explicitly states 'NO UPSTREAM WIKI was resolvable for any source listed in the lineage.' These are writer-composed descriptions falsely attributed as verbatim upstream quotes. Must be re-tagged as Tier 3."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Tier 1 legend reads 'Verbatim from upstream production wiki (FiatDwhDB.Tribe)' but no such wiki exists in the bundle. Legend is technically correct in definition but the writer violated it by tagging columns as Tier 1 anyway."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '4 T1, 5 T2, 103 T3' — should be '0 T1, 5 T2, 107 T3' after correcting the fabricated Tier 1 assignments."
    },
    {
      "severity": "low",
      "column_or_section": "review-needed sidecar Section 1",
      "problem": "Sidecar references 'upstream production wiki (Tribe.SettlementsTransactions_SettlementTransaction-637239.md)' as if it exists and documents 4 columns — but the bundle says NO upstream wiki was resolvable. Writer may have accessed a source outside the provided bundle."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.1",
      "problem": "Duplicate NCI documentation is accurate (ClusteredIndex_ST_637239 and idx_637239_Id both on @Id) — correctly identified but not a wiki deficiency."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag @Created, @Id, @SettlementsTransactions@Id-333243, and Created as Tier 3 — no upstream wiki was available in the bundle. (2) Update footer tier counts from '4 T1, 5 T2, 103 T3' to '0 T1, 5 T2, 107 T3'. (3) Remove or annotate the Tier 1 legend row to indicate no Tier 1 columns exist for this table. (4) Keep all other content — business meaning, completeness, evidence, and shape are strong.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "TransactionClass: Domestic 94%, Interregional 5%, Regional <1%, Unknown <0.1%",
      "Row count: 2,942,573",
      "Date range: 2021-09-05 to 2026-04-25"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
