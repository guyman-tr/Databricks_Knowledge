## Judge Review: BI_DB_dbo.BI_DB_QSR_Balance_New

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (CID, Regulation, IsZeroBalance, RealizedPnL, StockMargin). All tier assignments correct. The 4 Tier 1 columns (Regulation, PlayerStatus, Country, MifidCategory) are properly traced through dim-lookup passthroughs to their Dictionary origins rather than being tagged as Tier 2 via the SP or intermediate dim table.

**Dimension 2 — Upstream Fidelity: 9/10**
All 4 Tier 1 columns preserve the upstream wiki text verbatim, with minor additions (value lists, lineage context) that add information without losing any. No vendor names dropped, no NULL semantics removed, no paraphrasing of core descriptions.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 35/35 elements match DDL. All element rows have 5 cells with tier tags. Property table complete. ETL pipeline diagram uses real names. Footer has tier breakdown. Section 1 has row count (~127M) and date range (Q1-2020 to Q4-2023). Dictionary columns list inline values. Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the CySEC QSR domain, per-customer row grain, SP_Q_QSR_New ETL, DELETE+INSERT quarterly refresh, dual-currency duplication rationale, sustainability ratio logic, and two known inaccuracies from the SP header. An analyst reading this would know exactly when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (~127M total, ~10.9M per quarter) and date range (Q1-2020 through Q4-2023) are present. Enum values listed for Regulation (12), PlayerStatus (9), MifidCategory (6), ReportCurrency (2). However, no explicit Phase Gate Checklist with P2/P3 checkboxes is shown, and the data claims lack explicit NULL-rate or distribution analysis citations.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed list. Minor deviation: no explicit Phase Gate Checklist section.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. 12 distinct values in QSR data: CySEC, FCA, BVI, ASIC & GAML, FinCEN+FINRA, FinCEN, ASIC, FSA Seychelles, eToroUS, FSRA, NFA, None." | MINOR | Added QSR-specific value list — no loss |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. 9 values observed: Normal, Blocked, Block Deposit & Trading, Pending Verification, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning, Copy Block." | MINOR | Added observed values — no loss |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID." | MINOR | Added lineage context — no loss |
| MifidCategory | "Human-readable classification label. Used in compliance dashboards and regulatory reports." | "Human-readable classification label. Used in compliance dashboards and regulatory reports. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending." | MINOR | Added lineage and values — no loss |

### Top 5 Issues

1. **severity: low | Section 1** — Data freshness claim ("Q1-2020 through Q4-2023") may be stale if SP has been run for more recent quarters. The review-needed sidecar flags this uncertainty but Section 1 states it as fact.

2. **severity: low | StockMargin (#35)** — Description says "Added 2025-10-23 (Markos Ch). NULL for quarters before implementation." The review-needed sidecar notes uncertainty about whether StockMargin is actually populated in the balance table vs only the volume table. The SP code shows StockMargin flows through `#pnlCIDFinal` from `#RealizedPnLCIDLevel`, which only captures closed positions — for customers with no closed positions in a quarter, StockMargin would be NULL from the LEFT JOIN regardless.

3. **severity: low | CID (#4)** — Tagged "Tier 2 — Fact_SnapshotEquity" but the SP code shows CID comes from `#relevantCIDs` which is derived from `#LiabilitiesCBusersEndDate` which gets CID from `#vliabiltyprep` (V_Liabilities). The tier source attribution should be "V_Liabilities" or "multi-source" rather than specifically Fact_SnapshotEquity.

4. **severity: low | Section 8** — "No Atlassian sources searched" is acknowledged as a harness limitation but means potential Confluence context is missing.

5. **severity: low | LiabilitiesStocksSustainable (#18)** — The INSERT mapping in the SP shows `LiabilitiesTotalStockSustainable` maps to the column `LiabilitiesStocksSustainable`, while the wiki description correctly describes the computation. Minor naming confusion between the temp table column name and the target column name.

### Regeneration Feedback

No regeneration needed — this wiki passes with a strong score. If iterating:
1. Clarify CID source attribution (V_Liabilities, not specifically Fact_SnapshotEquity).
2. Add a note to StockMargin that it may be NULL for customers with no closed positions in the quarter (LEFT JOIN from #RealizedPnLCIDLevel).
3. Qualify the data freshness claim in Section 1 with "as of last known run" or similar hedge.

### Weighted Score

```
weighted = 0.25*10 + 0.20*9 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 2.50 + 1.80 + 2.00 + 1.35 + 0.70 + 0.90
         = 9.25
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_QSR_Balance_New",
  "weighted_score": 9.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. 12 distinct values in QSR data: CySEC, FCA, BVI, ASIC & GAML, FinCEN+FINRA, FinCEN, ASIC, FSA Seychelles, eToroUS, FSRA, NFA, None.",
      "match": "MINOR",
      "loss": "Added QSR-specific value list — no semantic loss"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. 9 values observed: Normal, Blocked, Block Deposit & Trading, Pending Verification, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning, Copy Block.",
      "match": "MINOR",
      "loss": "Added observed values — no semantic loss"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID.",
      "match": "MINOR",
      "loss": "Added lineage context — no semantic loss"
    },
    {
      "column": "MifidCategory",
      "upstream_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports.",
      "wiki_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending.",
      "match": "MINOR",
      "loss": "Added lineage and inline values — no semantic loss"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Data freshness claim ('Q1-2020 through Q4-2023, ~127M rows') stated as fact but review-needed sidecar flags uncertainty about whether more recent quarters have been loaded."
    },
    {
      "severity": "low",
      "column_or_section": "StockMargin",
      "problem": "Description does not clarify that StockMargin may be NULL for customers with no closed positions in the quarter due to LEFT JOIN from #RealizedPnLCIDLevel. Review-needed sidecar also flags uncertainty about whether the column is actually populated in the balance table."
    },
    {
      "severity": "low",
      "column_or_section": "CID",
      "problem": "Tagged 'Tier 2 — Fact_SnapshotEquity' but SP code shows CID flows from V_Liabilities (which wraps Fact_SnapshotEquity). Source attribution should be V_Liabilities for accuracy."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "No Atlassian sources searched — acknowledged harness limitation but potential Confluence context missing."
    },
    {
      "severity": "low",
      "column_or_section": "LiabilitiesStocksSustainable",
      "problem": "SP INSERT maps temp table column 'LiabilitiesTotalStockSustainable' to target column 'LiabilitiesStocksSustainable' — naming asymmetry not explicitly called out in wiki."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Minor improvements if iterating: (1) Clarify CID source as V_Liabilities rather than Fact_SnapshotEquity. (2) Note StockMargin NULL behavior for customers with no closed positions. (3) Qualify data freshness claim in Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
