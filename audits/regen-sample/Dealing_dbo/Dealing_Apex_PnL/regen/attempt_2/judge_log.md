I'll review this wiki systematically. Let me first verify the upstream wiki for the Tier 1 fidelity check.
Good — I have the Dim_Instrument elements confirmed. Let me read the specific element descriptions for InstrumentID (#1) and InstrumentDisplayName (#18).
Now I have everything I need for the full review.

---

## Adversarial Wiki Review: Dealing_dbo.Dealing_Apex_PnL

### Dimension 1 — Tier Accuracy: **9/10**

Random 5 columns selected: Date (#1), Trades (#8), InstrumentID (#13), Price_Start_DB (#16), Zero (#21).

| Column | Expected Tier | Wiki Tier | Match |
|--------|--------------|-----------|-------|
| Date | Tier 2 (SP parameter) | Tier 2 | YES |
| Trades | Tier 2 (SUM aggregation from EXT872) | Tier 2 | YES |
| InstrumentID | Tier 1 (dim-lookup passthrough, origin Trade.Instrument) | Tier 1 -- Trade.Instrument | YES |
| Price_Start_DB | Tier 2 (computed from PriceLog) | Tier 2 | YES |
| Zero | Tier 2 (SUM from sibling table) | Tier 2 | YES |

0/5 mismatches. However, InstrumentDisplayName (not in my random 5 but a Tier 1 column) has a **wrong origin attribution** — tagged `(Tier 1 -- Trade.Instrument)` but Dim_Instrument's own wiki tags it as `(Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)`, meaning the dim's origin is `Trade.InstrumentMetaData`, not `Trade.Instrument`. This is a misattribution: deduct 1.

### Dimension 2 — Upstream Fidelity: **8/10**

#### T1 Fidelity Table

| Column | Upstream Quote (Dim_Instrument) | Wiki Quote | Match | Loss |
|--------|-------------------------------|------------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | YES | — |
| InstrumentDisplayName | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." | YES (text), NO (origin) | Tier tag says `Trade.Instrument` but dim's origin is `Trade.InstrumentMetaData` (etoro_Trade_InstrumentMetaData). Wrong source attribution in tier tag. |

Description text for both T1 columns is character-for-character verbatim — excellent. However, InstrumentDisplayName's tier origin tag is misattributed (`Trade.Instrument` vs correct `Trade.InstrumentMetaData`). This is a wrong-origin error but not a paraphrasing failure on the description itself. Score: 8.

### Dimension 3 — Completeness: **10/10**

| Check | Present |
|-------|---------|
| All 8 sections (1-8) | YES |
| Element count = DDL count (21/21) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count + date range | YES (2,999,038 rows, 2021-02-10 to 2024-06-07) |
| Dictionary columns ≤15 values have inline key=value | YES (AccountNumber lists 5 accounts with percentages) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

10/10 checks pass.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is outstanding. It names the exact domain (Middle Office P&L reconciliation for Apex Clearing Corporation), the row grain (one instrument per account per reporting date), the ETL SP (SP_Apex_PnL), the refresh pattern (daily DELETE+INSERT), row count (2,999,038), date range (2021-02-10 to 2024-06-07), the 5 specific Apex accounts with distribution percentages, instrument matching logic, sibling tables, and dual price source rationale.

Minor issue: the header blurb says "weekly and daily P&L reconciliation table" but this specific table is weekly-window only; the daily sibling is `Dealing_Apex_PnL_Daily`. Section 1 body and Section 3.4 clarify this correctly, but the header is slightly misleading.

### Dimension 5 — Data Evidence: **9/10**

- Row count: YES (2,999,038)
- Date range: YES (2021-02-10 to 2024-06-07)
- Specific enum values: YES (5 accounts with percentages, TerminalID codes)
- NULL-rate claims: YES (NOP_Start 143K/5%, NOP_End 387K/13%, Trades 794K/26%, Dividends 2.95M/98%, InstrumentID 135K/4.5%, Zero 1.06M/35%)
- Phase Gate P2+P3: both marked `[x]`

All evidence is present and specific. Score: 9.

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score (8.5/10), phases completed (12/14), tier breakdown. Follows the golden reference shape closely. Minor: the property table has an empty row (`| | |`) which is slightly non-standard.

---

### Top 5 Issues

1. **InstrumentDisplayName wrong tier origin** (medium): Tagged `(Tier 1 -- Trade.Instrument)` but Dim_Instrument's wiki and lineage attribute this column to `Trade.InstrumentMetaData` (Tier 2 in the dim, via join-enrichment). The correct tag should be `(Tier 1 -- Trade.InstrumentMetaData)`.

2. **Header blurb says "weekly and daily"** (low): The opening summary line claims "weekly and daily P&L reconciliation table" but this specific table covers only weekly windows. `Dealing_Apex_PnL_Daily` is the daily sibling. The body correctly distinguishes them.

3. **PnL DDL type is decimal(24,6) but PnL_DBPrice is decimal(16,6)** (low/informational): The wiki correctly documents both types from the DDL, but the business logic section could note that PnL has wider precision (24 vs 16 digits) — likely to avoid overflow since NOP values can be large.

4. **Volume type discrepancy unremarked** (low): DDL has `Volume decimal(16,6)` but `Trades decimal(16,8)`. Both use the same source formula (Qty*Price+Fees) but different precision. The wiki documents both correctly but doesn't explain the 6 vs 8 decimal precision difference.

5. **No Section 6 "Referenced By" from outside the SP family** (informational): Section 6.2 only lists sibling tables from the same SP. If any reporting views or downstream tables consume Dealing_Apex_PnL, they're not documented. The review-needed sidecar doesn't flag this.

### Regeneration Feedback

1. Re-tag InstrumentDisplayName as `(Tier 1 -- Trade.InstrumentMetaData)` to match the dim's actual origin for that column.
2. Change header blurb from "weekly and daily P&L reconciliation table" to "weekly P&L reconciliation table" — the daily version is a separate sibling.
3. Both issues are minor. The wiki is otherwise excellent — verbatim T1 descriptions, comprehensive business logic, strong data evidence, and complete shape.

---

### Weighted Score Calculation

```
weighted = 0.25*9 + 0.20*8 + 0.20*10 + 0.15*9 + 0.10*9 + 0.10*9
         = 2.25 + 1.60 + 2.00 + 1.35 + 0.90 + 0.90
         = 9.00
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL",
  "weighted_score": 9.0,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 8,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "wiki_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries.",
      "wiki_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries.",
      "match": "MINOR",
      "loss": "Description text is verbatim. However, tier tag says '(Tier 1 -- Trade.Instrument)' but Dim_Instrument's own wiki and lineage attribute this column to Trade.InstrumentMetaData (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData). Wrong source attribution in the tier origin tag."
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Tagged '(Tier 1 -- Trade.Instrument)' but Dim_Instrument wiki tags this column as '(Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)'. The dim's origin is Trade.InstrumentMetaData, not Trade.Instrument. Correct tag should be '(Tier 1 -- Trade.InstrumentMetaData)'."
    },
    {
      "severity": "low",
      "column_or_section": "Header blurb (line 1)",
      "problem": "Header says 'weekly and daily P&L reconciliation table' but this table is weekly-window only. The daily sibling is Dealing_Apex_PnL_Daily. Misleading to describe this table as covering both."
    },
    {
      "severity": "low",
      "column_or_section": "Volume / Trades precision",
      "problem": "Trades is decimal(16,8) but Volume is decimal(16,6) despite using the same source formula (Qty*Price+Fees vs ABS(Qty*Price+Fees)). The wiki correctly documents both types but does not explain the precision difference."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Referenced By only lists sibling tables from the same SP. No downstream consumers (views, reports) are documented. May be accurate (no downstream references) but not explicitly confirmed."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Re-tag InstrumentDisplayName as '(Tier 1 -- Trade.InstrumentMetaData)' to match the dim's actual origin. (2) Change header blurb from 'weekly and daily P&L reconciliation table' to 'weekly P&L reconciliation table'.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P7 (no views)", "P10 (regen harness)"]
  }
}
</JUDGE_VERDICT>
