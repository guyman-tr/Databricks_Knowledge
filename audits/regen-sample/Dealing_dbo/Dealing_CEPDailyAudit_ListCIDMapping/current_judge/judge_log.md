## Judge Review — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled 5 columns: Date, NameListID, CID, TypeOfChange, UpdateDate. Four are correctly Tier 2 (SP-derived or staging passthrough with no upstream wiki). **UpdateDate** is mis-tagged as `[UNVERIFIED] (Tier 4 — inferred)` despite `GETDATE()` being clearly visible as the 8th positional column in the SP's `INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping` statement. That's 1 mismatch out of 5.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
There are zero Tier 1 columns. All direct column sources are either the SP parameter (`@Date`), staging tables (`External_Etoro_CEP_ListCIDMappings`, `External_Etoro_History_ListCIDMappings`) which have no wikis, or SP-derived logic. The upstream wikis in the bundle are sibling CEPDailyAudit tables — none are direct column ancestors for this table. Neutral score applies.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (8) matches DDL exactly. Every element row has 5 cells with tier tags. Property table has all required fields. ASCII pipeline diagram uses real object names. Footer has tier breakdown. Section 1 has row count (532) and date range (2023-12-19 to 2026-01-26). TypeOfChange enum values (`CID Added`, `CID Deleted`) listed inline. Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Excellent Section 1. Names the domain (CEP Named List CID membership), row grain (one add/remove of a CID from a Named List), ETL SP (`SP_CEPDailyAudit`), load pattern (DELETE + INSERT), refresh (daily), PII flag, and explains sparse activity. Three concrete use cases given.

**Dimension 5 — Data Evidence: 6/10**
Row count (532) and date range present. Enum values documented. However, no formal Phase Gate Checklist section with P2/P3 markers. No explicit NULL-rate analysis. Data claims appear grounded but unverifiable without phase gate attestation.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit "phases-completed" list in footer.

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. All columns derive from staging tables without wikis or from SP computation.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **HIGH — UpdateDate (Element #8):** Tagged `[UNVERIFIED] (Tier 4 — inferred)` but the SP INSERT clearly shows `GETDATE()` as the 8th positional value. Should be `(Tier 2 — SP_CEPDailyAudit)`. The description text itself correctly says "DWH load time via GETDATE()" — the tier tag contradicts the description body.

2. **LOW — Section 1 "Activity note" phrasing:** "About 532 rows" uses hedging language ("about") for what should be a precise sampled count. Minor but inconsistent with a data-evidence claim.

3. **LOW — No Phase Gate Checklist:** The wiki lacks a formal phase gate section documenting which verification phases (P1–P3) were completed. The footer references quality scores but not phase completion status.

4. **LOW — LoginName in Element #6:** Description says "CEP application user who performed the add/remove" which is accurate but could note the COALESCE logic (as Section 2 does). Not a tier error, just an inconsistency between element description depth and business logic section.

5. **INFO — SP column name mismatch:** The SP uses `PreviousAppLoginName AS AppLoginName` for the INSERT, meaning the column labeled `LoginName` in the DDL receives the COALESCE result. The wiki documents this correctly in Section 2 but the element description doesn't mention the COALESCE. Cosmetic only.

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` and remove the `[UNVERIFIED]` prefix — `GETDATE()` is explicitly visible in the SP INSERT.
2. Add a Phase Gate Checklist section or footer annotation documenting which verification phases were completed.
3. Optionally add COALESCE note to the `LoginName` element description for consistency with Section 2.

### Weighted Score

```
weighted = 0.25*7 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*6 + 0.10*8
         = 1.75 + 1.40 + 2.00 + 1.35 + 0.60 + 0.80
         = 7.90
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_ListCIDMapping",
  "weighted_score": 7.9,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate (Element #8)",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but GETDATE() is clearly the 8th positional value in the SP INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping statement. Should be (Tier 2 — SP_CEPDailyAudit). The description body itself correctly identifies the source as GETDATE()."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 — Activity note",
      "problem": "Uses hedging language 'About 532 rows' for what should be a precise sampled count."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / missing section",
      "problem": "No Phase Gate Checklist section documenting which verification phases (P1-P3) were completed."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName (Element #6)",
      "problem": "Element description does not mention COALESCE(AppLoginName, PreviousAppLoginName) logic documented in Section 2 — minor inconsistency in description depth."
    },
    {
      "severity": "info",
      "column_or_section": "LoginName",
      "problem": "SP uses PreviousAppLoginName AS AppLoginName for the INSERT column; wiki correctly documents the COALESCE in Section 2 but not in the element row. Cosmetic."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) and remove [UNVERIFIED] — GETDATE() is explicitly in the SP INSERT. (2) Add Phase Gate Checklist or footer annotation for P1-P3 completion status. (3) Optionally add COALESCE note to LoginName element description for consistency with Section 2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
