I'll review this wiki systematically against the upstream bundle, DDL, and SP code.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy (Score: 7)

Random 5-column sample: **PositionID**, **IsBuy**, **InstrumentID**, **ChangeTypeID**, **EODPrice**.

- **PositionID** (Tier 1 — Dim_PositionChangeLog): Passthrough from `dpcl.PositionID`. Upstream wiki present. Tier 1 correct.
- **IsBuy** (Tier 1 — Trade.PositionTbl): Dim-lookup passthrough via `dp.IsBuy`. Dim_Position wiki traces to Trade.PositionTbl. Correct root origin.
- **InstrumentID** (Tier 1 — Trade.PositionTbl): Same pattern as IsBuy. Correct.
- **ChangeTypeID** (Tier 4): Passthrough from `dpcl.ChangeTypeID`. Upstream wiki (Dim_PositionChangeLog) IS present and documents this column. Per tier rules, passthrough with upstream wiki present → must be Tier 1. Tagged Tier 4 instead. **Mismatch.**
- **EODPrice** (Tier 2): Complex CASE expression with arithmetic and cross-rate logic. Tier 2 correct.

1 mismatch out of 5 → **Score: 7**

### Dimension 2 — Upstream Fidelity (Score: 9)

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs." | "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs." | YES | — |
| CID | "Customer ID who owns the position. Nullable (some system positions may not have CID)." | "Customer ID who owns the position. Nullable (some system positions may not have CID)." | YES | — |
| Occurred | "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog." | "Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog." | YES | — |
| OccurredDateID | "ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance." | "ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance." | YES | — |
| PreviousAmount | "Position amount (USD) before this change. NOT NULL -- always captured." | "Position amount (USD) before this change. NOT NULL -- always captured." | YES | — |
| AmountChanged | "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL." | "Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL." | YES | — |
| NewAmount | "Position amount after this change. Nullable -- may be absent for non-amount change types." | "Position amount after this change. Nullable -- may be absent for non-amount change types." | YES | — |
| PreviousStopRate | "Stop-loss rate before this change. NOT NULL." | "Stop-loss rate before this change. NOT NULL." | YES | — |
| StopRate | "Stop-loss rate after this change. NOT NULL." | "Stop-loss rate after this change. NOT NULL." | YES | — |
| PreviousAmountInUnits | "Unit count (shares/coins) before this change. Added for futures/unit-based positions." | "Unit count (shares/coins) before this change. Added for futures/unit-based positions. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL." | MINOR | Additive DWH note about backfill; upstream text preserved verbatim |
| AmountInUnits | "Unit count after this change." | "Unit count after this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL." | MINOR | Additive DWH note; upstream text preserved |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." (Dim_Position, root: Trade.PositionTbl) | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." (Dim_Position, root: Trade.PositionTbl) | "FK to Trade.Instrument. Financial instrument being traded." | YES | — |

All 13 Tier 1 columns are verbatim with 2 minor additive notes. No semantic loss, no paraphrasing, no dropped vendor names or NULL semantics.

**Score: 9** (all verbatim, 2 trivial additive formatting diffs)

### Dimension 3 — Completeness (Score: 10)

- [x] All 8 sections present (1–8)
- [x] Element count matches DDL: 19 DDL columns, 19 wiki elements
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP/table names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (86M) and date range (2023-01-01 to 2025-10-27)
- [x] ChangeTypeID (2 values) and IsBuy (2 values) list inline values
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 → **Score: 10**

### Dimension 4 — Business Meaning (Score: 10)

Section 1 is excellent: names the domain (EY audit reporting), row grain (position change events for ChangeTypeID 12 and 13), ETL SP (`SP_EY_Audit_ChangeLog`), refresh pattern (daily delete-insert with gap-filling), row count (86M), date range (2023-01-01 to 2025-10-27), and distribution of ChangeTypeIDs (99.98% type 12). A new analyst can immediately understand when and why to query this table.

**Score: 10**

### Dimension 5 — Data Evidence (Score: 8)

- Row count (86M) and date range present in Section 1
- Specific enum distributions: ChangeTypeID 12 = 99.98% (~85.95M), ChangeTypeID 13 = ~12.9K; IsBuy=1 ~98.5%
- NULL-rate claims: PreviousIsSettled/IsSettled ~85% NULL
- Footer says "Phases: 11/14" — no explicit P2/P3 checkbox visible, but data specificity strongly suggests live data was queried

**Score: 8**

### Dimension 6 — Shape Fidelity (Score: 9)

Numbered sections, tier legend in Section 4, 3 real SQL samples in Section 7, footer with quality score and phases-completed. Minor issue: property table has an empty `| | |` row between Synapse Index and UC Target.

**Score: 9**

## Weighted Total

```
weighted = 0.25*7 + 0.20*9 + 0.20*10 + 0.15*10 + 0.10*8 + 0.10*9
         = 1.75 + 1.80 + 2.00 + 1.50 + 0.80 + 0.90
         = 8.75
```

