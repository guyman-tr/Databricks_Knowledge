I'll start by carefully reviewing the wiki against the DDL, SP source, lineage, and upstream bundle.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (5/5 columns checked, since only 5 exist)

| Column | Wiki Tier | Correct Tier | Match? |
|--------|-----------|-------------|--------|
| `Date` | Tier 2 (SP-computed) | Tier 2 (DATEADD from @Date) | YES |
| `InstrumentDisplayName` | Tier 1 (Dim_Instrument) | Tier 2 — CASE transform normalizes crude oil variants; upstream wiki itself tags this column as Tier 2 (SP_Dim_Instrument) | NO |
| `CID_Count` | Tier 2 (COUNT DISTINCT) | Tier 2 | YES |
| `Monthly_Volume` | Tier 2 (SUM) | Tier 2 | YES |
| `UpdateDate` | Tier 1 ("ETL metadata blacklist canonical") | Tier 2 — it's `GETDATE()` in the SP, not inherited from any upstream | NO |

2 mismatches → base score 5. InstrumentDisplayName is claimed Tier 1 but paraphrased (see D2) → deduct 2. **Score: 3**

### Dimension 2 — Upstream Fidelity

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| `InstrumentDisplayName` | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)" | "Instrument display name for this row. Crude oil futures all map to 'Crude Oil Future'." | NO | Dropped examples ('Apple Inc.' vs 'Apple'), dropped NULL semantics, dropped origin (Trade.InstrumentMetaData), upstream is Tier 2 not Tier 1 |
| `UpdateDate` | No upstream — GETDATE() in SP | "ETL metadata: timestamp when row was last written." | NO | No upstream exists; wrongly tagged Tier 1. GETDATE() is SP-computed = Tier 2 |

Wrong tier origin on InstrumentDisplayName (Dim_Instrument calls it Tier 2 from SP_Dim_Instrument, writer relayed it as Tier 1) + paraphrasing. **Score: 3**

### Dimension 3 — Completeness Checklist

| # | Check | Pass? |
|---|-------|-------|
| 1 | All 8 numbered sections present | YES |
| 2 | Element count matches DDL (5 vs 5) | YES |
| 3 | Every element row has 5 cells (`# \| Element \| Type \| Nullable \| Description`) | NO — wiki uses `Column \| Type \| Description \| Tier \| Notes`; missing `#` and `Nullable` |
| 4 | Every description ends with `(Tier N — source)` | NO — tier is in a separate column |
| 5 | Property table has Production Source, Refresh, Distribution, UC Target | NO — no UC Target |
| 6 | Section 5.2 ETL pipeline ASCII diagram | NO — ETL described in prose under "Source & Lineage", no ASCII diagram |
| 7 | Footer has tier breakdown counts | NO — footer has quality score only |
| 8 | Section 1 contains row count and date range | NO — Section 1 has business purpose only; row count is in Section 3 |
| 9 | Dictionary columns ≤15 values list key=value pairs | N/A (no applicable column) — PASS |
| 10 | `.review-needed.md` does not contain `## 4. Elements` | YES |

4/10 → **Score: 4**

**Critical additional finding**: DDL declares `Monthly_Volume` as `[bigint] NULL`. Wiki declares it as `decimal(38,6)`. **Type mismatch.**

### Dimension 4 — Business Meaning

Section 1 is specific: names CME regulatory obligation, explains the aggregate nature (client counts + volumes, not individual data), mentions crude oil normalization. The frontmatter description is strong. However, Section 1 itself lacks row count, date range, and explicit ETL SP name/refresh pattern — those appear in other sections.

**Score: 7**

### Dimension 5 — Data Evidence

- Row count (690) cited in frontmatter and grain section
- Date range ("last row 2026-02-28") in frontmatter
- Hardcoded instrument IDs enumerated
- No Phase Gate Checklist exists
- No P2/P3 markers
- No NULL-rate or distribution analysis

Without Phase Gate markers, data claims are unverified but plausible for a 690-row table. **Score: 5**

### Dimension 6 — Shape Fidelity

- Numbered sections 1–8: present
- Tier legend in Section 4: absent
- SQL samples in Section 5: present and valid
- Footer: has quality score but missing tier breakdown and phases-completed
- Elements table uses non-standard column headers

**Score: 6**

---

## Weighted Total

```
weighted = 0.25*3 + 0.20*3 + 0.20*4 + 0.15*7 + 0.10*5 + 0.10*6
         = 0.75 + 0.60 + 0.80 + 1.05 + 0.50 + 0.60
         = 4.30
```

**Verdict: FAIL**

---

## Top 5 Issues

1. **`Monthly_Volume` type mismatch** (high): DDL says `bigint`, wiki says `decimal(38,6)`. This is a factual error analysts will hit immediately.

2. **`InstrumentDisplayName` wrong tier** (high): Tagged Tier 1 from Dim_Instrument, but (a) there is a CASE transform making it Tier 2, and (b) the Dim_Instrument wiki itself tags this column as Tier 2 (SP_Dim_Instrument). Description is paraphrased — dropped examples, NULL semantics, and Trade.InstrumentMetaData origin.

