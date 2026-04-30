## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_ChangeLog

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled 5 columns: PositionID, CID, OccurredDateID, IsBuy, InstrumentID. PositionID and CID are sourced from `dpcl.PositionID` / `dpcl.CID` (Dim_PositionChangeLog) in the SP, but the wiki tags them as Tier 1 — Trade.PositionTbl using Dim_Position's descriptions. That's 2 mismatches out of 5.

**Dimension 2 — Upstream Fidelity: 3/10**
Of 13 claimed Tier 1 columns, 8 are verbatim correct, 2 are MINOR, and 3 are NO-match. PositionID and CID use the wrong upstream wiki entirely (Dim_Position instead of Dim_PositionChangeLog — a missed inheritance since the changelog wiki WAS in the bundle). PreviousAmountInUnits replaces the upstream text "Added for futures/unit-based positions" with transform-specific backfill notes.

**Dimension 3 — Completeness: 8/10**
9/10 checklist items pass. Missing: UC Target in property table. All 19 columns documented, all tier tags present, all 8 sections present, review-needed sidecar is clean.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent — names the domain (EY audit), row grain (ChangeTypeID 12/13 events), ETL SP, refresh pattern (daily delete-insert with gap-filling), row count (86M), and date range (2023-01-01 to 2025-10-27). Immediately actionable for a new analyst.

**Dimension 5 — Data Evidence: 7/10**
Row count, date range, ChangeTypeID distribution (99.98% type 12), NULL rates for settlement columns (~85%), and IsBuy skew (~98.5%) all present. No explicit Phase Gate Checklist section, but data claims appear genuine with specific numbers.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections, tier legend, real SQL in Section 7, footer with quality score and tier breakdown. Minor: no explicit Phase Gate Checklist block.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs." (Dim_PositionChangeLog) | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | NO | Wrong upstream — used Dim_Position wiki instead of Dim_PositionChangeLog wiki. Lost FK context, distribution note. |
| CID | "Customer ID who owns the position. Nullable (some system positions may not have CID)." (Dim_PositionChangeLog) | "Customer ID. References Customer.Customer." | NO | Wrong upstream — used Dim_Position wiki. Lost "who owns the position" context and nullable caveat for system positions. |
| Occurred | "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog." | "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog." | YES | — |
| OccurredDateID | "ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance." | "ETL-computed YYYYMMDD int from Occurred. Always filter on this for performance." | MINOR | Dropped "Clustered index key." |
| PreviousAmount | "Position amount (USD) before this change. NOT NULL -- always captured." | "Position amount (USD) before this change. NOT NULL -- always captured." | YES | — |
| AmountChanged | "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL." | "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL." | YES | — |
| NewAmount | "Position amount after this change. Nullable -- may be absent for non-amount change types." | "Position amount after this change. Nullable -- may be absent for non-amount change types." | YES | — |
| PreviousStopRate | "Stop-loss rate before this change. NOT NULL." | "Stop-loss rate before this change. NOT NULL." | YES | — |
| StopRate | "Stop-loss rate after this change. NOT NULL." | "Stop-loss rate after this change. NOT NULL." | YES | — |
| PreviousAmountInUnits | "Unit count (shares/coins) before this change. Added for futures/unit-based positions." | "Unit count (shares/coins) before this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL." | NO | Replaced "Added for futures/unit-based positions" with SP transform notes. Lost upstream context about futures/unit-based origin. |
| AmountInUnits | "Unit count after this change." | "Unit count after this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL." | MINOR | Upstream text preserved; added supplementary backfill note (acceptable addition). |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." (Dim_Position) | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." (Dim_Position) | "FK to Trade.Instrument. Financial instrument being traded." | YES | — |

### Top 5 Issues

1. **HIGH — PositionID (wrong upstream source)**: SP code uses `dpcl.PositionID` from Dim_PositionChangeLog. Wiki description and tier tag reference Trade.PositionTbl via Dim_Position instead. Should be Tier 1 — Dim_PositionChangeLog with that wiki's description verbatim.

2. **HIGH — CID (wrong upstream source)**: SP code uses `dpcl.CID` from Dim_PositionChangeLog. Wiki uses Dim_Position's description ("References Customer.Customer") instead of the changelog's ("Customer ID who owns the position. Nullable (some system positions may not have CID)").

3. **MEDIUM — PreviousAmountInUnits (paraphrased)**: Upstream description "Added for futures/unit-based positions" replaced with transform-specific backfill note. The upstream context about why this column exists (futures/unit-based positions) is lost.

4. **MEDIUM — OccurredDateID (minor paraphrase)**: Dropped "Clustered index key" from the upstream Dim_PositionChangeLog description.

5. **LOW — Missing UC Target in property table**: The property table has no UC Target row, reducing completeness.

### Regeneration Feedback

