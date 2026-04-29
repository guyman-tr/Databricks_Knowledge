## Judge Review: DWH_dbo.Dim_CashoutReason

### Dimension 1 — Tier Accuracy: **6/10**

All 3 columns sampled (entire table). Tier assignments are correct:
- `CashoutReasonID`: passthrough, upstream wiki exists → Tier 1 ✓
- `Name`: passthrough, upstream wiki exists → Tier 1 ✓
- `UpdateDate`: ETL-computed GETDATE() → Tier 2 ✓

Zero tier mismatches (base 10). However, **both Tier 1 columns are paraphrased** rather than verbatim:
- `CashoutReasonID`: dropped "Joined by 15+ BackOffice/Billing/Trade procedures", reworded "Range 1-19" → "Values 1-19 in DWH", added "See Section 2.1" not in upstream. **-2**
- `Name`: dropped "No unique constraint", "customer-facing credit history", "via LEFT JOIN". Added example values not in upstream. **-2**

### Dimension 2 — Upstream Fidelity: **3/10**

Both Tier 1 columns fail verbatim check.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CashoutReasonID | "Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures." | "Primary key identifying the withdrawal reason. Values 1-19 in DWH. Stored in Billing.Withdraw and History.WithdrawAction on production. Special routing for IN (12, 14, 15) in Billing.WithdrawToFundingProcess. Default 16 (Requested by User) set in Billing.WithdrawRequestAdd. See Section 2.1 for full value map." | NO | Dropped "Joined by 15+ BackOffice/Billing/Trade procedures"; reworded "Range" → "Values"; reordered sentences; added "See Section 2.1" |
| Name | "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history." | "Human-readable withdrawal reason label. E.g., \"Requested by User\" (most common), \"PI Payment\", \"Foreclose account\". Displayed in BackOffice withdrawal screens and used in audit trails." | NO | Dropped "No unique constraint", "via LEFT JOIN", "customer-facing credit history", "reports"; added example values not present in upstream |

2 paraphrased → **3**.

### Dimension 3 — Completeness: **10/10**

- [x] All 8 sections present
- [x] Element count matches DDL (3 = 3)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (19 rows, as of 2026-03-11)
- [x] ≤15 values check N/A (19 values)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 = **10**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (withdrawal/cashout reasons), row grain (one row per reason), ETL SP (SP_Dictionaries_DL_To_Synapse), refresh pattern (daily TRUNCATE+INSERT), row count (19), production source (etoro.Dictionary.CashoutReason). An analyst reading this immediately knows what the table is and when to use it.

### Dimension 5 — Data Evidence: **7/10**

Row count present (19). All 19 values enumerated with IDs in Section 2.1. The "as of 2026-03-11" timestamp suggests live verification. No explicit Phase Gate Checklist with P2/P3 checkboxes — footer says "Phases: 7/14 (Simple-Dict Fast-Path)". Data claims appear grounded but the formal phase gate is absent.

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: no explicit Phase Gate Checklist section, but otherwise matches the golden shape.

---

### Weighted Total

```
0.25×6 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
= 1.50 + 0.60 + 2.00 + 1.35 + 0.70 + 0.90
= 7.05
```

### Top 5 Issues

1. **HIGH — `CashoutReasonID` (Element #1)**: Tier 1 description paraphrased. Dropped "Joined by 15+ BackOffice/Billing/Trade procedures", reworded "Range 1-19" → "Values 1-19 in DWH", reordered sentences, added non-upstream text "See Section 2.1 for full value map".
2. **HIGH — `Name` (Element #2)**: Tier 1 description paraphrased. Dropped "No unique constraint", "via LEFT JOIN", "customer-facing credit history", "reports". Added example values that are not in the upstream description.
3. **MEDIUM — Section 4**: Tier 1 descriptions must be **verbatim** copies of the upstream wiki. The writer enriched and reorganized them instead of quoting.
4. **LOW — Phase Gate Checklist**: No explicit P2/P3 checklist section. Footer mentions "Phases: 7/14" but the formal checklist is missing.
5. **LOW — `Dim_Manager` in bundle**: The upstream bundle incorrectly included `DWH_dbo.Dim_Manager` which has no relationship to `Dim_CashoutReason`. This is a harness issue, not a writer issue, but the writer correctly ignored it.

### Regeneration Feedback

1. Replace `CashoutReasonID` Element description with **verbatim** upstream: `"Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. (Tier 1 — upstream wiki, Dictionary.CashoutReason)"`
2. Replace `Name` Element description with **verbatim** upstream: `"Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. (Tier 1 — upstream wiki, Dictionary.CashoutReason)"`
3. Do NOT add example values, section cross-references, or any other text not present in the upstream wiki to Tier 1 descriptions. Enrichments belong in Section 2 (Business Logic), not in the Elements table.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_CashoutReason",
  "weighted_score": 7.05,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CashoutReasonID",
      "upstream_quote": "Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures.",
      "wiki_quote": "Primary key identifying the withdrawal reason. Values 1-19 in DWH. Stored in Billing.Withdraw and History.WithdrawAction on production. Special routing for IN (12, 14, 15) in Billing.WithdrawToFundingProcess. Default 16 (Requested by User) set in Billing.WithdrawRequestAdd. See Section 2.1 for full value map.",
      "match": "NO",
      "loss": "Dropped 'Joined by 15+ BackOffice/Billing/Trade procedures'; reworded 'Range 1-19' to 'Values 1-19 in DWH'; reordered sentences; added non-upstream text 'See Section 2.1 for full value map'"
    },
    {
      "column": "Name",
      "upstream_quote": "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history.",
      "wiki_quote": "Human-readable withdrawal reason label. E.g., \"Requested by User\" (most common), \"PI Payment\", \"Foreclose account\". Displayed in BackOffice withdrawal screens and used in audit trails.",
      "match": "NO",
      "loss": "Dropped 'No unique constraint', 'via LEFT JOIN', 'customer-facing credit history', 'reports'; added example values not in upstream"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CashoutReasonID (Element #1)",
      "problem": "Tier 1 description paraphrased. Dropped 'Joined by 15+ BackOffice/Billing/Trade procedures', reworded 'Range 1-19' to 'Values 1-19 in DWH', reordered sentences, added 'See Section 2.1 for full value map' which is not in the upstream wiki."
    },
    {
      "severity": "high",
      "column_or_section": "Name (Element #2)",
      "problem": "Tier 1 description paraphrased. Dropped 'No unique constraint', 'via LEFT JOIN', 'customer-facing credit history', 'reports'. Added example values ('Requested by User', 'PI Payment', 'Foreclose account') not present in upstream description."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 (Elements)",
      "problem": "Both Tier 1 columns are enriched/reorganized instead of being verbatim copies of the upstream wiki. Writer added context (examples, cross-references) that belongs in Section 2, not in Element descriptions."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer says 'Phases: 7/14 (Simple-Dict Fast-Path)' but the formal checklist is absent."
    },
    {
      "severity": "low",
      "column_or_section": "Upstream bundle",
      "problem": "Bundle included DWH_dbo.Dim_Manager which has no relationship to Dim_CashoutReason. Harness issue, not writer fault — writer correctly ignored it."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace CashoutReasonID Element description with VERBATIM upstream text: 'Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures.' (2) Replace Name Element description with VERBATIM upstream text: 'Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history.' (3) Do NOT add examples, section cross-references, or enrichments to Tier 1 descriptions — those belong in Section 2 (Business Logic).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
