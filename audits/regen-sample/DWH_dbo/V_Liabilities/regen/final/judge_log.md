## Adversarial Wiki Judge — DWH_dbo.V_Liabilities

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy | 10 | 5 random columns (CID, TotalCryptoManualPosition, NOP_Crypto, LiabilitiesCrypto_TRS, TotalStockMarginLoanValue) all correctly tiered. No paraphrasing failures on FSE Tier 1 columns. |
| Upstream Fidelity | 8 | FSE columns are near-verbatim (only changelog dates dropped — "Added 2024-10-30 (Daniel Kaplan)" etc.). 28 columns from Fact_CustomerUnrealized_PnL tagged Tier 1 but no upstream wiki existed — neutral per rubric. |
| Completeness | 8 | 9/10 checklist items pass. Missing: explicit "Distribution" row in the Property table (info exists in Section 3.1 but not in the property table itself). |
| Business Meaning | 9 | Specific grain, domain, row count, date range, ETL pattern, downstream consumers, core formulas. An analyst can immediately understand when/why to query this view. |
| Data Evidence | 8 | Row counts (~6.8M), date range (2007+), distribution percentages for computed columns (64.5% Liabilities, 39.5% InUsedMargin), Phases 2+3 marked complete. |
| Shape Fidelity | 9 | All structural elements present: numbered sections, tier legend, ASCII pipeline diagram, real SQL samples, footer with quality score and phase list. Minor: no explicit Phase Gate Checklist section. |

### T1 Fidelity Table (Fact_SnapshotEquity columns — the only upstream with a wiki)

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK." | "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK." | YES | — |
| TotalPositionsAmount | "Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments." | Same | YES | — |
| TotalCash | "Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read." | Same | YES | — |
| RealizedEquity | "Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: ..." | Same | YES | — |
| TotalStockPositionAmount | "Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). Added with mutual exclusivity fix (Guy M, 2025-07-29)." | "Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6)." | MINOR | Dropped changelog note "Added with mutual exclusivity fix (Guy M, 2025-07-29)" |
| TotalCryptoPositionAmount | "Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. Confluence: \"TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount\" (approximately, excluding other types)." | "Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions." | MINOR | Dropped Confluence relationship note |
| Total_TRSCrypto | "Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). Added 2022-01-27." | Same minus "Added 2022-01-27." | MINOR | Dropped changelog date |
| TotalRealFutures | "Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30." | Same minus "Added 2024-10-30." | MINOR | Dropped changelog date |
| TotalStockMarginLoanValue | "Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate." | Same minus formula-update note | MINOR | Dropped changelog note |

All MINOR differences are changelog metadata (developer names, dates). No semantic content, vendor names, NULL semantics, or business logic was lost.

### Top 5 Issues

1. **Severity: low | Property table** — Missing explicit "Distribution" row. The HASH(CID) info is in Section 3.1 but the property table (which downstream tooling may parse) lacks it.

2. **Severity: low | TotalCryptoPositionAmount** — Dropped upstream Confluence note about `TotalCryptoPositionAmount + TotalStockPositionAmount ≈ TotalPositionsAmount`. This is a useful analyst relationship hint that was lost.

3. **Severity: low | Tier 1 tagging without upstream wiki** — 28 columns from Fact_CustomerUnrealized_PnL, 2 from V_M2M_Date_DateRange, and 1 from Fact_Guru_Copiers are tagged Tier 1 but no upstream wiki exists to copy from. The descriptions are well-written from DDL/context, but a strict reader might expect Tier 3 for "no upstream wiki available."

4. **Severity: info | Phase Gate Checklist** — No explicit Phase Gate section in the wiki body; phases are only listed in the footer. Minor shape deviation.

5. **Severity: info | TotalMirrorCryptoPositionAmount not in view** — The lineage file references `TotalMirrorCryptoPositionAmount` as a source column for the `TotalCryptoManualPosition` computation, but this column is never directly exposed in the SELECT. This is correct behavior (intermediate source), just noting for transparency.

### Regeneration Feedback

This wiki is high quality and passes. Minor improvements for a future iteration:

