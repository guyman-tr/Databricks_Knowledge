## Judge Review: DWH_dbo.Dim_MoveMoneyReason

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 6/10**
All 3 columns have correct tier assignments (MoveMoneyReasonID=T1, MoveMoneyReason=T1, UpdateDate=T3). However, both Tier 1 columns are paraphrased rather than verbatim from the upstream Dictionary.MoveMoneyReason wiki. That is -2 per paraphrasing failure on the two T1 columns (10 - 2 - 2 = 6).

**Dimension 2 — Upstream Fidelity: 3/10**
Both Tier 1 columns are substantially paraphrased. MoveMoneyReasonID drops "Referenced by 50+ credit/balance procedures" and rewrites the opening. MoveMoneyReason drops "credit history" and "BackOffice audit screens" from the display context. 2+ paraphrased = 3.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 3 DDL columns = 3 wiki elements. All element rows have 5 cells with tier tags. Property table complete. ASCII pipeline diagram present with real object names. Footer has tier breakdown. Row count in Section 1. Dictionary values listed inline. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent — names domain (money movement reason codes), grain (one row per reason), documents the 4-vs-9 gap with production, flags the critical missing ID=5 and its downstream impact on Fact_CustomerAction ActionTypeID derivation, and notes the manual-insert refresh pattern. Highly actionable for a new analyst.

**Dimension 5 — Data Evidence: 7/10**
Row count (4 rows) and specific ID-to-label mappings present. UpdateDate values cited with exact dates (2022-03-27, 2022-11-13). No explicit Phase Gate P2/P3 checkboxes, but data claims appear grounded in live queries. Footer says 11/14 phases.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: no explicit Phase Gate Checklist section.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| MoveMoneyReasonID | "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures." | "Internal money movement reason identifier. DWH values: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop (DWH-only label). Production has additional IDs 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment - all absent from DWH. ID=5 is critical: used in SP_Fact_CustomerAction to derive ActionTypeID 44 (internal deposit) and 45 (internal withdrawal)." | NO | Dropped "Referenced by 50+ credit/balance procedures". Rewrote opening ("Unique identifier" → "Internal ... identifier"). Added DWH-specific context (good) but upstream text is not verbatim. |
| MoveMoneyReason | "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens." | "Human-readable money movement reason label. DWH labels: Adjustment, Bonus Abuser, Staking, Airdrop. Column name intentionally matches table name (denormalized pattern per upstream wiki). Used in financial reporting and account statements. Note: DWH label 'Airdrop' for ID=4 diverges from production where ID=4 is marked deprecated." | NO | Dropped "credit history" and "BackOffice audit screens" from display contexts. Rewrote "Displayed in" → "Used in financial reporting and". |

---

### Top 5 Issues

1. **HIGH — MoveMoneyReasonID**: Tier 1 description is paraphrased. Upstream says "Unique identifier for the money movement reason" — wiki says "Internal money movement reason identifier". Upstream's "Referenced by 50+ credit/balance procedures" is completely dropped.

2. **HIGH — MoveMoneyReason**: Tier 1 description is paraphrased. Upstream lists three display contexts (account statements, credit history, BackOffice audit screens) — wiki drops two of them and substitutes "financial reporting" which does not appear in the upstream.

3. **MEDIUM — MoveMoneyReason tier tag**: Tagged as `(Tier 1 - upstream wiki, Dictionary.MoveMoneyReason + Tier 3 - live data sampling)` — hybrid tier tags are ambiguous. The base description should be verbatim T1; DWH-specific observations can be appended clearly after the upstream quote.

4. **LOW — No Phase Gate Checklist**: Footer claims 11/14 phases but there is no explicit Phase Gate Checklist section with P1/P2/P3 checkboxes. Minor structural gap.

5. **LOW — Footer self-score**: Writer gave itself 7.3/10 which is generous given the fidelity failures on both Tier 1 columns.

---

### Regeneration Feedback

