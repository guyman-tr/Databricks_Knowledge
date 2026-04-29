## Adversarial Judge Review: Dealing_dbo.Dealing_HedgeCost

### Dimension 1 — Tier Accuracy: **3/10**

Sampled 5 columns:

| Column | Lineage Transform | Wiki Tier | Expected Tier | Match? |
|--------|------------------|-----------|---------------|--------|
| Name | Passthrough from Dim_Instrument.Name (dim-lookup, upstream wiki exists) | Tier 2 | Tier 1 — Dim_Instrument | NO |
| IsSettled | ETL-computed CASE on HedgeServerID | Tier 5 | Tier 2 — SP_HedgeCost | NO |
| HC | Complex ETL formula | Tier 2 | Tier 2 | YES |
| FullCommission | SUM(RealizedCommission) aggregation | Tier 2 | Tier 2 | YES |
| HedgeServerID | Passthrough/GROUP BY key from Dim_Position (upstream wiki exists) | Tier 2 | Tier 1 — Dim_Position | NO |

3 mismatches out of 5 → base score 3. IsSettled also has a **factual error** in its description: the wiki says "1 = real asset, 0 = CFD asset" but the SP produces varchar values `'Real'` and `'CFD'`, as the lineage file itself notes ("String (not int)").

---

### Dimension 2 — Upstream Fidelity: **3/10**

The wiki declares **zero** Tier 1 columns. The bundle includes upstream wikis for Dim_Instrument, Dim_Position, BI_DB_VarCommission, Dealing_DailyZeroPnL_Stocks, and Fact_CurrencyPriceWithSplit. Multiple passthrough/rename columns should have been Tier 1 with verbatim upstream quotes:

