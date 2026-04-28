I need to check if any upstream wikis exist for Fact_CustomerUnrealized_PnL and V_M2M_Date_DateRange that might not have been included in the bundle.
Both upstream wikis exist but were NOT included in the bundle. Let me read them to check Tier 1 fidelity.
Now I have the full picture. Both `Fact_CustomerUnrealized_PnL` and `V_M2M_Date_DateRange` wikis exist in the repo but were **not included in the upstream bundle**. This is critical for the fidelity assessment — the writer could have inherited descriptions from FSE (which was in the bundle) but the wiki format doesn't even have a Description column.

---

## Adversarial Review: DWH_dbo.V_Liabilities

### Dimension 1 — Tier Accuracy: **8/10**

Sampled 5 columns:

| Column | Expected | Wiki Claims | Correct? |
|--------|----------|-------------|----------|
| CID (#1) | T1 — passthrough from FSE (wiki exists) | T1 | Yes |
| PositionPnL (#17) | T1 — passthrough from FCUPNL (wiki exists in repo) | T1 | Yes |
| LiabilitiesStockReal (#48) | T2 — ISNULL+ISNULL computation | T2 | Yes |
| TotalCryptoManualPosition (#33) | T2 — subtraction | T2 | Yes |
| NOP (#36) | T1 — passthrough from FCUPNL | T1 | Yes |

All 5 tier labels are correct (base score 10). However, because the wiki uses a non-standard Section 4 format (`# | Column | Source | Transformation | Tier` instead of `# | Element | Type | Nullable | Description`), there are **zero descriptions** on any Tier 1 column. Every T1 column is a description-absent failure. Deducting 2 for the format preventing any T1 content verification.

### Dimension 2 — Upstream Fidelity: **3/10**

This is the catastrophic failure. The wiki's Section 4 has **no Description column at all**. For all 63 Tier 1 columns, the "description" is just the word "Direct" in a Transformation column. No upstream text is quoted — not even attempted.

#### T1 Fidelity Table (representative sample across all 3 upstream sources)

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK." (FSE) | *(no description — Transformation: "Direct")* | NO | Entire description absent. Business context, FK target, distribution key info all lost. |
| TotalCash | "Customer's total cash balance for the day. Computed as: previous day's TotalCash + sum of TotalCashChange from History.ActiveCredit for @dt." (FSE) | *(no description — "Direct")* | NO | Running-balance computation context lost entirely. |
| Credit | "Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. Negative values represent outstanding obligations." (FSE) | *(no description — "Direct")* | NO | NULL semantics (negative = obligations), ROW_NUMBER selection logic lost. |
| BonusCredit | "Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: 'History.Credit.CreditTypeID = 5, 7 → BackOffice.BonusType.BonusTypeID'." (FSE) | *(no description — "Direct")* | NO | CreditTypeID mapping, vendor source chain lost. |
| TotalRealStocks | "Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT future. 'Real' means the customer owns the underlying asset." (FSE) | *(no description — "Direct")* | NO | IsSettled semantics, InstrumentTypeID filter, "real" definition lost. |
| PositionPnL | "Total unrealized PnL in USD across all open positions. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric." (FCUPNL) | *(no description — "Direct")* | NO | V1 formula reference, "primary PnL metric" designation lost. |
| StandardDeviation | "Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31." (FCUPNL) | *(no description — "Direct")* | NO | Covariance matrix methodology, date cutoff (pre-2013 = NULL) lost. |
| NOP | "Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short." (FCUPNL) | *(no description — "Direct")* | NO | Sign convention (long/short), "directional exposure" meaning lost. |
| DateID | "Individual calendar date key in YYYYMMDD integer format. Falls within the range defined by Dim_Range.FromDateID and Dim_Range.ToDateID." (V_M2M) | *(no description — "Direct (alias DateKey → DateID)")* | NO | YYYYMMDD format, range relationship context lost. |
| FullDate | "Calendar date corresponding to DateKey in native DATE format." (V_M2M) | *(no description — "Direct")* | NO | DATE type clarification lost. |

**Every single Tier 1 column fails fidelity.** The format structurally prevents verbatim quoting.

Additionally: `Fact_CustomerUnrealized_PnL` and `V_M2M_Date_DateRange` wikis exist in the repo but were NOT included in the upstream bundle. While this is partly a bundle-assembly failure, the writer also failed to quote FSE descriptions that WERE in the bundle.

### Dimension 3 — Completeness: **4/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | Yes |
| Element count = DDL count (75=75) | Yes |
| Every element row has 5 cells (# / Element / Type / Nullable / Description) | **NO** — uses Source/Transformation/Tier instead |
| Every description ends with `(Tier N — source)` | **NO** — no descriptions exist |
| Property table has Production Source, Refresh, Distribution, UC Target | **NO** — missing Refresh, Distribution, Production Source |
| Section 5.2 ETL pipeline ASCII diagram | **NO** — Section 5 is "Query Advisory" |
| Footer has tier breakdown counts | Yes |
| Section 1 has row count + date range | **NO** |
| Dictionary columns ≤15 values listed | N/A (credit) |
| .review-needed no `## 4. Elements` | Yes |

5/10 checks pass → score 4.

### Dimension 4 — Business Meaning: **8/10**

Section 1 is genuinely strong. The core formula breakdown (ActualNWA, Liabilities, Balance) with the BonusCredit clamping explanation is concrete and specific. The Confluence quotes add credibility. Key consumers are listed. However, **no row count** and **no date range** are provided.

### Dimension 5 — Data Evidence: **2/10**

Footer claims "Phases: 1,5,7,8,10,11" — **P2 and P3 are absent**. No row count, no date range, no NULL-rate analysis, no enum value distributions appear anywhere. Without P2/P3, any data claims would be fabricated, though the wiki is honest enough not to make any.

### Dimension 6 — Shape Fidelity: **5/10**

- Section 4 format is wrong (non-standard column headers)
- No tier legend in Section 4
- No Section 5.2 ETL pipeline ASCII diagram
- Real SQL samples in Section 7: present and correct
- Footer format is close but non-standard
- Numbered sections exist

---

### Top 5 Issues

1. **HIGH — Section 4 format entirely wrong.** Uses `# | Column | Source | Transformation | Tier` instead of `# | Element | Type | Nullable | Description`. This eliminates all per-column descriptions, making Tier 1 inheritance impossible. Affects all 75 columns.

2. **HIGH — Zero upstream fidelity.** All 63 Tier 1 columns lack descriptions entirely. The FSE wiki (in bundle) provides rich descriptions for 25 columns (e.g., `Credit`: "Negative values represent outstanding obligations"; `TotalRealStocks`: "IsSettled = 1, 'Real' means customer owns the underlying asset"). None of this appears. The FCUPNL wiki (exists in repo, 36 columns exposed) provides descriptions like `NOP`: "signed directional USD exposure" — also absent.

3. **MEDIUM — Missing row count and date range in Section 1.** The wiki claims "all dates before today" but provides no concrete date range or row count. An analyst cannot gauge table size.

4. **MEDIUM — No ETL pipeline diagram.** Section 5 is "Query Advisory" — there is no Section 5.2 with an ASCII pipeline diagram showing the view's data flow.

5. **LOW — CopyFundAUM source uncertain.** Listed as from `Fact_SnapshotEquity` but not in the FSE wiki's 32-column element list. The DDL uses it without a table alias. The review-needed sidecar flags this (item #5) but the wiki doesn't acknowledge the uncertainty.

---

### Regeneration Feedback

1. **Restructure Section 4 to use the standard format**: `| # | Element | Type | Nullable | Description |`. For views, derive Type from upstream wikis and Nullable from LEFT JOIN semantics (FCUPNL columns are nullable due to LEFT JOIN).

2. **For every Tier 1 column from FSE, quote the FSE wiki description verbatim** — including IsSettled semantics, InstrumentTypeID filters, formula details, and NULL conventions. Append `(Tier 1 — Fact_SnapshotEquity)`.

3. **For every Tier 1 column from FCUPNL, quote the FCUPNL wiki description verbatim** — including V1 formula references, sign conventions for NOP, covariance matrix details for StandardDeviation. Append `(Tier 1 — Fact_CustomerUnrealized_PnL)`. Note that FCUPNL columns are nullable in V_Liabilities due to the LEFT JOIN.

4. **Add row count and date range to Section 1** (requires P2 live data query).

5. **Add Section 5.2 ETL pipeline ASCII diagram** showing: `Fact_SnapshotEquity → V_M2M_Date_DateRange (date expansion) → LEFT JOIN Fact_CustomerUnrealized_PnL → WHERE DateKey < today → V_Liabilities`.

6. **Resolve CopyFundAUM source attribution** — verify which table it belongs to via `INFORMATION_SCHEMA.COLUMNS` and document accordingly.

7. **Run P2 and P3 phases** to obtain live data evidence (row counts, date ranges, NULL rates).

---

### Weighted Score

```
weighted = 0.25×8 + 0.20×3 + 0.20×4 + 0.15×8 + 0.10×2 + 0.10×5
         = 2.00 + 0.60 + 0.80 + 1.20 + 0.20 + 0.50
         = 5.30
```

**Verdict: FAIL**

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "V_Liabilities",
  "weighted_score": 5.3,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 3,
    "completeness": 4,
    "business_meaning": 8,
    "data_evidence": 2,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 — SP_Fact_SnapshotEquity)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "Entire description absent. FK target (Dim_Customer), distribution key role, grouping key context all lost."
    },
    {
      "column": "TotalCash",
      "upstream_quote": "Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read. (Tier 2 — SP_Fact_SnapshotEquity)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "Running-balance computation method, History.ActiveCredit source, 2020 methodology change all lost."
    },
    {
      "column": "Credit",
      "upstream_quote": "Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations. (Tier 2 — SP_Fact_SnapshotEquity)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "Negative value semantics (outstanding obligations), ROW_NUMBER selection logic, History.ActiveCredit source all lost."
    },
    {
      "column": "BonusCredit",
      "upstream_quote": "Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: 'History.Credit.CreditTypeID = 5, 7 → BackOffice.BonusType.BonusTypeID → History.Credit.BonusTypeID'. ISNULL to 0 in ETL. (Tier 2 — SP_Fact_SnapshotEquity)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "CreditTypeID mapping (5,7), BonusType chain, ISNULL-to-0 ETL behavior all lost."
    },
    {
      "column": "TotalRealStocks",
      "upstream_quote": "Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. 'Real' means the customer owns the underlying asset (settled/delivered). Updated via IsSettled change tracking from History.PositionChangeLog. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "IsSettled=1 filter, InstrumentTypeID IN (5,6), 'Real' = settled/delivered definition, PositionChangeLog tracking all lost."
    },
    {
      "column": "PositionPnL",
      "upstream_quote": "Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "V1 formula reference, 'primary PnL metric' designation, USD denomination all lost. (FCUPNL wiki exists in repo but was not in bundle)"
    },
    {
      "column": "StandardDeviation",
      "upstream_quote": "Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: sqrt(sum(weight_a * weight_b * covariance)). NULL for pre-2013 data. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "Covariance matrix methodology, date cutoff (pre-2013 NULL), formula all lost. (FCUPNL wiki exists in repo but was not in bundle)"
    },
    {
      "column": "NOP",
      "upstream_quote": "Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. 'eToro holding of each instrument' (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "Sign convention (positive=long, negative=short), directional exposure meaning, Confluence definition all lost. (FCUPNL wiki exists in repo but was not in bundle)"
    },
    {
      "column": "DateID",
      "upstream_quote": "Individual calendar date key in YYYYMMDD integer format. Falls within the range defined by Dim_Range.FromDateID and Dim_Range.ToDateID (inclusive). Primary key of Dim_Date. (Tier 2 — DDL + view logic)",
      "wiki_quote": "(no description — Transformation column says 'Direct (alias DateKey → DateID)')",
      "match": "NO",
      "loss": "YYYYMMDD format specification, Dim_Range relationship context lost. (V_M2M wiki exists in repo but was not in bundle)"
    },
    {
      "column": "FullDate",
      "upstream_quote": "Calendar date corresponding to DateKey in native DATE format. Provides the human-readable date for the YYYYMMDD integer key. (Tier 2 — DDL + view logic)",
      "wiki_quote": "(no description — Transformation column says 'Direct')",
      "match": "NO",
      "loss": "DATE type specification, relationship to DateKey integer lost. (V_M2M wiki exists in repo but was not in bundle)"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Section 4 (all 75 columns)",
      "problem": "Section 4 uses non-standard format (# | Column | Source | Transformation | Tier) instead of required (# | Element | Type | Nullable | Description). This eliminates all per-column descriptions, making Tier 1 verbatim inheritance structurally impossible."
    },
    {
      "severity": "high",
      "column_or_section": "All 63 Tier 1 columns",
      "problem": "Zero upstream descriptions quoted. FSE wiki was in the bundle with rich descriptions for 25 passthrough columns (CID, TotalCash, Credit, BonusCredit, TotalRealStocks, TotalRealCrypto, etc.). FCUPNL wiki exists in repo with descriptions for 36 passthrough columns (PositionPnL, NOP, StandardDeviation, etc.). V_M2M wiki exists for DateID and FullDate. None are quoted or referenced."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "No row count or date range provided. An analyst cannot gauge table size or data freshness without querying."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No ETL pipeline ASCII diagram (Section 5.2). Section 5 is 'Query Advisory' only. The view's 4-table join structure with date expansion logic warrants a visual pipeline."
    },
    {
      "severity": "low",
      "column_or_section": "CopyFundAUM (#34)",
      "problem": "Listed as from Fact_SnapshotEquity but CopyFundAUM is not in FSE wiki's 32-column element list. DDL uses it without table alias. Source attribution is uncertain — review-needed sidecar flags this but wiki does not acknowledge uncertainty."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Restructure Section 4 to standard format: | # | Element | Type | Nullable | Description | with descriptions ending in (Tier N — source). (2) For all 25 FSE passthrough columns, quote Fact_SnapshotEquity wiki descriptions VERBATIM — especially Credit (negative = obligations), TotalRealStocks (IsSettled=1 definition), BonusCredit (CreditTypeID 5,7 mapping). (3) Ensure FCUPNL wiki is included in bundle; for all 36 FCUPNL passthrough columns, quote descriptions verbatim — especially PositionPnL (V1 formula), NOP (signed directional exposure), StandardDeviation (covariance matrix, pre-2013 NULL). (4) Add row count and date range to Section 1 via P2 live query. (5) Add Section 5.2 ETL pipeline ASCII diagram. (6) Verify CopyFundAUM source table via INFORMATION_SCHEMA.COLUMNS. (7) Run P2 and P3 phases for data evidence.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
