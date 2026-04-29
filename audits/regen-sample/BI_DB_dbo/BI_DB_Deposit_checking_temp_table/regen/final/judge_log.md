## Adversarial Judge Review: `BI_DB_dbo.BI_DB_Deposit_checking_temp_table`

---

### Dimension 1 — Tier Accuracy (25%) → **7/10**

Picked all 5 columns (table is small enough to check all):

| Column | Wiki Tier | Correct Tier | Match? |
|---|---|---|---|
| Deposits_FCA | Tier 2 | Tier 2 | ✓ SUM aggregation — correct |
| Deposits_CB | Tier 2 | Tier 2 | ✓ SUM(Deposits)-SUM(InternalTransferDeposits) — correct |
| Balance_diff_deposit | Tier 2 | Tier 2 | ✓ Computed diff — correct |
| Error_Message | Tier 2 | Tier 2 | ✓ SP-constructed string — correct |
| **UpdateDate** | **Tier 2** | **Tier 3** | **MISMATCH** |

**UpdateDate** is `GETDATE()` at INSERT time. The wiki's own tier legend defines Tier 3 as "ETL-assigned constant (GETDATE, NULL placeholder)" with **GETDATE explicitly named as an example**. The writer tagged it Tier 2 ("Derived from SP code") instead. This is a direct contradiction of the table's own legend. The footer tier count ("0 T1, 5 T2, 0 T3, 0 T4") inherits this error.

1 mismatch out of 5 → score 7.

---

### Dimension 2 — Upstream Fidelity (20%) → **7/10**

There are **no Tier 1 columns** in this wiki. All 5 columns are computed or ETL-assigned by `SP_Client_Balance_Check_Opening_Balance`. Upstream wikis (`BI_DB_Client_Balance_Aggregate_Level_New`, `Fact_CustomerAction`) are present in the bundle but no column is a direct passthrough — every column involves aggregation, arithmetic, conditional logic, or a timestamp constant. Neutral score of 7 applies.

T1 fidelity table: empty (`[]`) — confirmed correct.

---

### Dimension 3 — Completeness (20%) → **8/10**

| Check | Pass? |
|---|---|
| All 8 sections present | ✓ |
| Element count matches DDL (5=5) | ✓ |
| Every element row has 5 cells | ✓ |
| Every description ends with `(Tier N — source)` | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target | ✓ |
| Section 5.2 ETL pipeline ASCII diagram with real names | ✓ |
| Footer has tier breakdown counts | ✓ (wrong counts — T3 count should be 1, not 0) |
| Section 1 has row count + date range | Partial ✓ (row count ✓; date range N/A for 1-row staging, last-sampled date present) |
| Enum/dict columns list `key=value` pairs | N/A — no low-cardinality enum columns |
| `.review-needed.md` does not contain `## 4. Elements` | ✓ |

~9/10 applicable checks pass. Score: **8**.

---

### Dimension 4 — Business Meaning (15%) → **9/10**

Section 1 is strong. It names the specific domain event (deposit reconciliation), the writing SP, the calling SP, the row count (1), the DELETE+INSERT pattern, the RAISERROR abort scenario, and includes a live sampled value (diff=0.000000, 2026-04-27 03:33:55). A brand-new analyst can immediately know when to query this table and what a non-zero `Balance_diff_deposit` means. Very close to best-in-class for a 1-row staging/check table.

---

### Dimension 5 — Data Evidence (10%) → **8/10**

- Row count (1) explicitly stated and confirmed by live sampling
- `UpdateDate` = 2026-04-27 03:33:55 — live data
- `Balance_diff_deposit` = 0.000000 — live sampled value
- Phase gates P1-P11 completed (P2+P3 not skipped → data claims are valid)
- P12-P14 skipped, which is consistent with the "not yet provisioned" UC Target and absence of Databricks-layer analysis

Score: **8**.

---

### Dimension 6 — Shape Fidelity (10%) → **9/10**