**Missed inheritances:**
1. **Name** — dim-lookup passthrough from `Dim_Instrument.Name`. Upstream wiki (element #4) describes it. Wiki paraphrases instead.
2. **HedgeServerID** — passthrough from `Dim_Position.HedgeServerID`. Upstream wiki (element #80): "FK to Trade.HedgeServer. Hedge server managing this position." Wiki rewrites it entirely.
3. **VariableSpread** — rename of `BI_DB_VarCommission.VarCommission`. Upstream wiki (element #8): "Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings." Wiki paraphrases as "variable component of spread revenue."

Score: "Wrong tier origin" → 3.

### T1 Fidelity Table

No columns were tagged Tier 1 by the writer, so the wiki-side fidelity table is technically empty. The following columns **should** have been Tier 1 but were not:

| Column | Upstream Source | Upstream Description (verbatim) | Wiki Description | Match | Loss |
|--------|---------------|--------------------------------|-----------------|-------|------|
| Name | Dim_Instrument #4 | "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name... This is the internal instrument name, not necessarily the display name..." | "Instrument name from DWH_dbo.Dim_Instrument.Name (internal name, e.g., 'COP.US/USD')..." | NO | Entire upstream description dropped; replaced with paraphrase. Detail about display name partially preserved but reworded. |
| HedgeServerID | Dim_Position #80 | "FK to Trade.HedgeServer. Hedge server managing this position." | "The HedgeServer that managed these positions. IDs {9, 102, 112, 125, 126} are classified as 'Real'..." | NO | Upstream FK reference dropped; description rewritten with added business logic that belongs in Section 2, not the element description. |
| VariableSpread | BI_DB_VarCommission #8 | "Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings." | "Variable spread commission from BI_DB_dbo.BI_DB_VarCommission... Represents the variable component of spread revenue." | NO | Formula dropped, "openings and closings" detail dropped, paraphrased. |

---

### Dimension 3 — Completeness: **4/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | NO — only 7 sections; no Section 8 (Sample Queries) |
| Element count matches DDL (15) | YES — 15/15 |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | NO — missing UC Target |
| Section 5.2 ETL pipeline ASCII diagram | NO — no pipeline diagram in expected location |
| Footer has tier breakdown counts | NO |
| Section 1 has row count and date range | NO |
| Dictionary columns ≤15 values list key=value | NO — IsSettled has 2 values, not listed as key=value |
| .review-needed.md does NOT contain ## 4. Elements | YES |

4 out of 10 → Score 4.

---

### Dimension 4 — Business Meaning: **7/10**

Section 1 is solid: names the domain (hedge execution cost), specifies scope (USD Stocks/ETFs only, InstrumentTypeID 5/6), explains the HC metric, identifies the ETL SP, and names the SP author. The row grain (instrument × HedgeServer × IsSettled × Date) is described. Missing: row count and date range. Otherwise specific and actionable for an analyst.

---

### Dimension 5 — Data Evidence: **5/10**

The Quality Score section claims "Live Data: 5/5, Sample up to 2026-03-10" — so live data was apparently consulted. However:
- No row count in Section 1
- No date range in Section 1
- No formal Phase Gate Checklist with `[x]` marks
- HedgeServerID enum values are listed (good)
- IsSettled values mentioned but described incorrectly (bad)
- No NULL-rate distribution analysis

---

### Dimension 6 — Shape Fidelity: **5/10**

- 7 sections instead of 8 (no sample queries section)
- Tier legend present in Section 4 but uses Tier 5 in a column without listing Tier 5 in the legend
- No SQL samples anywhere
- Footer format differs from golden reference (no tier breakdown counts, no phases-completed list)
- Quality Score section present but formatted as a custom table rather than the expected format

---

### Weighted Total

```
weighted = 0.25×3 + 0.20×3 + 0.20×4 + 0.15×7 + 0.10×5 + 0.10×5
         = 0.75 + 0.60 + 0.80 + 1.05 + 0.50 + 0.50
         = 4.20
```

**Verdict: FAIL**

---

### Top 5 Issues

1. **HIGH — IsSettled description is factually wrong.** Wiki says "1 = real asset, 0 = CFD asset" but the SP produces `'Real'` / `'CFD'` (varchar). The lineage file's own note ("String (not int)") was ignored.

2. **HIGH — Zero Tier 1 columns despite multiple upstream wikis in the bundle.** Name (Dim_Instrument), HedgeServerID (Dim_Position), VariableSpread (BI_DB_VarCommission) are all passthrough/rename columns with available upstream wikis — all should be Tier 1 with verbatim quotes.

3. **HIGH — IsSettled tagged Tier 5 (Expert Review) when the SP code clearly shows the CASE logic.** This is a Tier 2 column — the derivation is fully visible in SP_HedgeCost.

4. **MEDIUM — Missing Section 8 (Sample Queries).** No SQL samples anywhere in the wiki. An analyst needs query examples for a complex table like this.

5. **MEDIUM — No row count or date range in Section 1.** The Quality Score section mentions "Sample up to 2026-03-10" but Section 1 — the most-read section — lacks this essential context.

---

### Regeneration Feedback

1. Fix IsSettled description: values are `'Real'` and `'CFD'` (varchar), NOT `1`/`0`. Re-tag as `(Tier 2 — SP_HedgeCost)` and document the CASE derivation from HedgeServerID.
2. Re-tag Name as `(Tier 1 — Dim_Instrument.Name)` and quote the upstream Dim_Instrument wiki element #4 verbatim.
3. Re-tag HedgeServerID as `(Tier 1 — Dim_Position.HedgeServerID)` and quote upstream Dim_Position wiki element #80 verbatim.
4. Re-tag VariableSpread as `(Tier 1 — BI_DB_VarCommission.VarCommission)` and quote upstream BI_DB_VarCommission wiki element #8 verbatim.
5. Add Section 8 with sample SQL queries (e.g., daily HC by instrument, top costly instruments, HC trend over date range).
6. Add row count and date range to Section 1.
7. Add tier breakdown counts to footer.
8. Add ETL pipeline ASCII diagram to Section 5 (or a dedicated Section 5.2).
9. Add UC Target to property table (or note "N/A — Dealing_dbo not yet in Unity Catalog").
10. Add Tier 5 to the Tier Legend in Section 4 if any column uses it (currently IsSettled — but it should be reclassified to Tier 2).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_HedgeCost",
  "weighted_score": 4.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 5,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [
    {
      "column": "Name",
      "upstream_quote": "Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 -- live data, etoro.Trade.GetInstrument)",
      "wiki_quote": "Instrument name from DWH_dbo.Dim_Instrument.Name (internal name, e.g., 'COP.US/USD'). Note: in Phase 1 DDL this is varchar(50) which may truncate long names; prefer InstrumentDisplayName from Dim_Instrument for display. (Tier 2 — SP_HedgeCost)",
      "match": "NO",
      "loss": "Not tagged Tier 1. Upstream description fully paraphrased. Forex/stock/crypto examples dropped. 'Not necessarily the display name' detail partially preserved but reworded."
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "The HedgeServer that managed these positions. IDs {9, 102, 112, 125, 126} are classified as 'Real' (settled assets); all others are 'CFD'. Key dimension for separating settled-stock hedging from CFD hedging. (Tier 2 — SP_HedgeCost)",
      "match": "NO",
      "loss": "Not tagged Tier 1. Upstream FK reference to Trade.HedgeServer dropped. Description rewritten with business logic that belongs in Section 2."
    },
    {
      "column": "VariableSpread",
      "upstream_quote": "Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings. (Tier 2 -- SP_VarCommission, computed from Dim_Position forex fields)",
      "wiki_quote": "Variable spread commission from BI_DB_dbo.BI_DB_VarCommission for this instrument×HedgeServer×IsSettled on Date. Represents the variable component of spread revenue. (Tier 2 — SP_HedgeCost)",
      "match": "NO",
      "loss": "Not tagged Tier 1. Formula 'Units * Spread * USDRate' dropped. 'Both openings and closings' detail dropped. Fully paraphrased."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "IsSettled",
      "problem": "Description says '1 = real asset, 0 = CFD asset' but the SP produces varchar values 'Real' and 'CFD' via CASE WHEN HedgeServerID IN (9,102,112,125,126) THEN 'Real' ELSE 'CFD'. The lineage file's own note ('String (not int)') was ignored. Also tagged Tier 5 when SP code is fully visible — should be Tier 2."
    },
    {
      "severity": "high",
      "column_or_section": "Name, HedgeServerID, VariableSpread",
      "problem": "Zero Tier 1 columns despite upstream wikis being available in the bundle for Dim_Instrument, Dim_Position, and BI_DB_VarCommission. These passthrough/rename columns should be Tier 1 with verbatim upstream quotes."
    },
    {
      "severity": "high",
      "column_or_section": "IsSettled",
      "problem": "Tagged Tier 5 (Expert Review) but the CASE derivation from HedgeServerID is fully visible in SP_HedgeCost code. Should be Tier 2."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 8 (missing)",
      "problem": "No Section 8 (Sample Queries) exists. No SQL samples anywhere in the wiki."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "No row count or date range in Section 1. The Quality Score section mentions '2026-03-10' but Section 1 — the primary entry point — lacks this context."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix IsSettled: values are 'Real'/'CFD' varchar, not 1/0 int; re-tag as Tier 2 with the CASE derivation. (2) Re-tag Name as Tier 1 — Dim_Instrument.Name, quote Dim_Instrument wiki element #4 verbatim. (3) Re-tag HedgeServerID as Tier 1 — Dim_Position.HedgeServerID, quote Dim_Position wiki element #80 verbatim. (4) Re-tag VariableSpread as Tier 1 — BI_DB_VarCommission.VarCommission, quote upstream element #8 verbatim. (5) Add Section 8 with sample SQL queries. (6) Add row count and date range to Section 1. (7) Add tier breakdown counts to footer. (8) Add ETL pipeline ASCII diagram. (9) Add UC Target to property table. (10) Add Tier 5 to legend or reclassify IsSettled to Tier 2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
