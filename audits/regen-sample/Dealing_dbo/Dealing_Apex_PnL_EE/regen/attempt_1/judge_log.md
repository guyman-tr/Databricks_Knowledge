## Adversarial Review: `Dealing_dbo.Dealing_Apex_PnL_EE`

### Preliminary Verification

**DDL column count:** 8 columns (Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, UpdateDate, Dividends)
**Wiki element count:** 8 elements — **Match.**

**Tier 1 columns:** 0. All upstream staging tables (`LP_APEX_EXT981_3EU`, `LP_APEX_EXT869_3EU`) have no wiki documentation. Tier 2 across the board is correct for SP-derived columns from undocumented external staging.

---

### Dimension 1 — Tier Accuracy: **10/10**

5 sampled columns:

| Column | Lineage (from SP code) | Wiki Tier | Correct? |
|--------|----------------------|-----------|----------|
| Date | `@Date` SP parameter, SET by caller | Tier 2 — SP_Apex_PnL | YES |
| Equity_Start | `LP_APEX_EXT981_3EU.TotalEquity` at `@FridayBeforeID`; scientific notation parse | Tier 2 — SP_Apex_PnL | YES |
| Transfers | `SUM(-t.Amount)` from `LP_APEX_EXT869_3EU` WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL') | Tier 2 — SP_Apex_PnL | YES |
| PnL | `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)` — pure ETL computation | Tier 2 — SP_Apex_PnL | YES |
| Dividends | `SUM(-Amount)` from `LP_APEX_EXT869_3EU` WHERE TerminalID = '$+DIV', aggregated per account | Tier 2 — SP_Apex_PnL | YES |

0 mismatches → **10**. No Tier 1 columns exist, so no paraphrasing penalty applies.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. All upstream staging tables are external Apex LP files with no wiki documentation in the bundle. This is expected and noted correctly in the review-needed sidecar ("LP external files are not part of the standard DWH upstream wiki ecosystem").

### T1 Fidelity Table

No Tier 1 columns — table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES — Sections 1–8 all present |
| Element count = DDL column count (8) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES — `0 T1, 8 T2, 0 T3, 0 T4` |
| Section 1 has row count + date range | YES — 5,130 rows, 2021-02-10 to 2024-06-07 |
| Dictionary columns ≤15 values list inline key=value pairs | **NO** — AccountNumber (6 values) lists account numbers in Section 1 but not inline in the Element #2 description |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

9/10 → **8**

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names: the exact domain (WTD equity-level PnL for Apex Clearing LP), the row grain (Date + AccountNumber), the writer SP (SP_Apex_PnL), refresh pattern (stale since 2024-06-08, historically weekly Saturday WTD), scale (5,130 rows), date range (2021-02-10 to 2024-06-07), all 6 account numbers, and a clear staleness warning. A new analyst would immediately know what this table is for and that it's frozen.

One minor gap: doesn't mention the DELETE+INSERT idempotent pattern in Section 1 itself (it's in the Writer SP paragraph, which is fine). Overall very actionable.

### Dimension 5 — Data Evidence: **6/10**

Strong data claims present:
- Row count (5,130) and date range in Section 1
- NULL rates per column (57% Transfers, 54% Dividends, 14% Equity_End, 4% Equity_Start)
- 6 specific account numbers listed
- Last ETL update timestamp (2024-06-08 09:19)

However: **No Phase Gate Checklist** section exists anywhere in the wiki. The footer lists sub-scores (`Elements: 8/10, Logic: 8/10, ...`) but no P2/P3 phase completion markers. Without explicit phase marking, I cannot confirm these data claims were derived from live queries vs. fabricated from SP logic analysis. The specificity of NULL rates (14%, 54%, 57%) suggests live data was used, but this is unverifiable from the wiki alone.

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES
- Real SQL in Section 7: YES (3 practical queries)
- Footer with quality score: YES
- Footer phases-completed list: **Missing** — no `Phases: P1 [x] P2 [x] P3 [x]` line

Minor deviation only: missing phase gate line in footer.

---

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*6 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.25
```

**Verdict: PASS** (8.25 ≥ 7.5)

---

### Top 5 Issues

1. **(low) AccountNumber — missing inline values in Element description.** Element #2 says "6 distinct accounts in the dataset" but does not list them. Section 1 has them, but the Elements table should be self-contained for quick reference.

2. **(low) No Phase Gate Checklist.** The wiki lacks a P2/P3 phase gate section confirming live data was queried. Data claims are plausible but unverifiable from the document alone.

3. **(low) Section 2.3 Account→HS mapping is tangential.** The #AccountToHS mapping (3EU05026→HS9, etc.) is used only by #Zero which feeds the per-symbol sibling tables, NOT this equity-level table. Including it in Section 2 is contextually useful but slightly misleading about this table's own logic.

4. **(low) Footer missing phases-completed line.** The golden shape includes a phases-completed list; the footer has tier counts and sub-scores but no phase markers.

5. **(low) 3EU05000 account not in #AccountToHS.** The wiki lists 6 accounts including 3EU05000, but the SP's hedge-server mapping only has 5. The wiki doesn't explain that 3EU05000 has no HS mapping — this is a minor data-level detail but worth noting for completeness.

---

### Regeneration Feedback

1. Add the 6 account number values inline in Element #2's description (e.g., `(3EU05025, 3EU05027, 3EU00101, 3EU05028, 3EU05026, 3EU05000)`).
2. Add a Phase Gate Checklist section (or footer line) confirming P2/P3 data verification was performed.
3. Clarify in Section 2.3 that the Account→HS mapping applies to sibling per-symbol tables, not to `Dealing_Apex_PnL_EE` directly.
4. Add a phases-completed line to the footer (e.g., `Phases: P1 [x] P2 [x] P3 [x]`).

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_EE",
  "weighted_score": 8.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "AccountNumber (Element #2)",
      "problem": "Element description says '6 distinct accounts' but does not list them inline. Values are in Section 1 but Elements table should be self-contained."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No Phase Gate Checklist section or footer line confirming P2/P3 live data verification was performed. Data claims (NULL rates, row counts) are plausible but unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.3",
      "problem": "Account-to-HedgeServer mapping (3EU05026→HS9, etc.) is used only by #Zero for per-symbol sibling tables, not by this equity-level table. Inclusion is contextually useful but slightly misleading about this table's own ETL."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Missing phases-completed line in footer (golden shape expects 'Phases: P1 [x] P2 [x] P3 [x]')."
    },
    {
      "severity": "low",
      "column_or_section": "AccountNumber (Section 1)",
      "problem": "Wiki lists 3EU05000 as one of 6 accounts but SP's #AccountToHS mapping only has 5 (no HS for 3EU05000). Wiki does not explain this gap."
    }
  ],
  "regeneration_feedback": "Minor polish only (PASS): (1) List 6 account numbers inline in Element #2 description. (2) Add Phase Gate Checklist or footer phases-completed line. (3) Clarify Section 2.3 that Account→HS mapping is for sibling per-symbol tables, not this EE table. (4) Note that 3EU05000 has no hedge-server mapping in the SP.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 5,130 in Section 1",
      "NULL rates: 57% Transfers, 54% Dividends, 14% Equity_End, 4% Equity_Start in Element descriptions",
      "6 distinct AccountNumber values in Section 1",
      "Last ETL update 2024-06-08 09:19 in Section 1"
    ],
    "skipped_phases": [
      "No Phase Gate Checklist section present in wiki"
    ]
  }
}
</JUDGE_VERDICT>
