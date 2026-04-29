# Adversarial Review: Dealing_dbo.Dealing_HedgeCost

## Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled 5 columns: Name (Tier 1 correct), InstrumentID (wiki says Tier 1 from "Hedge.ExecutionLog via Dim_Instrument" — should be Tier 2 per lineage; it's a GROUP BY key across multiple sources in the SP, not a simple passthrough), HC (Tier 2 correct), FullCommission (Tier 2 correct — it's `SUM(RealizedCommission)`), VariableSpread (wiki says Tier 2 but SP code is `v.VarCommission AS VariableSpread` — a direct passthrough from BI_DB_VarCommission, whose wiki IS in the bundle; should be Tier 1). Two clear mismatches = 5.

**Dimension 2 — Upstream Fidelity: 8/10**
Both claimed Tier 1 columns (Name, InstrumentID) are verbatim or near-verbatim from upstream wikis. However, VariableSpread is a missed inheritance: it's a direct passthrough from `BI_DB_VarCommission.VarCommission` with the upstream wiki available in the bundle, yet tagged Tier 2. Deduct 2 for that missed inheritance. Base 10 - 2 = 8.

**Dimension 3 — Completeness: 8/10**
9 of 10 checklist items pass. Missing: UC Target row in the property table (no Unity Catalog target listed). All 8 sections present, element count matches DDL (15=15), all element rows have 5 cells with tier tags, pipeline diagram uses real names, footer has tier breakdown, Section 1 has row count + date range, review-needed sidecar does not contain `## 4. Elements`, IsSettled values listed inline.

**Dimension 4 — Business Meaning: 9/10**
Excellent. Section 1 names the domain (hedge cost for USD stocks/ETFs), row grain (Date + InstrumentID + HedgeServerID + IsSettled), ETL SP (SP_HedgeCost), refresh pattern (daily DELETE-INSERT), row count (7.85M), date range (2021-01-04 to 2026-04-25), and core metric (HC formula). A new analyst would know exactly when to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count and date range present. Specific distributions cited: ~64% Real / ~36% CFD for IsSettled, ~55% zero LP_Executed_Units, ~29% NULL VariableSpread, 6,447 distinct instruments, 25 hedge servers. Phase Gate Checklist in footer says "Phases: 12/14" but doesn't explicitly mark which P2/P3 checks were done. Data claims appear credible and internally consistent.

**Dimension 6 — Shape Fidelity: 8/10**
All numbered sections present. Tier legend in Section 4. Real SQL in Section 7 (3 queries). Footer has quality score and phases-completed. Minor: UC Target missing from property table; footer uses non-standard "Phases: 12/14" format rather than listing specific phase numbers.

---

