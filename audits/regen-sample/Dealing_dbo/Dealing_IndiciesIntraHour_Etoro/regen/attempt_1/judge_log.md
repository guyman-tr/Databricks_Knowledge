## Adversarial Review: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: Date (#1), LiquidityAccountName (#5), VolumeBuy (#7), NOP (#10), HedgeServerID (#15).

| Column | Lineage | Expected Tier | Wiki Claims | Match? |
|--------|---------|---------------|-------------|--------|
| Date | CONVERT(DATE, fromMinute) — generated in SP | Tier 2 | Tier 2 | YES |
| LiquidityAccountName | Passthrough from etoro_Trade_LiquidityAccounts (no wiki) | Tier 2 | Tier 2 | YES |
| VolumeBuy | SUM(Units*ExecutionRate)*ConversionFirst — computed | Tier 2 | Tier 2 | YES |
| NOP | Complex aggregation formula — computed | Tier 2 | Tier 2 | YES |
| HedgeServerID | Passthrough from ExecutionLog/Netting (no wiki) | Tier 2 | Tier 2 | YES |

All upstream staging sources (etoro_Hedge_ExecutionLog, etoro_Hedge_Netting, etoro_Trade_LiquidityAccounts) are unresolved — no wikis exist. Dim_Position and Dim_Customer are only used on the CLIENT side of SP_IntraHourIndexReport, not the Etoro side (confirmed by reading the SP code — `#Positions` feeds into `#Volume`, `#OP_complete`, `#Realized` which all go into the Clients INSERT, while the Etoro INSERT uses `#TOTS` built from `#NOP_by_minute`/`#Volume_E`). Zero Tier 1 is correct.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist. All 15 columns are Tier 2 with no upstream wiki available for inheritance. This is the correct outcome — the Etoro side sources exclusively from staging tables with no documented wikis.

**T1 Fidelity Table**: Empty — no Tier 1 columns to evaluate.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES (1–8) |
| Element count = DDL count | YES (15/15) |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES (0 T1, 15 T2, 0 T3, 0 T4, 0 T5) |
| Section 1 has row count and date range | YES (~8.7M, 2022-05-22 to 2026-04-26) |
| Dictionary columns ≤15 values list inline | YES (InstrumentID: 254/255/259; LiquidityAccountName: 2 values; HedgeServerID: 8/25) |
| review-needed does NOT contain `## 4. Elements` | YES |

### Dimension 4 — Business Meaning: **10/10**

Section 1 is exceptional. It names the domain (hedge-side intra-hour hedging activity), specifies the row grain (one minute × one liquidity account × one hedge instrument × one hedge server), names the ETL SP, describes the delete-insert refresh pattern, gives row count and date range, explains the companion table relationship, lists concrete instrument IDs with their index names, documents active liquidity accounts by name and ID, and walks through the 7-step ETL process. A new analyst would immediately understand when and how to query this table.

### Dimension 5 — Data Evidence: **7/10**

Row count (~8.7M) and date range (2022-05-22 to 2026-04-26) are present. Specific enum values are documented (instrument IDs, liquidity account names/IDs, hedge server IDs). NULL-rate for HedgeServerID is addressed (NULL for pre-2024, 142 NULLs in 2026 per review-needed). However, there is no explicit Phase Gate Checklist section — the footer says "Phases: 11/14" but doesn't show P2/P3 checkboxes. The data claims appear grounded but the audit trail for how they were obtained is implicit rather than explicit.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with tier breakdown and phases completed — all present. Minor deviations: no numeric quality score in footer (just "Phases: 11/14"), tier legend is a simplified single-row table rather than the multi-row stars format seen in the companion wiki. These are cosmetic.

### Top 5 Issues

