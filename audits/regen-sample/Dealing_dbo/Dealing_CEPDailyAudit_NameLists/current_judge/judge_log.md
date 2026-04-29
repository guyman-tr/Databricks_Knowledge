## Adversarial Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_NameLists`

### Dimension 1 — Tier Accuracy: **7/10**

Sampled 5 of 7 columns:

| Column | SP Evidence | Wiki Tier | Correct? |
|--------|-----------|-----------|----------|
| Date | `@Date` parameter | Tier 2 | YES |
| NameListID | Passthrough from staging via SP | Tier 2 | YES |
| TypeOfChange | CASE WHEN RN logic in SP | Tier 2 | YES |
| LoginName | `COALESCE(AppLoginName, PreviousAppLoginName)` | Tier 2 | YES |
| UpdateDate | `GETDATE()` — explicitly in SP INSERT | Tier 4 inferred | **NO** |

**UpdateDate** is explicitly `GETDATE()` in the SP's INSERT statement (line visible in the NameLists INSERT block). This is Tier 2 — SP_CEPDailyAudit, not Tier 4. The writer marked it `[UNVERIFIED]` despite having the SP source code available. 1 mismatch → score 7.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns**. All sources are `Dealing_staging.External_Etoro_*` tables which are unresolved (no wikis in the bundle). The upstream wikis provided (Rules, CP, Conditions, etc.) are **sibling** audit tables, not source tables for this object. No Tier 1 inheritance is expected or possible.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (7 = 7) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (~275) and date range (2023-12-19 – 2026-01-26) | YES |
| TypeOfChange (3 values) listed inline in element description | YES |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 → score 10.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable. It names the domain (CEP Named Lists, hedging rules), row grain (one event per Named List per Date), ETL SP (`SP_CEPDailyAudit`), load pattern (DELETE + INSERT), refresh (daily), row count (~275), date range, and sparsity context. A new analyst could immediately understand when and why to query this table.

### Dimension 5 — Data Evidence: **5/10**

Row count (275) and date range are cited with "documented sample" framing, and TypeOfChange values are listed. However, there is **no Phase Gate Checklist** section in the wiki, so P2/P3 completion cannot be verified. Without explicit phase markers, data claims lack provenance confirmation. No NULL-rate or distribution analysis is present.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviations: no Phase Gate Checklist section, no explicit "5.2" sub-numbering for the pipeline diagram.

### Weighted Total

```
weighted = 0.25×7 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×5 + 0.10×8
         = 1.75 + 1.40 + 2.00 + 1.35 + 0.50 + 0.80
         = 7.80
```

**Verdict: PASS** (7.80 ≥ 7.5)

### Top 5 Issues

1. **HIGH — UpdateDate tier misclassification** (`UpdateDate`): Tagged `[UNVERIFIED] (Tier 4 — inferred)` but `GETDATE()` is explicitly visible in the SP INSERT block. Should be `(Tier 2 — SP_CEPDailyAudit)`.

2. **MEDIUM — No Phase Gate Checklist**: The wiki lacks a Phase Gate section confirming which data-validation phases were completed. Data claims (row count, date range) have no provenance trail.

3. **LOW — Deletion event logic simplified** (Section 2): Wiki says "`SysEndDate = @Date` with latest-row semantics → Name List Deleted" but the SP actually uses `CASE WHEN nll.RN_desc=1 THEN 'Name List Deleted' ELSE 'Change In CIDs'` on the SysEndDate branch — meaning non-latest rows on that path also produce `Change In CIDs`. The wiki omits this second path for SysEndDate-triggered events.

4. **LOW — Missing SP column name discrepancy note** (`NameListID`): The DDL column is `NameListID` (no 'd') but the SP source column is `NamedListID` (with 'd'). The wiki doesn't call out this rename, which could confuse analysts tracing lineage manually.

5. **LOW — IsActive column alias note** (`LoginName`): The SP INSERT uses `PreviousAppLoginName AS AppLoginName` — the alias `AppLoginName` in the INSERT is actually the COALESCE result, not the raw field. The wiki correctly describes the COALESCE logic but doesn't note this aliasing subtlety.

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — `GETDATE()` is explicitly in the SP INSERT. Remove the `[UNVERIFIED]` marker.
2. Add a Phase Gate Checklist section documenting which data-validation phases (P1/P2/P3) were completed.
3. In Section 2, clarify that the `SysEndDate = @Date` branch produces BOTH `Name List Deleted` (when `RN_desc=1`) AND `Change In CIDs` (when `RN_desc > 1`).
4. Note the `NamedListID` → `NameListID` column rename in the lineage table.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_NameLists",
  "weighted_score": 7.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but GETDATE() is explicitly visible in the SP INSERT block for Dealing_CEPDailyAudit_NameLists. Should be (Tier 2 — SP_CEPDailyAudit)."
    },
    {
      "severity": "medium",
      "column_or_section": "Overall",
      "problem": "No Phase Gate Checklist section — data claims (row count 275, date range 2023-12-19 to 2026-01-26) lack provenance confirmation."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2 — Event typing",
      "problem": "Wiki says SysEndDate=@Date with latest-row semantics → Name List Deleted, but SP also produces 'Change In CIDs' on the SysEndDate branch when RN_desc > 1. Second path omitted."
    },
    {
      "severity": "low",
      "column_or_section": "NameListID",
      "problem": "DDL column is NameListID but SP source column is NamedListID (with 'd'). Column rename not noted in lineage."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName",
      "problem": "SP INSERT uses PreviousAppLoginName AS AppLoginName — the alias is actually the COALESCE result, not the raw field. Aliasing subtlety not documented."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) — GETDATE() is explicit in SP. (2) Add Phase Gate Checklist section. (3) Clarify SysEndDate branch produces both 'Name List Deleted' (RN_desc=1) and 'Change In CIDs' (RN_desc>1). (4) Note NamedListID → NameListID rename in lineage.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
