## Judge Review — Dealing_dbo.Dealing_Apex_PnL_EE

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `Date`, `AccountNumber`, `Equity_Start`, `PnL`, `Dividends`.

Tracing through `SP_Apex_PnL` INSERT into `Dealing_Apex_PnL_EE`:
- **Date** = `@Date` SP parameter → Tier 2 ✓
- **AccountNumber** = `ISNULL(ISNULL(e.AccountNumber, t.AccountNumber), d.AccountNumber)` — COALESCE across `#Equity`, `#Transfers`, `#Dividends_PerAcc` temp tables sourced from unresolved staging (`LP_APEX_EXT981_3EU`, `LP_APEX_EXT869_3EU`) → Tier 2 ✓
- **Equity_Start** = `e.Equity_Start` from `#EquityStart_ApexFiles` reading `lp.TotalEquity` from `LP_APEX_EXT981_3EU` (unresolved staging, no wiki) → Tier 2 ✓
- **PnL** = `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)` — ETL-computed → Tier 2 ✓
- **Dividends** = `SUM(Dividends)` from `#Dividends_PerAcc` aggregated from `#Dividends_ApexFiles` where `TerminalID = '$+DIV'` on `LP_APEX_EXT869_3EU` — aggregation from unresolved staging → Tier 2 ✓

0 mismatches. All 8 columns correctly tagged Tier 2 — sources are all external staging tables without resolved wikis, or SP-computed expressions.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist, and none should. The EE table reads exclusively from Apex external staging tables (`LP_APEX_EXT981_3EU` for equity, `LP_APEX_EXT869_3EU` for transfers/dividends) — none of which have resolved upstream wikis. The resolved wikis in the bundle (`Dim_Instrument`, `Dealing_DailyZeroPnL_Stocks`, etc.) feed the *symbol-level* tables (`Dealing_Apex_PnL`, `Dealing_Apex_PnL_Daily`), NOT the EE tables. No missed inheritance.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks)

| Check | Status |
|-------|--------|
| All 8 sections present | ✓ |
| Element count = DDL column count (8 = 8) | ✓ |
| Every element row has 5 cells | ✓ |
| Every description ends with `(Tier N — source)` | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target | ✓ |
| Section 5.2 ETL pipeline ASCII diagram in wiki | **✗** — defers to lineage file; no inline diagram |
| Footer has tier breakdown counts | ✓ |
| Section 1 has row count + date range | ✓ (~5,130 rows, 2021-02-10 → 2024-06-07) |
| Dictionary columns list key=value pairs | N/A (no enum columns) ✓ |
| `.review-needed.md` does NOT contain `## 4. Elements` | ✓ |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (Apex Clearing LP equity-level WTD PnL), row grain (one Apex account's total equity PnL for the week), ETL SP (`SP_Apex_PnL`), refresh pattern (weekly WTD), stale-data warning with specific dates, row count (~5,130), date range, and the business question it answers. Clear distinction from per-symbol `Dealing_Apex_PnL`. Only minor gap: doesn't name the specific staging tables inline.

### Dimension 5 — Data Evidence: **5/10**

Row count and date range are present. Stale-data timestamps appear grounded (2024-06-07 last row, 2024-06-08 09:19 last update). However:
- No Phase Gate Checklist at all
- No NULL-rate analysis for any column
- No distribution/value-frequency analysis
- No explicit confirmation of how many distinct `AccountNumber` values exist

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections ✓, tier legend in Section 4 ✓, real SQL in Section 7 ✓ (3 queries), footer with quality score and tier breakdown ✓. Minor deviations: no "phases-completed" list in footer, Section 5 is a pointer rather than containing its own ETL diagram.

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*5 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.50 + 0.80
         = 8.15
```

**Verdict: PASS**

### Top 5 Issues

1. **(medium) Section 5** — No inline ETL pipeline ASCII diagram; wiki defers entirely to lineage file. The lineage file has one, but the wiki shape spec expects it in Section 5.2.
2. **(medium) Phase Gate Checklist** — Absent. Data evidence claims (row count, date range) cannot be verified as live-queried vs fabricated without P2/P3 markers.
3. **(low) Dividends sign convention** — The SP uses `-CAST(lp.Amount)` for dividends from `LP_APEX_EXT869_3EU`, meaning source amounts are negative. The wiki doesn't explain this inversion; an analyst debugging a reconciliation gap might be confused by sign.
4. **(low) Transfers sign convention** — Wiki says "Positive = funds received at Apex; negative = funds withdrawn" but the SP computes `SUM(-t.Amount)` — the negation is not documented, which could mislead someone reading source data directly.
5. **(low) No NULL-rate analysis** — All 8 columns are nullable per DDL, but the wiki doesn't discuss expected NULL patterns (e.g., can `Equity_Start` be NULL if equity start file is missing for a date? What happens with FULL OUTER JOIN NULLs?).

### Regeneration Feedback

1. Add an inline ETL pipeline ASCII diagram in Section 5.2 showing: `LP_APEX_EXT981_3EU (equity) + LP_APEX_EXT869_3EU (transfers/dividends) → SP_Apex_PnL → #Equity + #Transfers + #Dividends_PerAcc → FULL OUTER JOIN → Dealing_Apex_PnL_EE`.
2. Add a Phase Gate Checklist section documenting which phases (P1/P2/P3) were completed.
3. Document the sign inversion for `Dividends` (`-CAST(lp.Amount)` in SP) and `Transfers` (`SUM(-t.Amount)`) so analysts understand the transformation from source to stored value.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_EE",
  "weighted_score": 8.15,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No inline ETL pipeline ASCII diagram in the wiki; defers entirely to lineage.md. Shape spec expects a Section 5.2 diagram with real object names."
    },
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist",
      "problem": "No Phase Gate Checklist present. Data evidence claims (row count ~5,130, date range 2021-02-10 to 2024-06-07) cannot be verified as live-queried without P2/P3 markers."
    },
    {
      "severity": "low",
      "column_or_section": "Dividends",
      "problem": "SP uses -CAST(lp.Amount) to invert sign from LP_APEX_EXT869_3EU. Wiki doesn't document this inversion, which could confuse analysts comparing wiki to raw staging data."
    },
    {
      "severity": "low",
      "column_or_section": "Transfers",
      "problem": "SP computes SUM(-t.Amount) for transfers. Wiki states sign convention (positive = received) but doesn't document the negation transform from source, risking confusion during debugging."
    },
    {
      "severity": "low",
      "column_or_section": "All columns",
      "problem": "No NULL-rate or distribution analysis for any column. All 8 columns are nullable; FULL OUTER JOIN pattern in SP can produce NULLs for Equity_Start, Transfers, or Dividends when staging feeds are incomplete for a date."
    }
  ],
  "regeneration_feedback": "Not required (PASS). For improvement: (1) Add inline ETL ASCII diagram in Section 5.2 showing LP_APEX_EXT981_3EU + LP_APEX_EXT869_3EU → SP_Apex_PnL temp tables → FULL OUTER JOIN → Dealing_Apex_PnL_EE. (2) Add Phase Gate Checklist with P2/P3 completion status. (3) Document sign inversions for Dividends (-CAST(Amount)) and Transfers (SUM(-Amount)) in element descriptions.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