All structural elements present: numbered sections, tier legend in Section 4, real SP-specific SQL samples in Section 7, footer with quality score and phases-completed list. Section 6 is slightly thin (only 6.1 Source Upstream; the Referenced By content that would normally go in 6.2 was placed in 5.4 instead), but this is a minor deviation.

Score: **9**.

---

### T1 Fidelity Table

*(Empty — no Tier 1 columns exist in this wiki. All columns are computed aggregations or ETL-assigned values.)*

---

### Top Issues

1. **[HIGH] `UpdateDate` — wrong tier.** Tagged Tier 2 ("Derived from SP code") but the wiki's own tier legend explicitly defines Tier 3 as "ETL-assigned constant (GETDATE, NULL placeholder)" with GETDATE named. `UpdateDate = GETDATE()` is textbook Tier 3. Footer tier counts are also wrong as a consequence.

2. **[LOW] Footer tier counts incorrect.** Footer reads "0 T1, 5 T2, 0 T3, 0 T4" but should read "0 T1, 4 T2, 1 T3, 0 T4" after correcting UpdateDate.

3. **[LOW] `Deposits_CB` formula simplified in wiki.** Wiki says `SUM(Deposits) - SUM(InternalTransferDeposits)` but SP uses `SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))`. The ISNULL wrappers are dropped in the wiki description (though correctly present in the lineage file). Minor semantic loss since NULL treatment affects numeric results.

4. **[LOW] Section 6 is sparse.** Section 6 contains only "6.1 Source Upstream" with no 6.2. The Referenced By content lives in 5.4 instead of being mirrored in Section 6. Not a functional problem but deviates from the standard shape.

5. **[INFO] Self-reported quality score (8.2/10) is slightly optimistic.** Judge finds 7.80, which still passes but is a gap of 0.4 from the writer's self-assessment.

---

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 3 — ETL-assigned constant)` and update the description to remove the SP attribution. Update the footer tier counts from "5 T2, 0 T3" to "4 T2, 1 T3".
2. In the `Deposits_CB` description, add back the ISNULL wrappers to accurately reflect the SP formula: `SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))`.
3. Optionally add a Section 6.2 "Referenced By" mirroring the content in 5.4 for shape compliance.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposit_checking_temp_table",
  "weighted_score": 7.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged Tier 2 ('Derived from SP code') but the wiki's own tier legend explicitly defines Tier 3 as 'ETL-assigned constant (GETDATE, NULL placeholder)' with GETDATE named as the canonical example. UpdateDate = GETDATE() at INSERT time is textbook Tier 3, not Tier 2."
    },
    {
      "severity": "low",
      "column_or_section": "Footer tier counts",
      "problem": "Footer reports '0 T1, 5 T2, 0 T3, 0 T4' but should be '0 T1, 4 T2, 1 T3, 0 T4' once UpdateDate is corrected to Tier 3."
    },
    {
      "severity": "low",
      "column_or_section": "Deposits_CB",
      "problem": "Description omits the ISNULL wrappers present in the SP: wiki says 'SUM(Deposits) - SUM(InternalTransferDeposits)' but SP code uses 'SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))'. The lineage file has the correct formula; the wiki description simplified it."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6",
      "problem": "Section 6 contains only '6.1 Source Upstream' with no 6.2 Referenced By subsection. The Referenced By content is in Section 5.4 but is not mirrored in Section 6 per the standard shape."
    },
    {
      "severity": "info",
      "column_or_section": "Footer quality score",
      "problem": "Self-reported quality score is 8.2/10; adversarial judge scores 7.80. Optimism gap of 0.4 — still a PASS but writer's self-assessment is slightly inflated."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as '(Tier 3 — ETL-assigned constant)' — GETDATE is the canonical Tier 3 example in the tier legend; update footer counts from '5 T2, 0 T3' to '4 T2, 1 T3'. (2) Restore ISNULL wrappers in Deposits_CB description: 'SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))'. (3) Optionally add Section 6.2 Referenced By mirroring Section 5.4 content.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P12", "P13", "P14"]
  }
}
</JUDGE_VERDICT>