**Verdict: PASS**

## Top 5 Issues

1. **ChangeTypeID** (high): Tagged `(Tier 4 — inferred)` but it is a direct passthrough from Dim_PositionChangeLog which has an upstream wiki documenting this column. Per tier rules, passthrough with upstream wiki present → Tier 1. The upstream wiki's own Tier 4 classification should be noted in the description text, but the inheritance tier should be Tier 1.

2. **PositionID description** (medium): Verbatim quote includes "Distribution key -- co-located with Dim_Position for efficient JOINs" which is true for Dim_PositionChangeLog (HASH on PositionID) but false for BI_DB_EY_Audit_ChangeLog (ROUND_ROBIN). The inherited text creates a factual error in context. The gotchas section correctly notes ROUND_ROBIN, but the element description contradicts it.

3. **OccurredDateID description** (medium): Verbatim quote includes "Clustered index key" which is true for Dim_PositionChangeLog but false for this HEAP table. Same inherited-context problem as PositionID.

4. **PreviousIsSettled / IsSettled** (low): Tagged `(Tier 5 — Expert Review)` — these are passthroughs from Dim_PositionChangeLog. Strictly should be Tier 1 with the upstream's Tier 5 expert-confirmed content quoted. However, Tier 5 is higher confidence than Tier 1, so this doesn't degrade quality.

5. **Property table formatting** (low): Empty row `| | |` between Synapse Index and UC Target is a minor shape irregularity.

## Regeneration Feedback

1. Re-tag ChangeTypeID as `(Tier 1 — Dim_PositionChangeLog)` using the upstream wiki description verbatim; note in the description text that the upstream itself classifies meanings as unverified.
2. For PositionID, append a DWH note: "DWH note: In this table, PositionID is NOT the distribution key (table uses ROUND_ROBIN)." to prevent confusion from the inherited Dim_PositionChangeLog context.
3. For OccurredDateID, append a DWH note: "DWH note: In this table, there is no clustered index (HEAP). Filter on this column to reduce scan scope." to correct the inherited "Clustered index key" claim.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_ChangeLog",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs.",
      "wiki_quote": "FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID who owns the position. Nullable (some system positions may not have CID).",
      "wiki_quote": "Customer ID who owns the position. Nullable (some system positions may not have CID).",
      "match": "YES",
      "loss": null
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
      "wiki_quote": "ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance.",
      "match": "YES",
      "loss": null
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
      "wiki_quote": "Unit count (shares/coins) before this change. Added for futures/unit-based positions. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL.",
      "match": "MINOR",
      "loss": "Additive DWH note about backfill logic; upstream text preserved verbatim"
    },
    {
      "column": "AmountInUnits",
      "upstream_quote": "Unit count after this change.",
      "wiki_quote": "Unit count after this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL.",
      "match": "MINOR",
      "loss": "Additive DWH note; upstream text preserved verbatim"
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "ChangeTypeID",
      "problem": "Tagged (Tier 4 — inferred) but is a direct passthrough from Dim_PositionChangeLog which has an upstream wiki. Per tier rules, passthrough with upstream wiki present must be Tier 1. The upstream's own Tier 4 classification should be noted in the description text, but the inheritance tier should be Tier 1."
    },
    {
      "severity": "medium",
      "column_or_section": "PositionID",
      "problem": "Verbatim Tier 1 quote includes 'Distribution key -- co-located with Dim_Position for efficient JOINs' which is true for Dim_PositionChangeLog (HASH on PositionID) but false for this ROUND_ROBIN table. Creates a factual error in context despite correct Tier 1 inheritance."
    },
    {
      "severity": "medium",
      "column_or_section": "OccurredDateID",
      "problem": "Verbatim Tier 1 quote includes 'Clustered index key' which is true for Dim_PositionChangeLog but false for this HEAP table. Needs a DWH note to clarify the inherited statement does not apply here."
    },
    {
      "severity": "low",
      "column_or_section": "PreviousIsSettled / IsSettled",
      "problem": "Tagged (Tier 5 — Expert Review) but these are passthroughs from Dim_PositionChangeLog. Strictly should be Tier 1 citing the upstream. However, Tier 5 is higher confidence so this does not degrade quality."
    },
    {
      "severity": "low",
      "column_or_section": "Property table",
      "problem": "Empty row '| | |' between Synapse Index and UC Target is a minor formatting irregularity."
    }
  ],
  "regeneration_feedback": "No regeneration needed (PASS). For polish: (1) Re-tag ChangeTypeID as (Tier 1 — Dim_PositionChangeLog) with a note that upstream meanings are unverified. (2) Add DWH notes to PositionID and OccurredDateID clarifying that 'Distribution key' and 'Clustered index key' refer to the upstream table, not this ROUND_ROBIN HEAP table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2/P3 checkbox not explicitly visible; footer says 11/14 phases"]
  }
}
</JUDGE_VERDICT>