1. Re-source PositionID and CID as `(Tier 1 — Dim_PositionChangeLog)` using verbatim descriptions from the Dim_PositionChangeLog wiki: PositionID = "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs."; CID = "Customer ID who owns the position. Nullable (some system positions may not have CID)."
2. Restore PreviousAmountInUnits upstream text to "Unit count (shares/coins) before this change. Added for futures/unit-based positions." — append the backfill note as a separate "DWH note:" after the verbatim quote.
3. Restore "Clustered index key." to OccurredDateID description from Dim_PositionChangeLog wiki.
4. Add UC Target row to property table (or mark as N/A if not applicable).
5. For IsBuy and InstrumentID (from `dp.*`), the dim-lookup passthrough rule is correctly applied — keep as Tier 1 — Trade.PositionTbl. Only columns sourced from `dpcl.*` need the Dim_PositionChangeLog attribution.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_ChangeLog",
  "weighted_score": 6.40,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)",
      "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl)",
      "match": "NO",
      "loss": "Wrong upstream — used Dim_Position wiki description instead of Dim_PositionChangeLog wiki. Lost FK context, distribution co-location note."
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)",
      "wiki_quote": "Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl)",
      "match": "NO",
      "loss": "Wrong upstream — used Dim_Position wiki. Lost 'who owns the position' context and nullable caveat for system positions."
    },
    {
      "column": "Occurred",
      "upstream_quote": "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog.",
      "wiki_quote": "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "OccurredDateID",
      "upstream_quote": "ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance.",
      "wiki_quote": "ETL-computed YYYYMMDD int from Occurred. Always filter on this for performance.",
      "match": "MINOR",
      "loss": "Dropped 'Clustered index key.'"
    },
    {
      "column": "PreviousAmount",
      "upstream_quote": "Position amount (USD) before this change. NOT NULL -- always captured.",
      "wiki_quote": "Position amount (USD) before this change. NOT NULL -- always captured.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AmountChanged",
      "upstream_quote": "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL.",
      "wiki_quote": "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "NewAmount",
      "upstream_quote": "Position amount after this change. Nullable -- may be absent for non-amount change types.",
      "wiki_quote": "Position amount after this change. Nullable -- may be absent for non-amount change types.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PreviousStopRate",
      "upstream_quote": "Stop-loss rate before this change. NOT NULL.",
      "wiki_quote": "Stop-loss rate before this change. NOT NULL.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "StopRate",
      "upstream_quote": "Stop-loss rate after this change. NOT NULL.",
      "wiki_quote": "Stop-loss rate after this change. NOT NULL.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PreviousAmountInUnits",
      "upstream_quote": "Unit count (shares/coins) before this change. Added for futures/unit-based positions.",
      "wiki_quote": "Unit count (shares/coins) before this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL.",
      "match": "NO",
      "loss": "Replaced 'Added for futures/unit-based positions' with SP transform backfill notes. Lost upstream context about futures/unit-based origin."
    },
    {
      "column": "AmountInUnits",
      "upstream_quote": "Unit count after this change.",
      "wiki_quote": "Unit count after this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL.",
      "match": "MINOR",
      "loss": "Upstream text preserved; appended supplementary backfill note."
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "PositionID",
      "problem": "Tagged Tier 1 — Trade.PositionTbl with Dim_Position wiki description, but SP sources PositionID from dpcl.PositionID (Dim_PositionChangeLog). Should be Tier 1 — Dim_PositionChangeLog with that wiki's description: 'FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs.'"
    },
    {
      "severity": "high",
      "column_or_section": "CID",
      "problem": "Tagged Tier 1 — Trade.PositionTbl with Dim_Position wiki description, but SP sources CID from dpcl.CID (Dim_PositionChangeLog). Should be Tier 1 — Dim_PositionChangeLog with that wiki's description: 'Customer ID who owns the position. Nullable (some system positions may not have CID).'"
    },
    {
      "severity": "medium",
      "column_or_section": "PreviousAmountInUnits",
      "problem": "Upstream Dim_PositionChangeLog description 'Unit count (shares/coins) before this change. Added for futures/unit-based positions.' was replaced with SP transform-specific backfill note, losing the upstream context about futures/unit-based origin."
    },
    {
      "severity": "medium",
      "column_or_section": "OccurredDateID",
      "problem": "Dropped 'Clustered index key.' from the verbatim Dim_PositionChangeLog upstream description."
    },
    {
      "severity": "low",
      "column_or_section": "Property Table",
      "problem": "Missing UC Target row in property table. Should include UC Target or explicitly mark N/A."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-source PositionID as Tier 1 — Dim_PositionChangeLog with verbatim description 'FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs.' (2) Re-source CID as Tier 1 — Dim_PositionChangeLog with verbatim description 'Customer ID who owns the position. Nullable (some system positions may not have CID).' (3) Restore PreviousAmountInUnits upstream text to 'Unit count (shares/coins) before this change. Added for futures/unit-based positions.' with backfill note appended as separate DWH note. (4) Restore 'Clustered index key.' to OccurredDateID description. (5) Add UC Target to property table. Rule: columns sourced from dpcl.* must inherit from Dim_PositionChangeLog wiki; only columns sourced from dp.* (IsBuy, InstrumentID) should trace through to Dim_Position's origin via dim-lookup passthrough rule.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P12", "P13", "P14"]
  }
}
</JUDGE_VERDICT>