1. Add a "Distribution" row to the property table: `HASH(CID) — inherited from base tables`
2. Preserve the Confluence relationship note on TotalCryptoPositionAmount ("TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount")
3. Consider adding a note in the Tier Legend that for columns from tables without an existing wiki (Fact_CustomerUnrealized_PnL, V_M2M_Date_DateRange, Fact_Guru_Copiers), Tier 1 means "direct passthrough confirmed via DDL, description written from source SP logic"

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "V_Liabilities",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 8,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK.",
      "wiki_quote": "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TotalPositionsAmount",
      "upstream_quote": "Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments.",
      "wiki_quote": "Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TotalCash",
      "upstream_quote": "Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read.",
      "wiki_quote": "Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RealizedEquity",
      "upstream_quote": "Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: \"Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity.\"",
      "wiki_quote": "Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: \"Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity.\"",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TotalStockPositionAmount",
      "upstream_quote": "Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). Added with mutual exclusivity fix (Guy M, 2025-07-29).",
      "wiki_quote": "Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6).",
      "match": "MINOR",
      "loss": "Dropped changelog note: 'Added with mutual exclusivity fix (Guy M, 2025-07-29)'"
    },
    {
      "column": "TotalCryptoPositionAmount",
      "upstream_quote": "Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. Confluence: \"TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount\" (approximately, excluding other types).",
      "wiki_quote": "Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions.",
      "match": "MINOR",
      "loss": "Dropped Confluence relationship note about TotalCryptoPositionAmount + TotalStockPositionAmount ≈ TotalPositionsAmount"
    },
    {
      "column": "Total_TRSCrypto",
      "upstream_quote": "Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). Added 2022-01-27.",
      "wiki_quote": "Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership).",
      "match": "MINOR",
      "loss": "Dropped changelog date: 'Added 2022-01-27'"
    },
    {
      "column": "TotalRealFutures",
      "upstream_quote": "Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30.",
      "wiki_quote": "Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID.",
      "match": "MINOR",
      "loss": "Dropped changelog date: 'Added 2024-10-30'"
    },
    {
      "column": "TotalStockMarginLoanValue",
      "upstream_quote": "Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate.",
      "wiki_quote": "Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1.",
      "match": "MINOR",
      "loss": "Dropped changelog note: 'Formula updated 2025-12-10 to use InitConversionRate'"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Property table",
      "problem": "Missing explicit 'Distribution' row in the property table. HASH(CID) info is documented in Section 3.1 but not in the structured property table that tooling may parse."
    },
    {
      "severity": "low",
      "column_or_section": "TotalCryptoPositionAmount",
      "problem": "Dropped upstream Confluence relationship note: 'TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount (approximately, excluding other types)'. This is a useful analyst hint about column relationships."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (28 columns from Fact_CustomerUnrealized_PnL)",
      "problem": "28 columns from Fact_CustomerUnrealized_PnL tagged Tier 1 but no upstream wiki exists in the bundle. Descriptions are well-written from DDL/SP logic but cannot be 'verbatim copies' since there is nothing to copy from. A Tier Legend footnote would clarify this."
    },
    {
      "severity": "info",
      "column_or_section": "Shape — Phase Gate",
      "problem": "No explicit Phase Gate Checklist section in the wiki body; completed phases only listed in the footer line."
    },
    {
      "severity": "info",
      "column_or_section": "TotalStockMarginLoanValue",
      "problem": "Dropped 'Formula updated 2025-12-10 to use InitConversionRate' — minor changelog metadata but could be useful for analysts debugging historical formula changes."
    }
  ],
  "regeneration_feedback": "Wiki passes. For polish: (1) Add 'Distribution: HASH(CID) — inherited from base tables' to property table. (2) Preserve Confluence relationship note on TotalCryptoPositionAmount. (3) Add Tier Legend footnote explaining that Tier 1 columns from Fact_CustomerUnrealized_PnL are confirmed passthroughs via DDL but lack an upstream wiki to quote from.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["ActualNWA: ~0.06% nonzero (4,145 of 6.8M)", "Liabilities: 64.5% nonzero", "WA_Liabilities: 54.3% nonzero", "Liabilities_InUsedMargin: 39.5% nonzero", "CopyFundAUM: NULL for ~98.6% of CIDs"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
