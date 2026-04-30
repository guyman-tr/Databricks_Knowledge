## Judge Summary — BI_DB_dbo.BI_DB_PI_Positions

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Tier Accuracy** | 10 | 5/5 sampled columns (PositionID, OpenDateID, IsSettled, FullCommissionByUnits, UpdateDate) all correctly tiered. Passthroughs from Dim_Position correctly inherit Tier 1 with root origin; IsSettled correctly carried as Tier 5; UpdateDate correctly Tier 2. |
| **Upstream Fidelity** | 10 | All 16 Tier 1 columns preserve upstream Dim_Position descriptions verbatim. Additions are strictly additive context (e.g., "Passthrough from Dim_Position", "Synced via UPDATE") — no vendor names dropped, no NULL semantics removed, no paraphrasing losses. |
| **Completeness** | 10 | All 8 sections present. 18 elements match 18 DDL columns exactly. Every element row has 5 cells with tier tags. Property table complete. ETL pipeline diagram with real SP section references. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar clean of Elements section. |
| **Business Meaning** | 9 | Section 1 is specific and actionable: names domain (PI shadow cache), row grain, three ETL paths (backfill/incremental/close sync), ~24.1M rows, date range 2009–2024, consumers (sections 2.4–2.8, 3.6), data freshness issue. Missing only minor detail — could note the ~3,400 CID population size more prominently. |
| **Data Evidence** | 7 | Row count (24.1M), date range, ~7,534 distinct CIDs, IsSettled distribution (14.8M/9.3M in review-needed), GuruStatusID value mappings all present. Phase Gate not explicitly shown but footer indicates 11/14 phases. Data claims appear grounded in live queries. |
| **Shape Fidelity** | 9 | Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed list. Minor: no star-rating in tier legend (uses Tier N format instead), but this is a formatting preference not a structural issue. |

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position." | YES | — |
| CID | "Customer ID. References Customer.Customer." | "Customer ID. References Customer.Customer. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). Passthrough from Dim_Position." | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position." | YES | — |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position." | YES | — |
| Amount | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents)." | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). Synced via UPDATE when value changes in Dim_Position. Passthrough from Dim_Position." | YES | — |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position." | YES | — |
| OpenOccurred | "When position was persisted (mapped from Occurred in production). Default getutcdate()." | "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position." | YES | — |
| CloseOccurred | "When close was persisted." | "When close was persisted. '1900-01-01 00:00:00' sentinel = still open. Synced via UPDATE from Dim_Position." | MINOR | Added sentinel info from Dim_Position Section 2.1 — enrichment, not loss |
| ParentPositionID | "Copy-trade parent. 0/1 = root. Positive = child of referenced position." | "Copy-trade parent. 0/1 = root. Positive = child of referenced position. Passthrough from Dim_Position." | YES | — |
| OrigParentPositionID | "Original parent before any detachment." | "Original parent before any detachment. Passthrough from Dim_Position." | YES | — |
| MirrorID | "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position." | "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. Used to filter manual positions (MirrorID=0) for PI classification and instrument analysis. Passthrough from Dim_Position." | YES | — |
| OpenDateID | "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default." | "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Used as DELETE+INSERT key for daily incremental refresh. Passthrough from Dim_Position." | YES | — |
| CloseDateID | "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Partition column. Always include in WHERE clause." | "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position." | MINOR | Dropped "Partition column. Always include in WHERE clause" — Dim_Position-specific advice, irrelevant to this non-partitioned table |
| Volume | "ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0)." | "ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). Passthrough from Dim_Position." | YES | — |
| FullCommissionOnCloseOrig | "Original FullCommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0." | "Original FullCommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position." | YES | — |
| FullCommissionByUnits | "Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission." | "Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position." | YES | — |

### Top Issues

1. **Minor (CloseOccurred)**: Added sentinel value `'1900-01-01 00:00:00'` context not present in the upstream element description (though documented in Dim_Position Section 2.1). This is enrichment, not loss — acceptable.

