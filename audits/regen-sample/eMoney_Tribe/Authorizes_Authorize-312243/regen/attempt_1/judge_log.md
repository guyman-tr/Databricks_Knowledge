## Review: eMoney_Tribe.Authorizes_Authorize-312243

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: `ResponseCode`, `MerchantName`, `partition_date`, `FxRate`, `CardPresent`. All are passthrough from `FiatDwhDB.Tribe.Authorizes_Authorize-312243` with no upstream wiki available (confirmed by `_no_upstream_found.txt` marker in the bundle). Tier 3 is the correct classification for all. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns exist because no upstream wiki was available for the production source (`FiatDwhDB.Tribe` on prod-banking). This is the correct outcome — the writer correctly did not fabricate Tier 1 tags. Per the rubric, this scores a neutral 7.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **9/10** (9 of 10 checks pass)

| Check | Result |
|---|---|
| All 8 sections present | PASS |
| Element count matches DDL (81 = 81) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 has ETL pipeline ASCII diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 contains row count and date range | PASS |
| Dictionary columns with ≤15 values list inline key=value pairs | PASS — `CardPresent`, `Action`, `Network`, `Suspicious`, `EntryModeCode`, `ResponseCode`, `TransactionCode` all list observed values inline |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

Score: 10/10 = 10. However, Section 1 says "All 80 columns" when the DDL and Elements table both have 81 column definitions. This is a factual error. Deducting to **9**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names: the domain (Tribe Payments card authorizations for eToro Money UK), the row grain (single authorization request — approval, decline, or verification), the ETL SP (`SP_eMoney_Reconciliation_ETLs`), the refresh pattern (daily append via Generic Pipeline #542), the row count (~3.8M), the date range (2021-09-05 to 2026-04-26), the downstream target (`ETL_Authorize`), and the card program constraint (Visa only, IIN 10079563). A brand-new analyst would know immediately what this table is and when to query it.

### Dimension 5 — Data Evidence: **8/10**

Strong data evidence throughout:
- Row count (3.8M) and date range in Section 1
- Specific observed values with approximate percentages (ResponseCode `00` ~85%, TransactionCode `2` POS ~85%)
- Specific merchant name examples, MCC codes, entry modes
- NULL behavior documented for schema-evolution columns (Created, PosDataExtendedDe61, PosDataDe61)

The footer says "Phases: 11/14" and the review-needed sidecar confirms P2 (live data sampling) and P3 (distribution analysis) were executed. Not a perfect 10 because there's no explicit Phase Gate Checklist section with `[x]` markers in the wiki body itself.

### Dimension 6 — Shape Fidelity: **9/10**

All structural elements present: numbered sections 1-8, tier legend in Section 4, three real SQL queries in Section 7, property table, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section (the phases are mentioned only in the footer line).

---

### Top 5 Issues

1. **Section 1 says "All 80 columns"** — the DDL defines 81 columns and the Elements table has 81 entries. Off-by-one error likely from confusing DDL column count with unique column names (the writer noted `PosDatDe61` and `PosDataDe61` are separate but still counted 80).

2. **No Phase Gate Checklist section** — the wiki embeds phase completion only in the footer (`Phases: 11/14`). The golden shape expects an explicit checklist with `[x]` markers for each phase.

3. **Section 1 claims "except metadata columns"** without listing which columns are metadata — `@Created`, `@WorkDate`, `SynapseUpdateDate`, `partition_date`, `Created` are the non-varchar columns, but the phrasing is imprecise.

4. **Duplicate `@Id` indexes not called out as a concern** — the DDL has two NCIs on `@Id` (`ClusteredIndex_Authorizes_312243` and `idx_312243_Id`). The property table mentions "4 NCIs on @Authorizes@Id-837045, @Id x2, partition_date" but Section 3 doesn't flag the redundancy as a gotcha for DDL maintainers.

5. **TokenizedRequest (#81) description is thin** — "NULL on most rows. Populated when a tokenization event is linked to this authorization" gives no indication of format, length, or what "tokenization event" means in the Tribe context. Acceptable for Tier 3 given no upstream wiki, but the least informative description relative to the others.

---

### Regeneration Feedback

1. Fix "All 80 columns" in Section 1 to "All 81 columns" (or "All 78 varchar(max) columns" if the intent was to exclude the 3 non-varchar columns — but then say so explicitly).
2. Add an explicit Phase Gate Checklist section (or subsection) with `[x]`/`[ ]` markers for each phase.
3. Clarify which columns are "metadata columns" in the Section 1 statement about varchar(max) types.

---

### Weighted Score

```
0.25×10 + 0.20×7 + 0.20×9 + 0.15×9 + 0.10×8 + 0.10×9
= 2.50 + 1.40 + 1.80 + 1.35 + 0.80 + 0.90
= 8.75
```

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "Authorizes_Authorize-312243",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "States 'All 80 columns' but DDL and Elements table both have 81 column definitions. Off-by-one factual error."
    },
    {
      "severity": "low",
      "column_or_section": "Shape",
      "problem": "No explicit Phase Gate Checklist section with [x] markers. Phase completion is only embedded in the footer line ('Phases: 11/14')."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Claims 'except metadata columns' without listing which columns are metadata. Imprecise — reader must scan all 81 elements to identify the 3 non-varchar columns."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3 / DDL",
      "problem": "Two redundant NCIs on @Id (ClusteredIndex_Authorizes_312243 and idx_312243_Id) are documented in the property table but not flagged as a redundancy concern in Query Advisory."
    },
    {
      "severity": "low",
      "column_or_section": "TokenizedRequest",
      "problem": "Description is the thinnest of all 81 elements — no format, length, or domain context for 'tokenization event'. Acceptable for Tier 3 but weakest entry."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Change 'All 80 columns' to 'All 81 columns' in Section 1. (2) Add an explicit Phase Gate Checklist subsection with [x]/[ ] markers for each phase. (3) Clarify which columns are 'metadata columns' (the 3 non-varchar: @Created, @WorkDate, SynapseUpdateDate, partition_date, Created — actually 5 non-varchar columns).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