1. For MoveMoneyReasonID, start the description with the upstream text VERBATIM: "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures." THEN append DWH-specific context (ID=4 Airdrop, missing IDs 5-9, SP_Fact_CustomerAction impact) clearly separated.
2. For MoveMoneyReason, start with upstream text VERBATIM: "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens." THEN append DWH-specific observations.
3. Do not substitute, rephrase, or drop vendor/system names from upstream descriptions. "BackOffice audit screens" must remain.
4. Add an explicit Phase Gate Checklist section or clearly mark P2/P3 status in the footer.

---

### Weighted Score Calculation

```
weighted = 0.25*6 + 0.20*3 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 1.50 + 0.60 + 2.00 + 1.35 + 0.70 + 0.90
         = 7.05
```

**Verdict: FAIL** (7.05 < 7.5)

The wiki is structurally excellent and has outstanding business context, but upstream fidelity failures on both Tier 1 columns drag the score below the pass threshold. This is fixable with a targeted regeneration that quotes upstream verbatim and appends DWH context separately.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_MoveMoneyReason",
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
      "column": "MoveMoneyReasonID",
      "upstream_quote": "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures.",
      "wiki_quote": "Internal money movement reason identifier. DWH values: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop (DWH-only label). Production has additional IDs 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment - all absent from DWH. ID=5 is critical: used in SP_Fact_CustomerAction to derive ActionTypeID 44 (internal deposit) and 45 (internal withdrawal).",
      "match": "NO",
      "loss": "Rewrote opening ('Unique identifier for the money movement reason' → 'Internal money movement reason identifier'). Dropped 'Referenced by 50+ credit/balance procedures'."
    },
    {
      "column": "MoveMoneyReason",
      "upstream_quote": "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens.",
      "wiki_quote": "Human-readable money movement reason label. DWH labels: Adjustment, Bonus Abuser, Staking, Airdrop. Column name intentionally matches table name (denormalized pattern per upstream wiki). Used in financial reporting and account statements. Note: DWH label \"Airdrop\" for ID=4 diverges from production where ID=4 is marked deprecated.",
      "match": "NO",
      "loss": "Dropped 'credit history' and 'BackOffice audit screens' from display contexts. Substituted 'financial reporting' which does not appear in upstream. Rewrote 'Displayed in' → 'Used in'."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "MoveMoneyReasonID",
      "problem": "Tier 1 description is paraphrased. Upstream says 'Unique identifier for the money movement reason' — wiki says 'Internal money movement reason identifier'. 'Referenced by 50+ credit/balance procedures' is dropped entirely."
    },
    {
      "severity": "high",
      "column_or_section": "MoveMoneyReason",
      "problem": "Tier 1 description is paraphrased. Upstream lists 'Displayed in account statements, credit history, and BackOffice audit screens' — wiki drops 'credit history' and 'BackOffice audit screens', substitutes 'financial reporting' (not in upstream)."
    },
    {
      "severity": "medium",
      "column_or_section": "MoveMoneyReason (tier tag)",
      "problem": "Hybrid tier tag '(Tier 1 - upstream wiki, Dictionary.MoveMoneyReason + Tier 3 - live data sampling)' is ambiguous. Base description should be verbatim T1 with DWH observations appended separately."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section with P1/P2/P3 checkboxes despite footer claiming 11/14 phases."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Writer self-score of 7.3/10 is generous given verbatim fidelity failures on both Tier 1 columns."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) For MoveMoneyReasonID, start description with upstream verbatim: 'Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures.' Then append DWH-specific context (ID=4 Airdrop, missing IDs, SP impact) clearly separated. (2) For MoveMoneyReason, start with upstream verbatim: 'Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens.' Then append DWH-specific observations. (3) Do not drop vendor/system names — 'BackOffice audit screens' and 'credit history' must remain. (4) Add explicit Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present as explicit section"]
  }
}
</JUDGE_VERDICT>
