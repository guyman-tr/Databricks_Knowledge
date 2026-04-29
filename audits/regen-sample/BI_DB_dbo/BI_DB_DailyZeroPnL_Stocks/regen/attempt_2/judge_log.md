## Review: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

### Critical Pre-Finding

The upstream bundle explicitly states: **"NO UPSTREAM WIKI was resolvable for any source listed in the lineage."** The immediate source `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` has no wiki in the bundle. This affects the entire Tier 1 assignment for 25 of 26 columns, since the tier legend defines Tier 1 as *"Verbatim from upstream production wiki"* — a condition that cannot be met when no wiki exists.

---

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Tier Accuracy** | 4 | Systemic: all 25 non-UpdateDate columns tagged Tier 1, but Tier 1 requires upstream wiki present (which doesn't exist). 3+ mismatches out of 5 sampled. Additionally IsCFD description conflates passthrough status with upstream derivation logic from 2 hops back. |
| **Upstream Fidelity** | 7 | Neutral per rubric — no upstream wiki in bundle. Descriptions are writer-inferred from DDL and SP source code, not quoted from any wiki. |
| **Completeness** | 8 | 9/10 checklist items. Miss: `IsManual` element description omits inline `0 = copy/automated, 1 = manual trade` key-value pairs (Section 2.2 covers it but the element table should be self-contained). All 26 DDL columns mapped. All 8 sections present. |
| **Business Meaning** | 9 | Excellent — row grain named precisely (date × hedge server × instrument × leverage × CFD × regulation × MiFID), row count (197.6M), date range (2019-01-01–2024-02-09), ETL pattern (one-time migration, dormant), source SP named. |
| **Data Evidence** | 6 | Row count, date range, and specific values present (6,910 rows with `Regulation='None'`). However: footer says "11/14 phases" with no Phase Gate Checklist section identifying which 3 were skipped. Cannot confirm P2+P3 (live data) ran. If skipped, all data claims are fabricated. |
| **Shape Fidelity** | 8 | Good structure throughout. Minor: footer has `Quality: regen-attempt-2` (attempt label) instead of a numeric quality score as required by the golden reference shape. |

**Weighted score:** `0.25×4 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×8 = 1.00 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80 = **6.75**`

---

### T1 Fidelity Table

All 25 Tier 1 columns have no upstream wiki to compare against. Every description is writer-inferred.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| Date | *(no upstream wiki)* | "Report date for the zero P&L snapshot." | NO | No upstream wiki — writer-inferred |
| HedgeServerID | *(no upstream wiki)* | "Hedge server identifier for the position set." | NO | No upstream wiki — writer-inferred |
| Industry | *(no upstream wiki)* | "Industry classification of the instrument (from Dim_Instrument)." | NO | No upstream wiki — writer-inferred; "(from Dim_Instrument)" is 2-hop attribution not from any wiki |
| InstrumentType | *(no upstream wiki)* | "Instrument type string (Stock / ETF)." | NO | No upstream wiki — writer-inferred |
| InstrumentID | *(no upstream wiki)* | "eToro instrument identifier." | NO | No upstream wiki — writer-inferred |
| InstrumentDisplayName | *(no upstream wiki)* | "Display name of the instrument." | NO | No upstream wiki — writer-inferred |
| StockIndex | *(no upstream wiki)* | "Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index." | NO | No upstream wiki — writer-inferred; NULL semantics are good but unverifiable against source |
| IsManual | *(no upstream wiki)* | "Flag indicating manual (non-automated) trading positions." | NO | No upstream wiki; missing inline 0/1 value map in element row |
| Leverage | *(no upstream wiki)* | "Position leverage tier." | NO | No upstream wiki — writer-inferred; no domain values listed |
| IsCFD | *(no upstream wiki)* | "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag." | NO | No upstream wiki; description incorrectly attributes derivation to BI_DB column when it is a passthrough (derivation is in SP_DailyZeroPnL_Stocks / Dealing_dbo) |
| Regulation | *(no upstream wiki)* | "Regulatory jurisdiction of the customer (e.g., ASIC, FCA, CySEC)." | NO | No upstream wiki — writer-inferred |
| MifID | *(no upstream wiki)* | "MiFID categorization ID of the customer snapshot." | NO | No upstream wiki — writer-inferred; no enum values listed |
| RealizedCommission | *(no upstream wiki)* | "Aggregate commission charged on positions closed on the report date." | NO | No upstream wiki — writer-inferred |
| RealizedZero | *(no upstream wiki)* | "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL)." | NO | No upstream wiki; formula is writer-inferred from SP source code |
| ChangeInUnrealizedZero | *(no upstream wiki)* | "Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment)." | NO | No upstream wiki; formula writer-inferred |
| TotalZero | *(no upstream wiki)* | "RealizedZero + ChangeInUnrealizedZero for the group." | NO | No upstream wiki — writer-inferred |
| NOP | *(no upstream wiki)* | "Net Open Position in USD for open positions in the group, via FX conversion." | NO | No upstream wiki — writer-inferred |
| OpenPositions | *(no upstream wiki)* | "Count of open positions in the group (as money type)." | NO | No upstream wiki; known type mismatch (count as money) noted but not explained in element row |
| NOP_Units | *(no upstream wiki)* | "Net open position in instrument units (signed: positive=long, negative=short)." | NO | No upstream wiki; sign semantics are good but unverifiable |
| VolumeOnOpen | *(no upstream wiki)* | "Cumulative open-action volume for positions opened on the report date." | NO | No upstream wiki — writer-inferred |
| VolumeOnClose | *(no upstream wiki)* | "Cumulative close-action volume for positions closed on the report date." | NO | No upstream wiki — writer-inferred |
| OpenPositionValue | *(no upstream wiki)* | "Aggregated USD value of open positions, computed from NOP and FX rate." | NO | No upstream wiki; "computed from NOP and FX rate" is writer inference |
| InstrumentName | *(no upstream wiki)* | "Short instrument name/ticker symbol." | NO | No upstream wiki — writer-inferred |
| Units | *(no upstream wiki)* | "Net units held across the group's open positions." | NO | No upstream wiki — writer-inferred |
| Currency | *(no upstream wiki)* | "Trade currency of the instrument (SellCurrency)." | NO | No upstream wiki; "(SellCurrency)" source attribution is writer inference |

---

### Top 5 Issues

1. **[HIGH] Systemic Tier 1 misuse across all 25 non-UpdateDate columns** — The tier legend states Tier 1 = "Verbatim from upstream production wiki." No upstream wiki for `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` exists in the bundle. All 25 element descriptions are writer-inferred. They should either be tagged differently (closest option would be Tier 3 for no upstream wiki, or a new label like "Tier 1*: passthrough, no upstream wiki") with a note explaining the absence. As written, every Tier 1 tag makes a claim the wiki cannot fulfill.

2. **[HIGH] IsCFD element description conflates passthrough with upstream derivation logic** — Element row says "Derived from HedgeServerID or IsSettled flag." `BI_DB_DailyZeroPnL_Stocks.IsCFD` is a passthrough migration from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`. The derivation from `IsSettled` occurs inside `SP_DailyZeroPnL_Stocks` when loading the Dealing table, not in the BI_DB schema. This misleads the analyst into thinking the BI_DB load computes IsCFD. The lineage table correctly says "Passthrough migration" but the element description contradicts it.

3. **[MEDIUM] Missing Phase Gate Checklist section; 3 skipped phases unidentified** — Footer says "Phases: 11/14" but no explicit checklist section names which phases were skipped. Cannot confirm P2 (distribution analysis) or P3 (enum/value profiling) ran. The specific claim of "~6,910 rows with `Regulation = 'None'`" requires live data access. If these phases were skipped, that numeric claim is fabricated.

4. **[MEDIUM] IsManual element description missing inline key=value mapping** — Description: "Flag indicating manual (non-automated) trading positions." No `0 = X, 1 = Y` values in the element row itself. Section 2.2 documents "IsManual = 1 when MirrorID = 0 (manual trade); IsManual = 0 for copy positions" but element tables must be self-contained per completeness checklist.

5. **[LOW] OpenPositions semantic mismatch not surfaced in element description** — Review-needed.md (R4) correctly flags that `OpenPositions` is typed as `money` but semantically is a count. The element description says "Count of open positions in the group (as money type)" which is accurate but doesn't warn the analyst that `SUM(OpenPositions)` may behave unexpectedly and that this is an inherited type mismatch from Dealing_dbo, not a design choice in BI_DB.

---

### Regeneration Feedback

1. **Tier labels for all 25 passthrough columns**: Since no upstream wiki for `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` was available in the bundle, add a note in the Tier Legend: `Tier 1*: Passthrough from upstream production table; upstream wiki not yet published.` Tag these columns `(Tier 1* — Dealing_dbo.Dealing_DailyZeroPnL_Stocks — no upstream wiki)` to be accurate without violating the definition.

2. **Fix IsCFD element description**: Remove "Derived from HedgeServerID or IsSettled flag" from the element row. That derivation occurs in `SP_DailyZeroPnL_Stocks` (Dealing_dbo). BI_DB copies the already-computed value. Correct element description: "1 = CFD position, 0 = Real stocks position. Passthrough from Dealing_dbo.Dealing_DailyZeroPnL_Stocks."

3. **Add explicit Phase Gate Checklist section** or annotate the footer with which 3 phases were skipped (e.g., `Phases passed: [list] | Skipped: [list]`). If P2/P3 ran, state this explicitly with the live query results. If not, remove the `~6,910 rows with Regulation='None'` numeric claim.

4. **Add `0 = copy/automated, 1 = manual trade` to IsManual element row** — make the element table self-contained.

5. **Add a note to OpenPositions element row** explaining the inherited type mismatch: "Note: stored as `money` type but represents a count of positions; design inherited from Dealing_dbo schema — treat as integer when aggregating."

6. **Replace `Quality: regen-attempt-2`** in the footer with a numeric quality score (e.g., `Quality: 6.75/10`) to match the golden reference shape.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DailyZeroPnL_Stocks",
  "weighted_score": 6.75,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 4,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "Date",
      "upstream_quote": null,
      "wiki_quote": "Report date for the zero P&L snapshot.",
      "match": "NO",
      "loss": "No upstream wiki for Dealing_dbo.Dealing_DailyZeroPnL_Stocks in bundle; description is writer-inferred, cannot be verbatim"
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": null,
      "wiki_quote": "Hedge server identifier for the position set.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "Industry",
      "upstream_quote": null,
      "wiki_quote": "Industry classification of the instrument (from Dim_Instrument).",
      "match": "NO",
      "loss": "No upstream wiki; 2-hop attribution '(from Dim_Instrument)' is writer inference"
    },
    {
      "column": "InstrumentType",
      "upstream_quote": null,
      "wiki_quote": "Instrument type string (Stock / ETF).",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": null,
      "wiki_quote": "eToro instrument identifier.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": null,
      "wiki_quote": "Display name of the instrument.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "StockIndex",
      "upstream_quote": null,
      "wiki_quote": "Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index.",
      "match": "NO",
      "loss": "No upstream wiki; NULL semantics and example values are writer-inferred"
    },
    {
      "column": "IsManual",
      "upstream_quote": null,
      "wiki_quote": "Flag indicating manual (non-automated) trading positions.",
      "match": "NO",
      "loss": "No upstream wiki; missing inline 0=copy/automated, 1=manual key-value pairs in element row"
    },
    {
      "column": "Leverage",
      "upstream_quote": null,
      "wiki_quote": "Position leverage tier.",
      "match": "NO",
      "loss": "No upstream wiki; no domain values or range described"
    },
    {
      "column": "IsCFD",
      "upstream_quote": null,
      "wiki_quote": "1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag.",
      "match": "NO",
      "loss": "No upstream wiki; description incorrectly attributes derivation to BI_DB column — derivation is in SP_DailyZeroPnL_Stocks (Dealing_dbo); BI_DB is a passthrough migration"
    },
    {
      "column": "Regulation",
      "upstream_quote": null,
      "wiki_quote": "Regulatory jurisdiction of the customer (e.g., ASIC, FCA, CySEC).",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "MifID",
      "upstream_quote": null,
      "wiki_quote": "MiFID categorization ID of the customer snapshot.",
      "match": "NO",
      "loss": "No upstream wiki; no enum values listed"
    },
    {
      "column": "RealizedCommission",
      "upstream_quote": null,
      "wiki_quote": "Aggregate commission charged on positions closed on the report date.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "RealizedZero",
      "upstream_quote": null,
      "wiki_quote": "Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL).",
      "match": "NO",
      "loss": "No upstream wiki; formula inferred from SP source code, not quoted from wiki"
    },
    {
      "column": "ChangeInUnrealizedZero",
      "upstream_quote": null,
      "wiki_quote": "Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment).",
      "match": "NO",
      "loss": "No upstream wiki; formula writer-inferred from SP source code"
    },
    {
      "column": "TotalZero",
      "upstream_quote": null,
      "wiki_quote": "RealizedZero + ChangeInUnrealizedZero for the group.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "NOP",
      "upstream_quote": null,
      "wiki_quote": "Net Open Position in USD for open positions in the group, via FX conversion.",
      "match": "NO",
      "loss": "No upstream wiki; FX conversion detail writer-inferred"
    },
    {
      "column": "OpenPositions",
      "upstream_quote": null,
      "wiki_quote": "Count of open positions in the group (as money type).",
      "match": "NO",
      "loss": "No upstream wiki; type mismatch (count stored as money) noted but not explained in element row"
    },
    {
      "column": "NOP_Units",
      "upstream_quote": null,
      "wiki_quote": "Net open position in instrument units (signed: positive=long, negative=short).",
      "match": "NO",
      "loss": "No upstream wiki; sign semantics writer-inferred"
    },
    {
      "column": "VolumeOnOpen",
      "upstream_quote": null,
      "wiki_quote": "Cumulative open-action volume for positions opened on the report date.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "VolumeOnClose",
      "upstream_quote": null,
      "wiki_quote": "Cumulative close-action volume for positions closed on the report date.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "OpenPositionValue",
      "upstream_quote": null,
      "wiki_quote": "Aggregated USD value of open positions, computed from NOP and FX rate.",
      "match": "NO",
      "loss": "No upstream wiki; computation detail writer-inferred from SP source"
    },
    {
      "column": "InstrumentName",
      "upstream_quote": null,
      "wiki_quote": "Short instrument name/ticker symbol.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "Units",
      "upstream_quote": null,
      "wiki_quote": "Net units held across the group's open positions.",
      "match": "NO",
      "loss": "No upstream wiki; description writer-inferred"
    },
    {
      "column": "Currency",
      "upstream_quote": null,
      "wiki_quote": "Trade currency of the instrument (SellCurrency).",
      "match": "NO",
      "loss": "No upstream wiki; '(SellCurrency)' source attribution is writer inference"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Section 4 Elements (all 25 Tier 1 columns)",
      "problem": "All 25 non-UpdateDate columns tagged Tier 1 but the tier legend defines Tier 1 as 'Verbatim from upstream production wiki.' No upstream wiki for Dealing_dbo.Dealing_DailyZeroPnL_Stocks exists in the bundle. Every description is writer-inferred, not a verbatim quote. Tier 1 claims are structurally false for all 25 columns."
    },
    {
      "severity": "high",
      "column_or_section": "IsCFD",
      "problem": "Element description says 'Derived from HedgeServerID or IsSettled flag.' BI_DB_DailyZeroPnL_Stocks.IsCFD is a passthrough migration from Dealing_dbo.Dealing_DailyZeroPnL_Stocks. The derivation from IsSettled occurs inside SP_DailyZeroPnL_Stocks (Dealing_dbo), not in the BI_DB load. This directly contradicts the lineage file which says 'Passthrough migration' for IsCFD and misleads analysts into thinking the BI_DB layer computes the flag."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 8 footer / Phase Gate",
      "problem": "Footer states 'Phases: 11/14' but no Phase Gate Checklist section identifies which 3 phases were skipped. Cannot confirm P2 (distribution analysis) and P3 (enum/value profiling) ran. Specific numeric claim '~6,910 rows with Regulation = None' requires live data access — if P2/P3 were skipped this claim is fabricated."
    },
    {
      "severity": "medium",
      "column_or_section": "IsManual",
      "problem": "Element description 'Flag indicating manual (non-automated) trading positions.' does not include inline key=value mapping (0 = copy/automated, 1 = manual trade). Completeness checklist requires dictionary columns with <=15 values to list inline key=value pairs. Section 2.2 covers this in business logic but element table must be self-contained."
    },
    {
      "severity": "low",
      "column_or_section": "OpenPositions",
      "problem": "Description correctly notes '(as money type)' but does not explain that this is an inherited type mismatch from Dealing_dbo design (count stored as money). Review-needed.md R4 flags this but it belongs in the element description so analysts know to treat aggregation with caution."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Add Tier 1* variant to the Tier Legend: 'Tier 1*: Passthrough from upstream production table; upstream wiki not yet published.' Re-tag all 25 passthrough columns as '(Tier 1* — Dealing_dbo.Dealing_DailyZeroPnL_Stocks — upstream wiki unavailable)' to avoid false verbatim claims. (2) Fix IsCFD element row: remove 'Derived from HedgeServerID or IsSettled flag' and replace with '1 = CFD position, 0 = Real stocks position. Passthrough from Dealing_dbo.Dealing_DailyZeroPnL_Stocks; derivation computed in source SP_DailyZeroPnL_Stocks.' (3) Add explicit Phase Gate Checklist section or annotate footer with which 3 phases were skipped. If P2/P3 did not run, remove the '~6,910 rows' Regulation claim. (4) Add inline '0 = copy/automated, 1 = manual trade' to IsManual element row. (5) Add type-mismatch warning to OpenPositions element row. (6) Replace 'Quality: regen-attempt-2' in footer with a numeric score.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "197.6M rows (Section 1 and header)",
      "~6,910 rows with Regulation='None' (Section 3.4 Gotchas)"
    ],
    "skipped_phases": ["3 phases skipped per footer '11/14' but not identified"]
  }
}
</JUDGE_VERDICT>