## T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument." (Hedge.ExecutionLog #4) | "The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. Filtered to SellCurrencyID=1 (USD) and InstrumentTypeID IN (5,6) (stocks/ETFs)." | YES | Verbatim core + added filter context (acceptable). But source attribution is wrong — should cite Dim_Position as primary source, not ExecutionLog. |
| Name | "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName)." (Dim_Instrument #4) | "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Passthrough from Dim_Instrument." | YES | Verbatim + appended passthrough note. |

---

## Top 5 Issues

1. **HIGH — VariableSpread (#15) missed Tier 1 inheritance**: SP code is `v.VarCommission AS VariableSpread` — a direct passthrough rename from `BI_DB_VarCommission.VarCommission`. The BI_DB_VarCommission wiki is in the bundle. Should be `(Tier 1 -- upstream wiki, BI_DB_VarCommission.VarCommission)` with verbatim description from upstream.

2. **HIGH — InstrumentID (#2) wrong tier and source**: Tagged `(Tier 1 -- upstream wiki, Hedge.ExecutionLog via Dim_Instrument)`. InstrumentID is a GROUP BY key across multiple SP temp tables (#Clients from Dim_Position, #LP from ExecutionLog). The lineage file correctly marks it Tier 2. Source attribution "Hedge.ExecutionLog via Dim_Instrument" is also wrong — the primary source in the final SELECT is `#Final.InstrumentID` which aggregates from `#Clients` (Dim_Position). Should be Tier 2 from SP_HedgeCost.

3. **MEDIUM — No UC Target in property table**: The property table omits Unity Catalog target, format, partitioning, and table type rows that other wikis in this repo include. If this table has a UC export (or is pending one), it should be documented.

4. **MEDIUM — Fact_CurrencyPriceWithSplit JOIN missing isvalid filter**: The SP joins `Fact_CurrencyPriceWithSplit` on `OccurredDateID = @DateInt AND InstrumentID = f.InstrumentID` without `isvalid = 1`. The Fact_CurrencyPriceWithSplit wiki notes ~46% of rows are `isvalid=0`. This is documented in the review-needed sidecar but not flagged in Section 3.4 Gotchas — an analyst reading only the wiki would not know the HC calculation may use an arbitrary price row.

5. **LOW — FullCommission column description incomplete on aggregation scope**: The wiki says "Aggregate realized commission from positions closed on the report date" but the SP shows `SUM(z.RealizedCommission)` is grouped by InstrumentID + HedgeServerID + IsCFD across all leverages, regulations, etc. in `Dealing_DailyZeroPnL_Stocks`. The aggregation scope (across MifID, Regulation, Leverage, IsManual) could surprise analysts expecting instrument-level granularity.

---

## Regeneration Feedback

1. Re-tag VariableSpread (#15) as `(Tier 1 -- upstream wiki, BI_DB_VarCommission.VarCommission)` and use verbatim description from BI_DB_VarCommission wiki: "Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings."
2. Re-tag InstrumentID (#2) as `(Tier 2 -- SP_HedgeCost)` with source attribution to `DWH_dbo.Dim_Position + CopyFromLake.etoro_Hedge_ExecutionLog` (grouping key).
3. Add UC Target rows to the property table (or note explicitly if no UC export exists).
4. Add a Gotcha in Section 3.4 about the missing `isvalid = 1` filter on the Fact_CurrencyPriceWithSplit JOIN — this is a data quality risk that analysts need to know about.
5. Update footer tier counts to reflect the corrected tiers (should be 1 T1, 13 T2, 1 T3 after fixes).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_HedgeCost",
  "weighted_score": 7.3,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 8,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument.",
      "wiki_quote": "The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. Filtered to SellCurrencyID=1 (USD) and InstrumentTypeID IN (5,6) (stocks/ETFs).",
      "match": "YES",
      "loss": "Verbatim core preserved. But tier should be 2 (grouping key) and source attribution is wrong (says Hedge.ExecutionLog via Dim_Instrument, should cite Dim_Position as primary)."
    },
    {
      "column": "Name",
      "upstream_quote": "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName).",
      "wiki_quote": "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Passthrough from Dim_Instrument.",
      "match": "YES",
      "loss": "None. Verbatim with appended passthrough note."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "VariableSpread (#15)",
      "problem": "Tagged Tier 2 (SP_HedgeCost, BI_DB_VarCommission.VarCommission) but SP code is a direct passthrough: v.VarCommission AS VariableSpread. BI_DB_VarCommission wiki is in the bundle. Should be Tier 1 with verbatim upstream description."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID (#2)",
      "problem": "Tagged Tier 1 (Hedge.ExecutionLog via Dim_Instrument) but it is a GROUP BY key across multiple SP temp tables. Lineage file correctly says Tier 2. Source attribution wrong: primary source is Dim_Position, not ExecutionLog."
    },
    {
      "severity": "medium",
      "column_or_section": "Property Table",
      "problem": "Missing UC Target, UC Format, UC Partitioned By, and UC Table Type rows. Other wikis in this repo include these."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 3.4 Gotchas",
      "problem": "Missing gotcha about Fact_CurrencyPriceWithSplit JOIN lacking isvalid=1 filter. The FCPWS wiki notes ~46% of rows are isvalid=0. HC calculation may use arbitrary price row. Documented in review-needed sidecar but not in the wiki itself."
    },
    {
      "severity": "low",
      "column_or_section": "FullCommission (#14)",
      "problem": "Description says 'Aggregate realized commission from positions closed on the report date' but does not clarify the aggregation crosses all Leverage, Regulation, MifID, and IsManual values from DailyZeroPnL_Stocks. Analysts expecting instrument-level match may be surprised."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag VariableSpread as Tier 1 from BI_DB_VarCommission.VarCommission with verbatim upstream description. (2) Re-tag InstrumentID as Tier 2 from SP_HedgeCost (grouping key from Dim_Position + ExecutionLog). (3) Add UC Target rows to property table. (4) Add Gotcha about missing isvalid=1 filter on Fact_CurrencyPriceWithSplit JOIN. (5) Update footer tier counts to reflect corrected tiers.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
