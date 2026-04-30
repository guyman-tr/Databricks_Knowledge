I need to verify the SettlementTypeID description against the full Dim_Position wiki, since the upstream bundle was truncated.
Good. Now I have the full upstream description for SettlementTypeID. Let me compile the full evaluation.

---

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: **10/10**
Sampled 5 columns: CID, NetProfit, InstrumentID, IsSettled, UnrealizedPnLStart. All tier assignments are correct. Passthrough columns from Dim_Position correctly trace to Dim_Position's root origin (`Trade.PositionTbl`) per the dim-lookup rule. ETL-computed columns (UnrealizedPnLStart, UnrealizedPnLEnd, UnrealizedPnLChange) are correctly Tier 2. IsSettled correctly inherits Tier 5 from Dim_Position's wiki. No paraphrasing failures on sampled Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **9/10**
All 9 Tier 1 columns preserve the upstream Dim_Position descriptions verbatim. Three columns append context without losing anything: PositionID adds "Synapse distribution key", NetProfit adds "Passthrough from Dim_Position for positions closing on @date", IsBuy adds "Stored as int (not bit) in this table." No vendor names dropped, no NULL semantics lost, no semantic rewording. One trivial formatting difference (additions) prevents a perfect 10.

### Dimension 3 — Completeness: **10/10**
All 10 checklist items pass: 8 numbered sections present, 15/15 elements match DDL, all element rows have 5 cells with tier tags, property table has all required fields, ETL pipeline diagram uses real names, footer has tier breakdown, Section 1 has row count + date range, SettlementTypeID lists enum values, and `.review-needed.md` does not contain `## 4. Elements`.

### Dimension 4 — Business Meaning: **9/10**
Section 1 is specific and actionable: names the domain (unrealized P&L close adjustment for positions that closed during the day), row grain (one per closed PositionID per DateID), ETL SP, refresh pattern (daily, delete+insert), row count (~278M), and date range. Clearly explains why this table exists alongside BI_DB_PositionPnL. An analyst would immediately know when to query it.

### Dimension 5 — Data Evidence: **7/10**
Row count (~278M), date range (20230101–20240706), 188+ distinct dates, and specific NULL-rate claim for SettlementTypeID (~3.5%, 716K of 20.5M) suggest live data queries were run. However, no explicit Phase Gate Checklist section is present — only a footer claim of "Phases: 13/14". Cannot confirm P2+P3 were formally completed vs. claimed.

### Dimension 6 — Shape Fidelity: **9/10**
Follows the golden reference shape closely: numbered sections 1–8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section as a standalone numbered list.

---

## T1 Fidelity Table

| Column | Upstream (Dim_Position) | Wiki Description | Match | Loss |
|--------|------------------------|------------------|-------|------|
| CID | Customer ID. References Customer.Customer. | Customer ID. References Customer.Customer. | YES | — |
| PositionID | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Synapse distribution key. | MINOR | Added "Synapse distribution key" — no loss |
| NetProfit | Realized PnL. 0 when open; set on close. In position currency. | Realized PnL. 0 when open; set on close. In position currency. Passthrough from Dim_Position for positions closing on @date. | MINOR | Added passthrough context — no loss |
| InstrumentID | FK to Trade.Instrument. Financial instrument being traded. | FK to Trade.Instrument. Financial instrument being traded. | YES | — |
| MirrorID | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. | YES | — |
| Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. | YES | — |
| IsBuy | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Stored as int (not bit) in this table. | MINOR | Added type-widening note — no loss |
| HedgeServerID | FK to Trade.HedgeServer. Hedge server managing this position. | FK to Trade.HedgeServer. Hedge server managing this position. | YES | — |
| SettlementTypeID | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. | YES | — |

---

## Top 5 Issues

1. **Medium — Section 7, Query 7.1**: The `WHERE o.DateID = 20240701` filter is on the `o` (BI_DB_PositionPnL) alias, which eliminates right-side-only rows from the FULL OUTER JOIN. Positions that appear only in the close-adjustment table for that date would be excluded. Should use `WHERE COALESCE(o.DateID, c.DateID) = 20240701`.

2. **Low — Footer**: No explicit Phase Gate Checklist section. Footer claims "Phases: 13/14" but there's no section documenting which phases were completed vs. skipped.

3. **Low — Section 4, Tier Legend**: Lists Tier 5 as "Expert Review" but the legend row shows `(Tier 5 — Expert Review)` without stars, while the header says `*` = Tier 5. Cosmetic inconsistency only.

4. **Low — Section 1**: Claims "~278M rows" and "188+ distinct dates" — if 188 dates span 20230101–20240706 (~550 calendar days), that's only ~34% of days loaded. This is not flagged as unusual. Could confuse analysts expecting daily continuity.

5. **Info — Section 3.4, data freshness**: Correctly flags that data stops at 20240706. The review-needed sidecar also flags this appropriately.

---

## Regeneration Feedback

No regeneration required (PASS). Minor improvements for a future polish pass:

1. Fix Query 7.1 WHERE clause to `WHERE COALESCE(o.DateID, c.DateID) = 20240701` to avoid silently dropping close-adjustment-only rows.
2. Add a brief note in Section 1 explaining the 188 distinct dates out of ~550 calendar days (weekends/holidays excluded? or partial load history?).
3. Consider adding a Phase Gate Checklist section for transparency.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment",
  "weighted_score": 9.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID. References Customer.Customer.",
      "wiki_quote": "Customer ID. References Customer.Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PositionID",
      "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.",
      "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Synapse distribution key.",
      "match": "MINOR",
      "loss": "Added 'Synapse distribution key' — no semantic loss"
    },
    {
      "column": "NetProfit",
      "upstream_quote": "Realized PnL. 0 when open; set on close. In position currency.",
      "wiki_quote": "Realized PnL. 0 when open; set on close. In position currency. Passthrough from Dim_Position for positions closing on @date.",
      "match": "MINOR",
      "loss": "Added passthrough context — no semantic loss"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MirrorID",
      "upstream_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position.",
      "wiki_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Stored as int (not bit) in this table.",
      "match": "MINOR",
      "loss": "Added type-widening note — no semantic loss"
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "SettlementTypeID",
      "upstream_quote": "Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled.",
      "wiki_quote": "Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 7, Query 7.1",
      "problem": "FULL OUTER JOIN query uses WHERE o.DateID = 20240701 on the left alias, silently dropping rows that exist only in the close-adjustment table (right side). Should be WHERE COALESCE(o.DateID, c.DateID) = 20240701."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer claims 'Phases: 13/14' but does not document which phases were completed vs. skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4, Tier Legend",
      "problem": "Tier 5 row in legend shows one star (*) but the tag example says '(Tier 5 — Expert Review)' — minor cosmetic inconsistency with the star-count convention."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Claims '188+ distinct dates' across a ~550 calendar day span (20230101–20240706) without explaining why only ~34% of days have data. Trading-day gaps are expected but not called out."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4",
      "problem": "Correctly flags data stops at 20240706. Review-needed sidecar also flags this appropriately. No action needed."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["~278M rows", "188+ distinct dates", "~3.5% NULL SettlementTypeID (716K of 20.5M)"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
