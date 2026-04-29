## Human Summary: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

### Per-Dimension Scores

| Dimension | Score | Justification |
|---|---|---|
| **Tier Accuracy** | 3 | 4 of 5 randomly-sampled columns are mislabeled. Every column in this table is a passthrough from `BI_DB_CID_DailyPanel_FullData` via `ALTER TABLE ... SWITCH` (a metadata-only operation with no ETL). With the parent wiki present in the bundle, the rubric requires all 169 columns to be **Tier 1**. The writer labeled 164 as T2 (relaying deeper SP lineage) and 2 as T4. Only 3 of 169 are correctly tagged T1. |
| **Upstream Fidelity** | 5 | The 3 claimed Tier 1 columns (CID, Region, Country) all have descriptions verbatim from the parent wiki (MINOR adds only). However, 166 columns that should be T1 lack proper T1 labeling — this is a systematic missed-inheritance failure. The descriptions themselves are faithful copies of the parent wiki, which partially mitigates the damage. |
| **Completeness** | 9 | All 8 sections present. Element count 169 = DDL. All rows have 5 cells with `(Tier N — source)` suffixes. Property table, Section 5.2 ASCII diagram, footer tier breakdown, and review-needed sidecar are all correctly formed. Minor deduction: T3 is absent from the Section 4 tier legend (though no T3 columns exist). |
| **Business Meaning** | 9 | Excellent for an infrastructure table. Section 1 names the three-step ETL mechanism with specific SP names, explains the transient-empty semantics, documents the DDL-vs-runtime mismatch, and clearly redirects analysts to the parent table. |
| **Data Evidence** | 7 | The table is always empty (0 rows at rest) — the writer correctly makes no fabricated data claims. The "Phases: 12/14" footer implies two phases skipped; since live-query phases legitimately yield 0 rows for a transient table, no fabricated distributions appear. |
| **Shape Fidelity** | 9 | Numbered sections, tier legend, real SQL samples in Section 7, proper footer format. Minor: index property in the property table shows SSDT DDL value (`CLUSTERED COLUMNSTORE INDEX`) while Section 3.1 correctly notes the runtime index is `CLUSTERED INDEX (DateID ASC)`. |

---

### T1 Fidelity Table

| Column | Upstream Quote (BI_DB_CID_DailyPanel_FullData) | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| CID | "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID" | "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID. Passthrough from BI_DB_CID_DailyPanel_FullData." | MINOR | Additive phrase only; no loss |
| Region | "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')" | "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe'). Passthrough from BI_DB_CID_DailyPanel_FullData." | MINOR | Additive phrase only; no loss |
| Country | "Customer's country name at snapshot date" | "Customer's country name at snapshot date. Passthrough from BI_DB_CID_DailyPanel_FullData." | MINOR | Additive phrase only; no loss |

*Note: The rubric requires all 169 passthrough columns to be Tier 1. The 166 columns labeled T2/T4 are absent from this table because the writer did not declare them T1 — the descriptions match the parent wiki verbatim, but the tier label is wrong.*

---

### Top 5 Issues

1. **[HIGH] All 169 columns should be Tier 1 — systematic mislabeling of 166 columns as T2/T4.**
   This is a partition-switch shadow table created via `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`. Data moves exclusively via `ALTER TABLE ... SWITCH PARTITION` — a metadata-only operation. No ETL, no computation, no joins. With `BI_DB_CID_DailyPanel_FullData`'s wiki present in the bundle, the rubric requires every column to be `(Tier 1 — BI_DB_CID_DailyPanel_FullData)`. Instead, `DateID`, `Channel`, `Revenue_Total`, `EOD_Equity_Copy`, and 160 others are tagged `(Tier 2 — SP_CID_DailyPanel_FullData)`. The tier label is wrong even though the descriptions are faithful.

2. **[HIGH] Tier Legend in Section 4 is internally inconsistent with rubric.**
   The legend defines "Tier 2 = ETL-computed in the parent table's writer SP" — but this is the parent SP's classification, not this table's. This shadow table performs zero ETL. No column in this table is "ETL-computed." The legend should define T1 only (all passhthroughs from parent) and T4 (deprecated). T2 should not appear.

