## Adversarial Review: Dealing_dbo.Dealing_Execution_Slippage

This is a well-constructed wiki with strong business context, but it has a critical tier-assignment and fidelity problem on its single Tier 1 column.

---

### Dimension 1 — Tier Accuracy: **5/10**

**5 columns sampled**: Date (#1), InstrumentID (#2), Slippage (#12), HedgingMode (#16), BidSpreaded (#19).

| Column | Wiki Tier | Correct Tier | Verdict |
|--------|-----------|-------------|---------|
| Date | Tier 2 — SP | Tier 2 (SP @Date param) | OK |
| InstrumentID | Tier 1 — Trade.Instrument | **Tier 2** — from `Dealing_staging.Etoro_Hedge_ExecutionLog` (unresolved) | **MISMATCH** |
| Slippage | Tier 2 — SP | Tier 2 (computed) | OK |
| HedgingMode | Tier 2 — SP | Tier 2 (CASE logic in SP) | OK |
| BidSpreaded | Tier 2 — SP | Tier 2 (from unresolved CopyFromLake) | OK |

1 mismatch → base score 7. **InstrumentID** is sourced from `Etoro_Hedge_ExecutionLog` (line: `SELECT ... InstrumentID ... FROM Dealing_staging.Etoro_Hedge_ExecutionLog er`). The SP joins to `Dim_Instrument` only for `InstrumentType`, `BuyCurrencyID`, `SellCurrencyID` — it does NOT source `InstrumentID` from Dim_Instrument. Tagging it Tier 1 — Trade.Instrument is a provenance error. The review-needed sidecar even flags this uncertainty, yet the writer chose Tier 1 anyway.

Additionally, the InstrumentID description is paraphrased, not verbatim. Upstream (Trade.Instrument via Dim_Instrument wiki): *"Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated."* Wiki says: *"Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument. 75 distinct instruments in recent data."* — completely rewritten. Deduct 2 for paraphrasing.

**Score: 7 − 2 = 5.**

---

### Dimension 2 — Upstream Fidelity: **3/10**

Only 1 column tagged Tier 1 (InstrumentID). It fails on both fidelity and tier origin.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | "Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument. 75 distinct instruments in recent data (Sep–Oct 2024)." | **NO** | Dropped "tradeable instrument pair" domain term, dropped allocation mechanism (Trade.InstrumentAdd), dropped range (0 to ~21M), dropped FK references (Dim_Currency, Dim_HistorySplitRatio). Entire description rewritten. |

Furthermore, the tier origin is wrong: the column comes from `Etoro_Hedge_ExecutionLog`, not from `Trade.Instrument` or `Dim_Instrument`. This is a relay-instead-of-root error in reverse — the writer attributed to a root that isn't even the actual source.

**Score: 3** (wrong tier origin + fully paraphrased).

---

### Dimension 3 — Completeness: **10/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | Yes |
| Element count = DDL column count (21/21) | Yes |
| Every element row has 5 cells | Yes |
| Every description ends with (Tier N — source) | Yes |
| Property table has Production Source, Refresh, Distribution, UC Target | Yes |
| Section 5.2 has ETL pipeline ASCII diagram with real names | Yes |
| Footer has tier breakdown counts | Yes |
| Section 1 has row count (4.78M) and date range (2023-01-01 to 2024-10-03) | Yes |
| Dictionary columns with ≤15 values list inline pairs (HedgingMode: CBH/HBC, IsBuy: 0/1) | Yes |
| .review-needed.md does NOT contain `## 4. Elements` | Yes |

**Score: 10.**

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (execution slippage), the exact row grain (execution group by 11 columns), the ETL SP, the refresh pattern (daily delete+insert), row count (4.78M), date range, pipeline staleness with root cause, the redirect to RequestTime variant, and the slippage sign convention. A new analyst reading this knows exactly when and why to query this table.

**Score: 9.**

---

### Dimension 5 — Data Evidence: **7/10**

Rich data claims throughout: 4.78M rows, 7,500+ instruments, 75 instruments in Sep-Oct 2024, ~92% sells, ~2 transactions per group, Oct 3 partial day with 52 rows, HBC disappearing after 2023-12-19. These are specific enough to indicate live data was queried. However, there is no explicit Phase Gate Checklist section with P2/P3 checkboxes — the footer says "Phases: 12/14" but doesn't identify which were skipped.

**Score: 7.**

---

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1–8, tier legend in Section 4, real SQL samples in Section 7, footer with quality score and phases-completed list. Minor deviation: no explicit Phase Gate Checklist table (just the footer summary).

**Score: 9.**

---

### Weighted Total

```
weighted = 0.25×5 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 1.25  + 0.60  + 2.00   + 1.35  + 0.70  + 0.90
         = 6.80
```

**Verdict: FAIL** (6.80 < 7.5)

---

### Top 5 Issues

1. **HIGH — InstrumentID wrong tier origin**: Tagged `(Tier 1 — Trade.Instrument)` but sourced from `Dealing_staging.Etoro_Hedge_ExecutionLog` in the SP. Should be Tier 2.
2. **HIGH — InstrumentID paraphrased**: Even if Tier 1 were correct, the description bears no resemblance to the upstream text. "Tradeable instrument pair", allocation range, and FK references all dropped.
3. **MEDIUM — No columns inherit from resolved upstreams**: Dim_Instrument and Fact_CurrencyPriceWithSplit are used only for internal SP computation (FX rates, instrument type). No output column is a direct passthrough from these resolved wikis, making all 20 non-InstrumentID columns correctly Tier 2. The writer should have recognized InstrumentID is also Tier 2 from the unresolved ExecutionLog.
4. **LOW — Missing Phase Gate Checklist section**: Footer claims 12/14 phases but no explicit checklist identifies which phases were completed or skipped.
5. **LOW — Section 8 placeholder**: "Phase 10 skipped" is noted but Section 8 is otherwise empty — acceptable given environment constraints.

---

### Regeneration Feedback

1. Re-tag InstrumentID as `(Tier 2 — SP_Execution_Slippage, from Dealing_staging.Etoro_Hedge_ExecutionLog)`. It is NOT sourced from Trade.Instrument or Dim_Instrument in this SP — only the InstrumentType/currency columns are looked up from Dim_Instrument, and those are used internally, not passed through to the output.
2. Update InstrumentID description to reflect its actual provenance: FK to Dim_Instrument, sourced from ExecutionLog. Do not claim Tier 1 inheritance from Trade.Instrument.
3. Add an explicit Phase Gate Checklist section or subsection listing which phases (P1–P14) were completed.
4. Update footer tier counts: should be 0 T1, 21 T2 after the InstrumentID correction.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Execution_Slippage",
  "weighted_score": 6.80,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "wiki_quote": "Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument. 75 distinct instruments in recent data (Sep\u2013Oct 2024).",
      "match": "NO",
      "loss": "Entire description rewritten. Dropped 'tradeable instrument pair' domain term, dropped allocation mechanism (Trade.InstrumentAdd), dropped range (0 to ~21M IDs), dropped FK references (Dim_Currency, Dim_HistorySplitRatio). Additionally, tier origin is wrong: column comes from Dealing_staging.Etoro_Hedge_ExecutionLog, not Trade.Instrument."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "InstrumentID",
      "problem": "Tagged Tier 1 \u2014 Trade.Instrument but the SP sources InstrumentID from Dealing_staging.Etoro_Hedge_ExecutionLog (SELECT InstrumentID FROM Dealing_staging.Etoro_Hedge_ExecutionLog). Dim_Instrument is joined only for InstrumentType/BuyCurrencyID/SellCurrencyID \u2014 not to source InstrumentID. Should be Tier 2."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID",
      "problem": "Description is fully paraphrased. Upstream says 'Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated.' Wiki says 'Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument.' \u2014 no overlap."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Tier counts",
      "problem": "Footer claims '1 T1, 20 T2' but after correcting InstrumentID to Tier 2, counts should be 0 T1, 21 T2."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 12/14' but does not identify which 2 phases were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Section 8 is a placeholder ('Phase 10 skipped'). Acceptable given environment constraints but noted."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag InstrumentID as (Tier 2 \u2014 SP_Execution_Slippage, from Dealing_staging.Etoro_Hedge_ExecutionLog). The SP sources InstrumentID from ExecutionLog, not from Trade.Instrument or Dim_Instrument. (2) Rewrite InstrumentID description to reflect actual provenance: 'Financial instrument identifier from Dealing_staging.Etoro_Hedge_ExecutionLog. FK to DWH_dbo.Dim_Instrument for name/type/currency lookup.' (3) Update footer tier counts to 0 T1, 21 T2. (4) Add explicit Phase Gate Checklist subsection listing completed and skipped phases.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "InstrumentID: '75 distinct instruments in recent data (Sep\u2013Oct 2024)'",
      "IsBuy: '~92% sells in recent data'",
      "Units: 'Average ~1,035 units per group'",
      "SlippageInDollar: 'Average \u2212$0.004 per group'",
      "NumberofTransaction: 'Typically 2 per row (min=2, max=4 in recent data)'"
    ],
    "skipped_phases": [
      "Phase 10 (Atlassian MCP)",
      "2 unidentified phases (footer says 12/14)"
    ]
  }
}
</JUDGE_VERDICT>
