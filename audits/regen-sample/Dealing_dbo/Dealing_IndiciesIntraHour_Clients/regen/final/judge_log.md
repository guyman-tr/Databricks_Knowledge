## Adversarial Review: Dealing_dbo.Dealing_IndiciesIntraHour_Clients

This is a strong wiki. The writer clearly read the SP code thoroughly and produced accurate, detailed documentation. I'll note where it falls short, but the shortcomings are minor.

---

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled:

| Column | Claimed Tier | Verified Tier | Correct? |
|--------|-------------|--------------|----------|
| InstrumentID | Tier 1 — Trade.PositionTbl | Passthrough from Dim_Position.InstrumentID (Tier 1 origin: Trade.PositionTbl) | YES |
| HedgeServerID | Tier 1 — Trade.PositionTbl | Passthrough from Dim_Position.HedgeServerID (Tier 1 origin: Trade.PositionTbl) | YES |
| VolumeBuy | Tier 2 — Dim_Position | SUM(CASE) aggregation in SP — ETL-computed | YES |
| Bid | Tier 2 — CopyFromLake.PriceLog | LAG(LastBid,1) with gap-fill — ETL transform | YES |
| Date | Tier 2 — SP_IntraHourIndexReport | CONVERT(DATE, fromMinute) — generated in SP | YES |

0 mismatches, 0 paraphrasing failures on Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **10/10**

Only 2 Tier 1 columns exist. Both preserve the upstream Dim_Position text verbatim and append additive context (filter values, NULL semantics). No semantic loss.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|-----------|-------|------|
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Filtered to three index instruments: 27 (S&P 500), 28 (DJ30), 32 (GER30)." | YES | None — upstream preserved verbatim, context appended |
| HedgeServerID | "FK to Trade.HedgeServer. Hedge server managing this position." | "FK to Trade.HedgeServer. Hedge server managing this position. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows." | YES | None — upstream preserved verbatim, context appended |

### Dimension 3 — Completeness: **10/10**

All 10 checks pass:

- [x] All 8 sections present (1–8)
- [x] Element count matches DDL (17/17)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP/table names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (~13.3M) and date range (2022-05-22 to 2026-04-26)
- [x] Dictionary columns list values: InstrumentID lists 27/28/32 with names; HedgeServerID lists 5/8/20/1776
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names the domain (intra-hour hedging), the row grain (per minute × instrument × HedgeServerID), the ETL SP, the refresh pattern (daily delete-insert), the companion table, the row count with annual growth, and the HedgeServerID history. An analyst reading this would immediately know what the table is for and when to query it.

### Dimension 5 — Data Evidence: **7/10**

Data claims are specific and plausible: ~13.3M rows, 2022-05-22 to 2026-04-26, ~8,638 rows/day, annual volumes (~907K, ~5.8M), specific HedgeServerID values (5, 8, 20, 1776). However, there is no formal Phase Gate Checklist with P2/P3 checkboxes. The footer says "Phases: 11/14" without specifying which phases completed. Data appears real but evidence provenance is not explicit.

### Dimension 6 — Shape Fidelity: **8/10**

Structure is solid: numbered sections, tier legend in Section 4, real SQL in Section 7, footer with tier breakdown and phase count. Minor deviations: no explicit quality score number in footer, no Phase Gate Checklist section with checkboxes.

---

### Top 5 Issues

1. **(low)** **Section 5.2 / Gotchas** — The SP's final INSERT joins `#OP_complete` to `#Volume` and `#Realized` on `(fromMinute, InstrumentID)` but **not** on `HedgeServerID`. Since both temp tables are grouped by HedgeServerID, this could cause volume/realized values to fan out across HedgeServerIDs. The wiki doesn't flag this potential data quality issue in Section 3.4 Gotchas.

2. **(low)** **Footer** — No explicit quality score number. The footer lists tier counts and phase count but omits a numeric quality self-assessment.

3. **(low)** **Phase Gate Checklist** — Missing as a formal section with `[x]`/`[ ]` checkboxes. The footer's "Phases: 11/14" is not a substitute.

4. **(low)** **Section 2.2, OP_Buy description** — Wiki says "priced at start-of-minute bid" but the SP uses `FirstBid` which is `LAG(LastBid,1)` — i.e., the *previous* minute's last bid. The wiki's Section 2.5 correctly explains this for Bid/Ask but Section 2.2 could be clearer that "start-of-minute" means "prior minute's closing price."

5. **(low)** **Section 8** — "No Jira or Confluence sources were searched" is honest but the section is minimal. SR-249626 and SR-257613 are mentioned but not linked or expanded.

### Regeneration Feedback

No regeneration needed. If desired for polish:

1. Add a Gotcha noting that the SP's final INSERT joins Volume/Realized to OP_complete without HedgeServerID — analysts should validate volume values per HedgeServerID.
2. Add a formal Phase Gate Checklist section with explicit checkboxes.
3. Add a numeric quality score to the footer.

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×10 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 2.00 + 2.00 + 1.50 + 0.70 + 0.80
         = 9.50
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_IndiciesIntraHour_Clients",
  "weighted_score": 9.5,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Filtered to three index instruments: 27 (S&P 500), 28 (DJ30), 32 (GER30).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 3.4 Gotchas / VolumeBuy / VolumeSell / Realized",
      "problem": "SP final INSERT joins #OP_complete to #Volume and #Realized on (fromMinute, InstrumentID) without HedgeServerID. Since both temp tables group by HedgeServerID, volumes and realized P&L may fan out across HedgeServerIDs. Not flagged in Gotchas."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit numeric quality score in footer. Only tier counts and phase count present."
    },
    {
      "severity": "low",
      "column_or_section": "Missing section",
      "problem": "No formal Phase Gate Checklist section with [x]/[ ] checkboxes. Footer says 'Phases: 11/14' without specifying which."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2 (OP_Buy / OP_Sell)",
      "problem": "Says 'priced at start-of-minute bid' but FirstBid is LAG(LastBid,1) — previous minute's last bid. Section 2.5 explains this correctly for Bid/Ask but Section 2.2 could be more precise."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Minimal content — notes Phase 10 was skipped but SR-249626 and SR-257613 are not linked or expanded."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian scan)"]
  }
}
</JUDGE_VERDICT>