3. **[MEDIUM] FirstAction (#19) and FirstInstrument (#20) tagged T4 — correct deprecated flag, wrong tier anchor.**
   These are deprecated NULL columns in the parent table (T4 in parent). For the SWITCH table they are still passhthroughs of `BI_DB_CID_DailyPanel_FullData.FirstAction / .FirstInstrument`. They should be `(Tier 1 — BI_DB_CID_DailyPanel_FullData)` with the deprecated/NULL note preserved in the description body.

4. **[LOW] Property table Synapse Index field shows SSDT DDL value, not runtime.**
   Property table says `CLUSTERED COLUMNSTORE INDEX`. Section 3.1 correctly notes the SP dynamically creates `CLUSTERED INDEX (DateID ASC)`. The property table should match runtime state or note the discrepancy inline.

5. **[LOW] Section 4 Tier Legend omits T3.**
   No T3 columns exist here, but the legend should include T3 for structural completeness (the standard template requires it). An analyst unfamiliar with the schema would not know whether T3 was considered and found inapplicable, or simply forgotten.

---

### Weighted Score

```
0.25×3 + 0.20×5 + 0.20×9 + 0.15×9 + 0.10×7 + 0.10×9
= 0.75 + 1.00 + 1.80 + 1.35 + 0.70 + 0.90
= 6.50  → FAIL
```

---

### Regeneration Feedback

1. **Re-tag all 169 columns as `(Tier 1 — BI_DB_CID_DailyPanel_FullData)`.** This table performs zero ETL. Every column arrives via `ALTER TABLE ... SWITCH PARTITION`. Quote descriptions verbatim from `BI_DB_CID_DailyPanel_FullData`'s wiki for each column.
2. **Rewrite the Section 4 Tier Legend** to define only T1 (verbatim passthrough from parent) and T4 (deprecated — always NULL, inherited from parent). Remove T2. Add T3 = "No traceable source" even if unused.
3. **For deprecated columns** (FirstAction, FirstInstrument, Daily_Classification): label `(Tier 1 — BI_DB_CID_DailyPanel_FullData)` and retain the deprecated/NULL note in the description body. Do NOT use T4 as the tier label for the SWITCH table.
4. **Fix the Synapse Index property**: change to `CLUSTERED INDEX (DateID ASC)` (runtime) with a note that the SSDT DDL shows CLUSTERED COLUMNSTORE INDEX.
5. **Update footer tier breakdown** to reflect the corrected counts: e.g., `169 T1, 0 T2, 0 T3, 0 T4` (or fold deprecated into T1 with deprecation noted inline).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CID_DailyPanel_FullData_SWITCH",
  "weighted_score": 6.50,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 5,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID",
      "wiki_quote": "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID. Passthrough from BI_DB_CID_DailyPanel_FullData.",
      "match": "MINOR",
      "loss": "Additive phrase appended; no semantic loss"
    },
    {
      "column": "Region",
      "upstream_quote": "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')",
      "wiki_quote": "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe'). Passthrough from BI_DB_CID_DailyPanel_FullData.",
      "match": "MINOR",
      "loss": "Additive phrase appended; no semantic loss"
    },
    {
      "column": "Country",
      "upstream_quote": "Customer's country name at snapshot date",
      "wiki_quote": "Customer's country name at snapshot date. Passthrough from BI_DB_CID_DailyPanel_FullData.",
      "match": "MINOR",
      "loss": "Additive phrase appended; no semantic loss"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "All 169 columns (DateID, Channel, Revenue_Total, EOD_Equity_Copy, and 160 others)",
      "problem": "All 169 columns are passhthroughs from BI_DB_CID_DailyPanel_FullData via ALTER TABLE ... SWITCH PARTITION — a metadata-only operation with zero ETL. With the parent wiki present in the bundle, the rubric requires every column to be Tier 1 from BI_DB_CID_DailyPanel_FullData. Writer labeled 164 as T2 (relaying the parent's SP lineage) and 2 as T4. Only CID, Region, Country are correctly T1."
    },
    {
      "severity": "high",
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Tier Legend defines T2 as 'ETL-computed in the parent table's writer SP (SP_CID_DailyPanel_FullData)'. This SWITCH table performs zero ETL — no column is ETL-computed in this table. T2 should not appear in the legend. The correct legend for this object is T1 (passthrough from parent) and T4 (deprecated)."
    },
    {
      "severity": "medium",
      "column_or_section": "FirstAction, FirstInstrument, Daily_Classification",
      "problem": "Tagged T4 in the wiki. These are deprecated/NULL columns that are passhthroughs of T4 columns in the parent table. For the SWITCH table they should still be labeled Tier 1 from BI_DB_CID_DailyPanel_FullData with the deprecated note in the description body, not a different tier label."
    },
    {
      "severity": "low",
      "column_or_section": "Property table — Synapse Index",
      "problem": "Property table shows 'CLUSTERED COLUMNSTORE INDEX' (SSDT DDL value). Section 3.1 correctly notes SP_CREATE_SWITCH_SINGLE creates 'CLUSTERED INDEX (DateID ASC)' at runtime. Property table should reflect runtime state or note the discrepancy."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Tier 3 is absent from the tier legend. While no T3 columns exist, the standard legend template requires T3 to be defined so analysts know it was considered and found inapplicable."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag ALL 169 columns as (Tier 1 — BI_DB_CID_DailyPanel_FullData). This table performs zero ETL; ALTER TABLE SWITCH is a metadata-only operation. Quote each column description verbatim from BI_DB_CID_DailyPanel_FullData wiki. (2) Rewrite Section 4 Tier Legend: define T1=passthrough from BI_DB_CID_DailyPanel_FullData, T3=no traceable source (unused), T4=deprecated/NULL inherited from parent. Remove T2 entirely. (3) For FirstAction, FirstInstrument, Daily_Classification: keep T1 tier label, note deprecated/NULL status in description body. (4) Fix Synapse Index property to CLUSTERED INDEX (DateID ASC) reflecting runtime SP behavior. (5) Update footer tier breakdown to 169 T1, 0 T2, 0 T3, 0 T4.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