3. **`UpdateDate` wrong tier** (medium): Tagged Tier 1 "blacklist canonical" but it's `GETDATE()` in the SP — no upstream inheritance, should be Tier 2.

4. **Elements table wrong shape** (medium): Missing `#` and `Nullable` columns, tier annotation is in a separate column instead of inline in the description. All DDL columns are NULLable but this isn't shown.

5. **Missing structural components** (medium): No tier legend, no ETL ASCII pipeline diagram, no tier breakdown footer, no Phase Gate Checklist, Section 1 lacks row count/date range.

---

## Regeneration Feedback

1. Fix `Monthly_Volume` type from `decimal(38,6)` to `bigint` to match DDL.
2. Re-tag `InstrumentDisplayName` as `(Tier 2 — SP_M_CME_Reporting, CASE transform on DWH_dbo.Dim_Instrument.InstrumentDisplayName)` — the CASE normalization of crude oil variants makes this ETL-computed, not a passthrough.
3. Re-tag `UpdateDate` as `(Tier 2 — SP_M_CME_Reporting, GETDATE())`.
4. Restructure Elements table to use `# | Element | Type | Nullable | Description` format with tier annotation inline at end of description: `(Tier N — source)`.
5. Add a Tier Legend subsection in Section 4.
6. Add an ETL pipeline ASCII diagram showing `Dim_Position + Dim_Instrument + Dim_Customer → #Ins → #Positions → DELETE+INSERT → Dealing_CME_Reporting`.
7. Add row count (690) and date range (2024-01 to 2026-02-28) to Section 1.
8. Add tier breakdown footer: `Tier 1: 0 | Tier 2: 5`.
9. Add Phase Gate Checklist or explicitly note that P2/P3 live-data validation was not performed.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CME_Reporting",
  "weighted_score": 4.30,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 5,
    "shape_fidelity": 6
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)",
      "wiki_quote": "Instrument display name for this row. Crude oil futures all map to 'Crude Oil Future'.",
      "match": "NO",
      "loss": "Dropped examples ('Apple Inc.' vs 'Apple'), dropped NULL semantics, dropped origin (Trade.InstrumentMetaData). Upstream wiki tags this as Tier 2 (SP_Dim_Instrument), not Tier 1. Additionally, CASE transform in SP_M_CME_Reporting normalizes crude oil variants, making this Tier 2 in the CME table."
    },
    {
      "column": "UpdateDate",
      "upstream_quote": null,
      "wiki_quote": "ETL metadata: timestamp when row was last written.",
      "match": "NO",
      "loss": "No upstream exists — column is GETDATE() in SP_M_CME_Reporting. Wrongly tagged Tier 1; should be Tier 2 (SP-computed)."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Monthly_Volume",
      "problem": "DDL declares Monthly_Volume as bigint NULL but wiki says decimal(38,6). Type mismatch will mislead analysts about precision and storage."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Tagged Tier 1 from DWH_dbo.Dim_Instrument but: (a) Dim_Instrument wiki tags InstrumentDisplayName as Tier 2 (SP_Dim_Instrument, join-enriched from Trade.InstrumentMetaData), (b) SP_M_CME_Reporting applies a CASE transform normalizing crude oil variants. Should be Tier 2. Description is paraphrased — dropped examples, NULL semantics, and Trade.InstrumentMetaData origin."
    },
    {
      "severity": "medium",
      "column_or_section": "UpdateDate",
      "problem": "Tagged Tier 1 'ETL metadata (blacklist canonical)' but it is GETDATE() in SP_M_CME_Reporting — no upstream inheritance. Should be Tier 2."
    },
    {
      "severity": "medium",
      "column_or_section": "## 4. Elements",
      "problem": "Elements table uses non-standard format (Column|Type|Description|Tier|Notes) instead of required (#|Element|Type|Nullable|Description). Missing Nullable column — all 5 DDL columns are NULL-able but this is not shown. Tier annotation should be inline at end of description, not a separate column."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Structure",
      "problem": "Missing tier legend in Section 4, no ETL ASCII pipeline diagram, no tier breakdown footer, no Phase Gate Checklist. Section 1 lacks row count and date range."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Monthly_Volume type from decimal(38,6) to bigint to match DDL. (2) Re-tag InstrumentDisplayName as Tier 2 (SP_M_CME_Reporting CASE transform on Dim_Instrument.InstrumentDisplayName). (3) Re-tag UpdateDate as Tier 2 (SP_M_CME_Reporting GETDATE()). (4) Restructure Elements table to # | Element | Type | Nullable | Description format with inline (Tier N — source) at end of each description. (5) Add Tier Legend subsection in Section 4. (6) Add ETL ASCII pipeline diagram: Dim_Position + Dim_Instrument + Dim_Customer → #Ins → #Positions → DELETE+INSERT → Dealing_CME_Reporting. (7) Move row count (690) and date range to Section 1. (8) Add tier breakdown footer: Tier 1: 0 | Tier 2: 5. (9) Add Phase Gate Checklist or explicitly note P2/P3 skipped.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
