The upstream bundle claimed no upstream wiki was resolvable. Before finalising scores I need to verify whether the Dealing wiki referenced in the lineage actually exists.

The Dealing wiki does exist and I have read it (lines 1–120). Key finding: **all 26 column descriptions in the BI_DB wiki were drawn from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks.md`**, which the harness failed to include in the bundle. This materially affects Tier Accuracy.

---

## Human-readable summary

### Dimension scores

| Dimension | Score | One-line justification |
|---|---|---|
| Tier Accuracy (25%) | 3 | 3 of 5 sampled columns wrong tier: `InstrumentType` and `Industry` should be Tier 1 (BI_DB is a mirror of Dealing, Dealing wiki IS in the knowledge base); `UpdateDate` should be Tier 3 (GETDATE() = batch metadata), not Tier 2. |
| Upstream Fidelity (20%) | 7 | Neutral per rubric — bundle explicitly contained no upstream wiki. Dealing wiki was not formally bundled so no missed-inheritance penalty applies. |
| Completeness (20%) | 10 | All 10 checklist items satisfied: 8 sections present, 26 DDL = 26 wiki elements, all rows have 5 cells and `(Tier N — source)` suffixes, property table complete, ASCII pipeline in §5.2, footer with tier counts, §1 has row count + date range, Regulation/MifID inline enumerations, review-needed sidecar contains no Elements section. |
| Business Meaning (15%) | 9 | §1 is specific and actionable: names row grain, date range, row count, dormancy status, instrument scope (InstrumentTypeID 5 & 6), author SP name, and migration provenance. Only micro-miss: no explicit mention of the DELETE+INSERT cadence in §1 (covered in §5 but not surfaced up front). |
| Data Evidence (10%) | 8 | 197.6M rows, precise date range, InstrumentType distribution (177.3M / 20.3M), Regulation='None' with exact 6,910-row count all signal real data queries. Footer "11/14" phases suggests P2/P3 completed. |
| Shape Fidelity (10%) | 9 | All required structural elements present: numbered sections, tier legend, SQL samples in §7, footer with quality score and phase counts. Minor deviation: footer quality self-score "7.5/10" is optimistic relative to actual issues. |

### Weighted total

```
0.25×3 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9
= 0.75 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
= 7.20  →  FAIL
```

---

### T1 Fidelity Table

The wiki claims **zero Tier 1 columns** (all 26 are tagged Tier 2). However, `BI_DB_DailyZeroPnL_Stocks` is a mirror of `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`, whose wiki IS present at `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md`. Per tier rules, passthroughs WITH upstream wiki present must be Tier 1. The table below covers the 5 sampled columns showing what the Dealing wiki says vs what the BI_DB wiki says:

| Column | Upstream quote (Dealing wiki) | Wiki quote (BI_DB) | Match | Loss |
|---|---|---|---|---|
| InstrumentType | "Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType)" | "Instrument type string (Stocks / ETF); only values 5=Stocks and 6=ETF are present. (Tier 2 — SP_DailyZeroPnL_Stocks)" | NO | Should be Tier 1 citing Dealing wiki; dropped source-column reference; "Stock" → "Stocks" typo |
| IsCFD | "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsSettled / HedgeServerID)" | "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 — SP_DailyZeroPnL_Stocks)" | MINOR | Should be Tier 1; dropped source-column reference in parenthetical |
| RealizedZero | "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL / NetProfit / CommissionOnClose)" | "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 — SP_DailyZeroPnL_Stocks)" | MINOR | Should be Tier 1; dropped source-column detail |
| UpdateDate | "Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())" | "Batch execution timestamp (GETDATE()). (Tier 2 — SP_DailyZeroPnL_Stocks)" | NO | Tier 3 → Tier 2 mis-tag; batch metadata must be Tier 3 per tier legend |
| Industry | "Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry)" | "Industry classification of the instrument (from Dim_Instrument). (Tier 2 — SP_DailyZeroPnL_Stocks)" | NO | Should be Tier 1 (mirror passthrough from Dealing); dropped source-column reference |

---

### Top 5 issues

1. **[HIGH] `UpdateDate` — Tier 2 instead of Tier 3.** The Dealing wiki explicitly tags this `(Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())`. The BI_DB wiki tags it Tier 2. The tier legend in the wiki itself says "Tier 3: Batch-system metadata; no upstream traceability" — `GETDATE()` is the canonical example. The footer also says "0 T3" confirming the writer missed this.

2. **[HIGH] All 26 passthrough columns mis-tiered as Tier 2 instead of Tier 1 (Dealing).** `BI_DB_DailyZeroPnL_Stocks` is a historical migration of `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` with identical schema. The Dealing wiki IS present in the knowledge base. Tier rule: passthrough WITH upstream wiki present = Tier 1. Writer's R5 justification ("upstream already documented them as Tier 2") is incorrect tier logic — the fact that Dealing internally calls columns Tier 2 from the SP does not cascade downstream; the BI_DB columns are Tier 1 relative to their immediate upstream (Dealing).

3. **[HIGH] Harness bundle failure.** The upstream bundle reported "NO UPSTREAM WIKI resolvable" but `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md` exists and was actively used by the writer (descriptions match near-verbatim). The harness's resolution step failed to include this file. This is the root cause of the tier failures and should be fixed before re-generation.

4. **[MEDIUM] `NOP` description drops FX conversion detail.** Dealing wiki: "Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP **via FX conversion**)". BI_DB wiki omits "via FX conversion" — this is semantically meaningful for analysts who need to know the USD conversion is applied.

5. **[MEDIUM] `OpenPositionValue` description semantic drift.** Dealing wiki: "Aggregated USD value of open positions (units × price). (Tier 2 -- SP_DailyZeroPnL_Stocks, **computed from NOP and FX rate**)". BI_DB wiki: "Aggregated USD value of open positions (units × price). (Tier 2 — SP_DailyZeroPnL_Stocks)" — drops the FX-rate computation detail which is important context for currency-aware analysts.

---

### Regeneration feedback

1. **Fix harness first**: Add `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md` to the upstream bundle for this object before re-generating. The resolution step must search for the migration source table wiki, not just DDL-declared FKs.
2. **Fix UpdateDate to Tier 3**: Change element 23 to `(Tier 3 — SP_DailyZeroPnL_Stocks, GETDATE())` verbatim from Dealing wiki.
3. **Promote all 26 passthrough columns to Tier 1**: Each column description should be quoted verbatim from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` and tagged `(Tier 1 — Dealing_dbo.Dealing_DailyZeroPnL_Stocks)`. Do not carry through the Tier 2 source attribution from Dealing's own descriptions.
4. **Restore FX conversion in NOP and OpenPositionValue descriptions**: Quote from Dealing wiki verbatim including "via FX conversion" and "computed from NOP and FX rate" details.
5. **Update footer tier counts**: Once UpdateDate is corrected to T3 and remaining 25 columns are promoted to T1, footer should read "25 T1, 0 T2, 1 T3, 0 T4."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DailyZeroPnL_Stocks",
  "weighted_score": 7.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentType",
      "upstream_quote": "Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType)",
      "wiki_quote": "Instrument type string (Stocks / ETF); only values 5=Stocks and 6=ETF are present. (Tier 2 — SP_DailyZeroPnL_Stocks)",
      "match": "NO",
      "loss": "Should be Tier 1 citing Dealing wiki; dropped source-column reference; 'Stock' rendered as 'Stocks'"
    },
    {
      "column": "IsCFD",
      "upstream_quote": "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsSettled / HedgeServerID)",
      "wiki_quote": "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 — SP_DailyZeroPnL_Stocks)",
      "match": "MINOR",
      "loss": "Should be Tier 1; dropped source-column detail in parenthetical"
    },
    {
      "column": "RealizedZero",
      "upstream_quote": "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL / NetProfit / CommissionOnClose)",
      "wiki_quote": "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 — SP_DailyZeroPnL_Stocks)",
      "match": "MINOR",
      "loss": "Should be Tier 1; dropped source-column detail"
    },
    {
      "column": "UpdateDate",
      "upstream_quote": "Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())",
      "wiki_quote": "Batch execution timestamp (GETDATE()). (Tier 2 — SP_DailyZeroPnL_Stocks)",
      "match": "NO",
      "loss": "Tier 3 downgraded to Tier 2; GETDATE() is canonical batch metadata and the Dealing wiki explicitly marks it Tier 3"
    },
    {
      "column": "Industry",
      "upstream_quote": "Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry)",
      "wiki_quote": "Industry classification of the instrument (from Dim_Instrument). (Tier 2 — SP_DailyZeroPnL_Stocks)",
      "match": "NO",
      "loss": "Should be Tier 1 (mirror passthrough from Dealing); dropped source-column reference"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged Tier 2 but should be Tier 3. The Dealing_DailyZeroPnL_Stocks wiki (which exists at knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md) explicitly marks UpdateDate as '(Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())'. GETDATE() is canonical batch metadata and the wiki's own tier legend defines Tier 3 as 'Batch-system metadata; no upstream traceability'. Footer incorrectly shows 0 T3."
    },
    {
      "severity": "high",
      "column_or_section": "All 26 elements",
      "problem": "BI_DB_DailyZeroPnL_Stocks is a schema-identical migration of Dealing_dbo.Dealing_DailyZeroPnL_Stocks. The Dealing wiki IS present in the knowledge base. Per tier rules, passthroughs WITH upstream wiki present must be Tier 1. The writer's review-needed R5 reasoning ('upstream already documented them as Tier 2 so BI_DB is also Tier 2') is incorrect: the Dealing table's own internal tier does not cascade; the BI_DB columns are Tier 1 relative to their immediate upstream (Dealing_DailyZeroPnL_Stocks)."
    },
    {
      "severity": "high",
      "column_or_section": "Upstream bundle",
      "problem": "The harness bundle incorrectly reported 'NO UPSTREAM WIKI resolvable' for this object. The Dealing_DailyZeroPnL_Stocks wiki (knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md) exists, was referenced by the writer in the lineage and review-needed sidecar, and was clearly consulted for descriptions (near-verbatim matches). The harness resolution step must be fixed to search for migration source table wikis."
    },
    {
      "severity": "medium",
      "column_or_section": "NOP",
      "problem": "Description drops FX conversion detail. Dealing wiki: 'Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion)'. BI_DB wiki omits 'via FX conversion' — semantically important for analysts interpreting USD values."
    },
    {
      "severity": "medium",
      "column_or_section": "OpenPositionValue",
      "problem": "Description semantic drift from upstream. Dealing wiki: 'computed from NOP and FX rate'. BI_DB wiki: 'units × price'. These are not equivalent — the actual computation uses NOP and FX-rate conversion, not raw units × price multiplication."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix harness — add knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md to the upstream bundle before regeneration. (2) Fix UpdateDate to Tier 3: '(Tier 3 — Dealing_dbo.Dealing_DailyZeroPnL_Stocks)' verbatim. (3) Promote all 25 remaining passthrough columns to Tier 1, citing Dealing_dbo.Dealing_DailyZeroPnL_Stocks as origin, using verbatim descriptions from that wiki. (4) Fix NOP description to include 'via FX conversion'. (5) Fix OpenPositionValue to 'computed from NOP and FX rate'. (6) Update footer tier counts to 25 T1, 0 T2, 1 T3, 0 T4.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["phases 12, 13, 14 (footer reports 11/14 completed; specific skipped phases not enumerated in footer)"]
  }
}
</JUDGE_VERDICT>
