## Judge Review: BI_DB_dbo.BI_DB_NOP_Risk_Daily

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (DateID, InstrumentID, IsSettled, InstrumentDisplayName, NOP). All tiers are correctly assigned. Passthroughs from BI_DB_PositionPnL correctly tagged Tier 1; the dim-lookup InstrumentDisplayName correctly traces to Tier 1 — Trade.InstrumentMetaData (the dim's root origin, not Tier 2 via SP); ETL-computed columns (InstrumentType, SellBuy, NOP, UpdateDate) correctly tagged Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 9/10**
All 4 Tier 1 columns are verbatim or near-verbatim. InstrumentDisplayName appends "Passthrough from Dim_Instrument" which is additive context, not semantic loss. No vendor names dropped, no NULL semantics removed. One trivial formatting addition.

**Dimension 3 — Completeness: 8/10 (9/10 checks passed)**
Missing: dictionary columns with ≤15 values (IsSettled has 2 values, SellBuy has 2, InstrumentType has 8) should have inline `key=value` pairs in the Elements table itself. The values are documented in Section 2 business logic but not in the element descriptions per the shape requirement.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (NOP risk reporting), row grain (DateID + InstrumentID + IsSettled + SellBuy), ETL SP name and step number, refresh pattern (delete+insert with rolling 1-month purge), row count (~359K), date range (20231216–20240116), and instrument count (4,816). Actionable and specific.

**Dimension 5 — Data Evidence: 7/10**
Row count, date range, and distribution breakdowns for InstrumentType and SellBuy are present and appear grounded. No explicit NULL-rate analysis. No formal Phase Gate Checklist with P2/P3 checkboxes — footer says "Phases: 11/14" but doesn't clarify which phases were skipped. Data claims appear genuine given specificity.

**Dimension 6 — Shape Fidelity: 9/10**
All 8 numbered sections present, tier legend in Section 4, real SQL in Section 7, footer with quality score, phases, and tier breakdown. Minor: no explicit phase gate checklist section.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| DateID | "Snapshot date as YYYYMMDD; partition key." (BI_DB_PositionPnL) | "Snapshot date as YYYYMMDD; partition key." | YES | — |
| InstrumentID | "Traded instrument." (BI_DB_PositionPnL) | "Traded instrument." | YES | — |
| IsSettled | "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable." (BI_DB_PositionPnL) | "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable." | YES | — |
| InstrumentDisplayName | "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs." (Dim_Instrument → Trade.InstrumentMetaData) | "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument." | MINOR | Added "Passthrough from Dim_Instrument" — no semantic loss |

### Top 5 Issues

1. **Severity: low | Section 4 (Elements)** — InstrumentType, SellBuy, and IsSettled have ≤15 distinct values but lack inline `key=value` enumeration in the Elements table. Values are documented in Section 2 but the completeness checklist requires them inline in Section 4 descriptions.

2. **Severity: low | Section 4 (Elements)** — InstrumentDisplayName element description says `(Tier 1 — Trade.InstrumentMetaData)` which is correct root origin, but adds "Passthrough from Dim_Instrument" which is technically accurate context. Not a defect but noted for completeness.

3. **Severity: low | Footer** — No formal Phase Gate Checklist section with explicit P2/P3 checkboxes. Footer states "Phases: 11/14" without listing which phases were completed vs skipped.

4. **Severity: low | Section 1** — Data staleness (max DateID = 20240116) is noted in the review-needed sidecar but not flagged in Section 1 summary with a warning icon or callout for analysts.

5. **Severity: low | Section 3.4** — "DateID is NOT a partition key in Synapse" gotcha is useful but the Elements table for DateID says "partition key" which is inherited from BI_DB_PositionPnL. This is slightly misleading for this table specifically — DateID is the clustered index column, not a partition key here.

### Regeneration Feedback

Not required (PASS). Minor improvements if desired:
1. Add inline `key=value` pairs for IsSettled (0=CFD, 1=Real), SellBuy (Buy, Sell), and InstrumentType (7 categories + Check) in the Elements table descriptions.
2. Remove "partition key" from DateID description — it is the clustered index column in this table, not a partition key.
3. Add a data staleness note in Section 1 (max date is January 2024).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_NOP_Risk_Daily",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "DateID",
      "upstream_quote": "Snapshot date as YYYYMMDD; partition key.",
      "wiki_quote": "Snapshot date as YYYYMMDD; partition key.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "Traded instrument.",
      "wiki_quote": "Traded instrument.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsSettled",
      "upstream_quote": "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable.",
      "wiki_quote": "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs.",
      "wiki_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument.",
      "match": "MINOR",
      "loss": "Added 'Passthrough from Dim_Instrument' — no semantic loss, additive context only"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 4 (InstrumentType, SellBuy, IsSettled)",
      "problem": "Dictionary columns with ≤15 distinct values lack inline key=value pairs in Elements table. Values documented in Section 2 but not inline per completeness checklist."
    },
    {
      "severity": "low",
      "column_or_section": "DateID",
      "problem": "Element description says 'partition key' inherited from BI_DB_PositionPnL upstream, but this table has no PARTITION clause — DateID is the clustered index column only. Misleading for analysts querying this specific table."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No formal Phase Gate Checklist with explicit P2/P3 checkboxes. Footer says 'Phases: 11/14' without specifying which were completed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Data staleness (max DateID = 20240116, over 2 years old) noted in review-needed sidecar but not called out prominently in Section 1 summary for analysts."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Minor addition of 'Passthrough from Dim_Instrument' beyond the verbatim upstream text. Not semantic loss but deviates from strict verbatim requirement."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)", "3 other unidentified phases"]
  }
}
</JUDGE_VERDICT>