1. **Medium — Section 7.3 query**: The client-vs-eToro comparison query joins on `c.HedgeServerID = e.HedgeServerID`, but for pre-2024 data both sides are NULL and `NULL = NULL` evaluates to false in SQL. This query silently drops all pre-2024 rows. Should use `ISNULL(c.HedgeServerID, -1) = ISNULL(e.HedgeServerID, -1)` or note the limitation.

2. **Low — ValueEnd self-join missing HedgeServerID**: The SP's Etoro self-join (`te.toMinute=te1.fromMinute AND te.LiquidityAccountID=te1.LiquidityAccountID AND te.InstrumentID=te1.InstrumentID`) does not include HedgeServerID. The wiki accurately describes this but doesn't flag it as a potential data quality issue — if multiple HedgeServerIDs exist for the same LP+instrument+minute, the LEFT JOIN could produce unexpected results.

3. **Low — No Phase Gate Checklist section**: Footer says "Phases: 11/14" but there's no explicit P1/P2/P3 checklist section with checkboxes, making it harder to audit which data-gathering phases were executed.

4. **Low — HedgeServerID discrepancy in review-needed**: The review-needed mentions "HedgeServerID=225 appeared only 4 times" but the wiki body says active values are 8, 25. This may be a typo (225 vs 25) or a real third value; either way it's inconsistent.

5. **Cosmetic — Companion table join note in Section 3.4**: The gotcha correctly warns about instrument ID mapping but could explicitly note that the client table uses different HedgeServerID values (5, 8, 20, 1776) than the Etoro table (8, 25), meaning only HedgeServerID=8 overlaps.

### Regeneration Feedback

1. Fix Section 7.3 query to handle NULL HedgeServerID in pre-2024 joins (use ISNULL or add a comment warning).
2. Add a note in Section 3.4 gotchas about the ValueEnd self-join not including HedgeServerID.
3. Add an explicit Phase Gate Checklist section or expand the footer to show P1/P2/P3 status.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.50 + 0.70 + 0.80
         = 8.90
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_IndiciesIntraHour_Etoro",
  "weighted_score": 8.9,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 7.3 (Sample Query)",
      "problem": "Client-vs-eToro comparison query joins on c.HedgeServerID = e.HedgeServerID, but for pre-2024 data both sides are NULL and NULL=NULL is false in SQL. This silently drops all pre-2024 rows. Should use ISNULL or document the limitation."
    },
    {
      "severity": "low",
      "column_or_section": "ValueEnd",
      "problem": "The SP self-join for ValueEnd does not include HedgeServerID (only LiquidityAccountID + InstrumentID + minute). Wiki accurately describes this but doesn't flag the potential data quality issue if multiple HedgeServerIDs share the same LP+instrument+minute."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Shape",
      "problem": "No explicit Phase Gate Checklist section with P1/P2/P3 checkboxes. Footer says 'Phases: 11/14' but doesn't detail which phases were executed vs skipped."
    },
    {
      "severity": "low",
      "column_or_section": "review-needed.md Section 2.3",
      "problem": "Review-needed mentions 'HedgeServerID=225 appeared only 4 times' but wiki body documents active values as 8 and 25. Inconsistency (typo 225 vs 25, or undocumented third value)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 (Gotchas)",
      "problem": "Gotchas warn about instrument ID mapping for client-vs-eToro joins but don't note that HedgeServerID values differ between tables (client: 5/8/20/1776; Etoro: 8/25), with only HedgeServerID=8 overlapping."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Fix Section 7.3 query to handle NULL HedgeServerID in pre-2024 joins. (2) Add a gotcha note about the ValueEnd self-join not including HedgeServerID. (3) Add explicit Phase Gate Checklist section or expand footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "~8.7M rows",
      "2022-05-22 to 2026-04-26",
      "InstrumentIDs: 254, 255, 259",
      "LiquidityAccountIDs: 275, 317",
      "HedgeServerIDs: 8, 25"
    ],
    "skipped_phases": ["Phase 10 (Atlassian search)"]
  }
}
</JUDGE_VERDICT>
