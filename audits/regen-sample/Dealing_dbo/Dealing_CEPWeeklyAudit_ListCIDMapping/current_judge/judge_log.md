I'll review this wiki systematically. Let me first verify the critical DDL-vs-wiki column mapping.

**DDL columns (from source):**
1. `[FromDate]` datetime NULL
2. `[ToDate]` datetime NULL
3. `[NameListID]` int NULL
4. **`[ListName]`** varchar(max) NULL
5. `[CID]` bigint NULL
6. `[TypeOfChange]` varchar(max) NULL
7. `[LoginName]` varchar(max) NULL
8. `[ChangeTime]` datetime NULL
9. `[UpdateDate]` datetime NULL

**Wiki Element #4:** `Name` — but DDL says **`ListName`**. This is a hard naming error.

Let me verify the SP insert to confirm which physical column receives the value:

The SP's `INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` uses positional insert (no column list). The 4th selected value is `Name` (from `#ListCIDMapping_ChangesFinal`), which maps to DDL position 4 = `[ListName]`. So the **physical column is `ListName`**, not `Name`. The wiki documents the wrong column name.

---

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy (25%) — Score: 8

**5-column random sample:**

| Column | Wiki Tier | Actual Source | Correct? |
|--------|-----------|---------------|----------|
| FromDate | Tier 2 — SP | `@weekStart` parameter in SP | YES |
| NameListID | Tier 2 — SP | Passthrough from `External_Etoro_CEP_ListCIDMappings.NamedListID` via `#ListCIDMapping_Log`; no upstream wiki exists | YES (no wiki = can't be T1) |
| CID | Tier 2 — SP | Passthrough from staging; no upstream wiki | YES |
| TypeOfChange | Tier 2 — SP | SP-computed literal (`'CID Added'` / `'CID Deleted'`) | YES |
| UpdateDate | Tier 4 — inferred | `GETDATE()` clearly visible in SP INSERT | MINOR — should not be `[UNVERIFIED]`; sibling Rules wiki marks same column as `(Tier 4 — SP_W_CEPWeeklyAudit)` without UNVERIFIED |

0 real mismatches, 1 minor (UpdateDate unnecessarily tagged UNVERIFIED when SP code is explicit). **Score: 8** (docked for the UNVERIFIED tag on a clearly-visible SP expression).

### Dimension 2 — Upstream Fidelity (20%) — Score: 7

Zero Tier 1 columns. All upstream staging sources (`External_Etoro_CEP_ListCIDMappings`, etc.) are unresolved — no wikis in the bundle. The six sibling weekly audit wikis are **related objects**, not direct column sources. Neutral score applies.

**T1 Fidelity Table:** Empty — no Tier 1 columns exist.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

**Score: 7** (neutral — no upstream wiki available for inheritance).

### Dimension 3 — Completeness (20%) — Score: 5

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count matches DDL (9 vs 9) | **NO — column name mismatch: DDL `ListName` vs wiki `Name`** |
| Every element has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ETL pipeline ASCII diagram | YES (in Section 5, no 5.2 subsection label) |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES |
| Dictionary columns ≤15 values list key=value pairs | PARTIAL — TypeOfChange values mentioned in prose but not formatted as inline key=value in Element description |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

7.5/10 checks → **Score: 5**. The column name mismatch is a hard failure for any analyst writing queries.

### Dimension 4 — Business Meaning (15%) — Score: 9

Section 1 is excellent: names the domain (CEP Named List CID membership), states the row grain (weekly Monday–Sunday window), identifies the ETL SP, gives row count (~1,047) and date range (Sep 2021 → Mar 2026), flags PII (CID), explains NULL `TypeOfChange` semantics, and references the daily counterpart. Highly specific and actionable.

### Dimension 5 — Data Evidence (10%) — Score: 5

Row count (~1,047) and date range (2021-09-26 → 2026-03-01) are present. TypeOfChange values listed. However: **no Phase Gate Checklist** appears anywhere in the wiki — no P2/P3 markers. Stats appear but methodology is unverifiable. The `max FromDate` claim is specific enough to suggest real data was queried, but formal evidence structure is missing.

### Dimension 6 — Shape Fidelity (10%) — Score: 7

Numbered sections 1–8 present. Tier legend in Section 4. Three real SQL samples in Section 7. Footer has quality score and tier counts. Missing: no phases-completed list in footer, Section 5 lacks the "5.1 / 5.2" subsection numbering seen in golden-reference shapes.

---

## Weighted Total

```
weighted = 0.25*8 + 0.20*7 + 0.20*5 + 0.15*9 + 0.10*5 + 0.10*7
         = 2.00 + 1.40 + 1.00 + 1.35 + 0.50 + 0.70
         = 6.95
```

**6.95 → FAIL**

---

## Top 5 Issues

1. **HIGH — Element #4 column name wrong.** DDL defines `[ListName]` but wiki documents `Name`. Any analyst querying `SELECT Name FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` will get an error.

2. **MEDIUM — UpdateDate tagged `[UNVERIFIED] (Tier 4 — inferred)` when SP code explicitly shows `GETDATE()`.** Sibling wikis (e.g., `Dealing_CEPWeeklyAudit_Rules`) correctly mark this as `(Tier 4 — SP_W_CEPWeeklyAudit)` without UNVERIFIED. Should be consistent.

3. **MEDIUM — No Phase Gate Checklist.** Stats (row count, date range) appear in Section 1 but there is no evidence trail showing P2/P3 data validation was performed. The sibling wikis also lack this, but the rubric penalizes it.

4. **LOW — TypeOfChange enum values not formatted as inline key=value in Element description.** The column has only 2 real values (`CID Added`, `CID Deleted`) plus NULL — ideal for inline enumeration in the Elements table cell, not just in prose in Section 2.

5. **LOW — Section 5 lineage lacks formal 5.1/5.2 subsection structure.** The ASCII diagram exists but isn't labeled as a numbered subsection.

---

## Regeneration Feedback

1. **Rename Element #4 from `Name` to `ListName`** to match the DDL column `[ListName] varchar(max) NULL`. Update all references in Sections 2, 3, 6, and 7 (sample queries should use `ListName` not `Name`).
2. **Remove `[UNVERIFIED]` from UpdateDate** — the SP INSERT clearly selects `GETDATE()` as the 9th positional column. Tag as `(Tier 4 — SP_W_CEPWeeklyAudit)` consistent with sibling wikis.
3. **Add Phase Gate Checklist** (even if P2/P3 are marked skipped, the checklist must be present for shape compliance).
4. **Add inline enum values to TypeOfChange Element description:** `Values: 'CID Added', 'CID Deleted'; NULL = no-change placeholder.`
5. **Fix sample queries** in Section 7 to use `ListName` instead of `Name`.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_ListCIDMapping",
  "weighted_score": 6.95,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 7,
    "completeness": 5,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Element #4 (Name vs ListName)",
      "problem": "DDL defines column as [ListName] varchar(max) NULL but wiki Element #4 documents it as 'Name'. The SP inserts positionally — the 4th value (Name from #ListCIDMapping_Log) maps to DDL position 4 = [ListName]. All sample queries in Section 7 and references in Sections 2/3 use the wrong column name."
    },
    {
      "severity": "medium",
      "column_or_section": "Element #9 (UpdateDate)",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but GETDATE() is explicitly visible as the 9th positional value in the SP INSERT. Sibling wiki Dealing_CEPWeeklyAudit_Rules correctly uses (Tier 4 — SP_W_CEPWeeklyAudit) without UNVERIFIED."
    },
    {
      "severity": "medium",
      "column_or_section": "Missing section",
      "problem": "No Phase Gate Checklist present. Row count and date range stats appear in Section 1 but no P2/P3 evidence trail exists to confirm data validation was performed."
    },
    {
      "severity": "low",
      "column_or_section": "Element #6 (TypeOfChange)",
      "problem": "TypeOfChange has only 2 real values (CID Added, CID Deleted) plus NULL — ideal for inline key=value enumeration in the Elements table cell, but values are only mentioned in Section 2 prose."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5",
      "problem": "Lineage section lacks formal 5.1/5.2 subsection numbering per golden reference shape."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Rename Element #4 from 'Name' to 'ListName' to match DDL [ListName] varchar(max) NULL — update all references in Sections 2, 3, 6, and 7 sample queries. (2) Remove [UNVERIFIED] from UpdateDate and tag as (Tier 4 — SP_W_CEPWeeklyAudit) consistent with sibling wikis. (3) Add Phase Gate Checklist section. (4) Add inline enum values to TypeOfChange Element description: 'CID Added', 'CID Deleted'; NULL = no-change placeholder. (5) Fix all sample queries in Section 7 to use ListName instead of Name.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