2. **Minor (CloseDateID)**: Dropped Dim_Position-specific advice about partition pruning. Correct decision since BI_DB_PI_Positions is not partitioned.

3. **Minor (Phase Gate)**: No explicit Phase Gate Checklist in the wiki body. The footer references "Phases: 11/14" but the checklist with `[x]` marks is absent. This is a formatting gap, not a content gap.

4. **Observation (review-needed #4)**: The sidecar correctly flags that FullCommissionOnCloseOrig is Tier 2 in Dim_Position but promoted to Tier 1 here as a passthrough — this is the correct tier rule application and the sidecar appropriately flags it for human review.

5. **Observation (no issues found with dim-lookup tiers)**: This table has no dim-lookup passthroughs — all columns come directly from Dim_Position, not through intermediate dimension lookups. The writer correctly avoided the relay-tier trap.

### Regeneration Feedback

No regeneration needed. The wiki is high quality across all dimensions. If minor polish were desired:
1. Add an explicit Phase Gate Checklist section showing which data validation phases were completed.
2. Consider noting the ~3,400 active PI/CopyFund population size more prominently in Section 1 (currently buried in the ETL pipeline diagram).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_Positions",
  "weighted_score": 9.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.",
      "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID. References Customer.Customer.",
      "wiki_quote": "Customer ID. References Customer.Customer. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Amount",
      "upstream_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents).",
      "wiki_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). Synced via UPDATE when value changes in Dim_Position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "OpenOccurred",
      "upstream_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate().",
      "wiki_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CloseOccurred",
      "upstream_quote": "When close was persisted.",
      "wiki_quote": "When close was persisted. '1900-01-01 00:00:00' sentinel = still open. Synced via UPDATE from Dim_Position.",
      "match": "MINOR",
      "loss": "Added sentinel info from Dim_Position Section 2.1 — enrichment, not semantic loss"
    },
    {
      "column": "ParentPositionID",
      "upstream_quote": "Copy-trade parent. 0/1 = root. Positive = child of referenced position.",
      "wiki_quote": "Copy-trade parent. 0/1 = root. Positive = child of referenced position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "OrigParentPositionID",
      "upstream_quote": "Original parent before any detachment.",
      "wiki_quote": "Original parent before any detachment. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MirrorID",
      "upstream_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position.",
      "wiki_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. Used to filter manual positions (MirrorID=0) for PI classification and instrument analysis. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "OpenDateID",
      "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default.",
      "wiki_quote": "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Used as DELETE+INSERT key for daily incremental refresh. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CloseDateID",
      "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Partition column. Always include in WHERE clause.",
      "wiki_quote": "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Dropped 'Partition column. Always include in WHERE clause' — Dim_Position-specific advice irrelevant to this non-partitioned table"
    },
    {
      "column": "Volume",
      "upstream_quote": "ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0).",
      "wiki_quote": "ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FullCommissionOnCloseOrig",
      "upstream_quote": "Original FullCommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0.",
      "wiki_quote": "Original FullCommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FullCommissionByUnits",
      "upstream_quote": "Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission.",
      "wiki_quote": "Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "CloseOccurred",
      "problem": "Added sentinel value context ('1900-01-01 00:00:00' = still open) not in the upstream element-level description. This is enrichment from Dim_Position Section 2.1, not semantic loss. Acceptable."
    },
    {
      "severity": "low",
      "column_or_section": "CloseDateID",
      "problem": "Dropped Dim_Position-specific advice about partition pruning ('Partition column. Always include in WHERE clause'). Correct omission since BI_DB_PI_Positions is not partitioned."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "The ~3,400 active PI/CopyFund population size is mentioned only in the ETL pipeline diagram. Could be more prominent in the opening summary."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist with [x] marks. Footer shows 'Phases: 11/14' but individual phase completion status is not itemized."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["~24.1M rows", "~7,534 distinct CIDs", "2009-01-02 through 2024-04-14", "IsSettled: 14.8M CFD / 9.3M real (in review-needed)"],
    "skipped_phases": ["Phase Gate Checklist not explicitly shown"]
  }
}
</JUDGE_VERDICT>
