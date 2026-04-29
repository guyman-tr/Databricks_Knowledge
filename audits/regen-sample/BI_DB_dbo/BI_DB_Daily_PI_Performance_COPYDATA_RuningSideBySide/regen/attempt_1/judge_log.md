## Human-Readable Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|---|---|---|
| Tier Accuracy | 5 | 2 sourcing mismatches out of 5 sampled: `Country` cites `BI_DB_CopyDailyData.Country via DWH_dbo.Dim_Country` instead of root `Dictionary.Country`; `SymbolFull` adds intermediate `DWH_dbo.Dim_Instrument via` prefix that rubric forbids |
| Upstream Fidelity | 5 | `CopyEquity` description substitutes verbatim formula `ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0)` from upstream with `ISNULL(CopyAUM, 0)` — specific formula detail lost; other 4 T1 columns verbatim |
| Completeness | 6 | 8/10 checklist: missing `Refresh` and `UC Target` in property table; footer lacks tier breakdown counts |
| Business Meaning | 9 | Specific row grain, row count (56,837), date range, SP name, DELETE+INSERT pattern, PI population filter — analyst can immediately act on this |
| Data Evidence | 6 | Row count and date range present, enum values listed; no Phase Gate Checklist marking P2+P3 complete, so data claims cannot be confirmed as non-fabricated |
| Shape Fidelity | 5 | Missing Tier Legend in Section 4, no quality score in footer, no phases-completed list; recognizable structure but structural gaps |

**Weighted score: 5.90 → FAIL**

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| SymbolFull | "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API." | "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API." | YES | — |
| CopyEquity | "Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers." | "Total AUM managed by this PI through copy relationships: ISNULL(CopyAUM, 0); renamed CopyAUM → CopyEquity; wiki: knowledge/synapse/…" | NO | Verbatim formula `ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0)` replaced with intermediate column reference `ISNULL(CopyAUM, 0)` |
| NumOfCopiers | "Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers." | "Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers." | YES | — |
| Manager | "Account manager display name: FirstName + ' ' + LastName from Dim_Manager." | "Account manager display name: FirstName + ' ' + LastName from Dim_Manager." | YES | — |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | MINOR | Description verbatim; tier origin `(BI_DB_CopyDailyData.Country via DWH_dbo.Dim_Country)` should be `(Dictionary.Country)` — the root cited in BI_DB_CopyDailyData.Country's own Tier 1 tag |

---

### Top 5 Issues

1. **HIGH — CopyEquity (col 16)**: Tier 1 description replaces verbatim upstream formula. BI_DB_CopyDailyData.CopyAUM states `ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0)` from `etoroGeneral_History_GuruCopiers`. The wiki instead wrote `ISNULL(CopyAUM, 0)` — the intermediate column reference, losing the actual computation. An analyst reading the wiki cannot know what the AUM is composed of.

2. **HIGH — Country (col 21)**: Wrong Tier 1 origin. The BI_DB_CopyDailyData wiki marks `Country` as `(Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country)`. The rubric requires using the DIM's root origin: `(Tier 1 — Dictionary.Country)`. The writer relayed through the intermediate table instead.

3. **MEDIUM — SymbolFull (col 10)**: Tier 1 origin citation includes an intermediate `DWH_dbo.Dim_Instrument via Trade.InstrumentMetaData`. Per rubric, dim-lookup passthroughs must cite the dim's root origin: `(Tier 1 — Trade.InstrumentMetaData)`.

4. **MEDIUM — Property table**: `Refresh` cadence (daily DELETE+INSERT on DateINT) and `UC Target` are absent from the property block. These are required fields that let an analyst understand SLA and UC location.

5. **MEDIUM — Footer/shape gaps**: No Tier Legend in Section 4 (Elements), no quality score in footer, no tier breakdown counts (e.g., `Tiers: 5 T1, 10 T2, 6 T3`), no phases-completed list. The golden reference shape requires these.

---

### Regeneration Feedback

1. Fix `CopyEquity` description to verbatim from upstream: *"Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers."* — do NOT substitute the intermediate `ISNULL(CopyAUM, 0)` shorthand.
2. Fix `Country` tier tag to `(Tier 1 — Dictionary.Country)` — trace to root origin as defined in BI_DB_CopyDailyData.Country which is itself `Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country`.
3. Fix `SymbolFull` tier tag to `(Tier 1 — Trade.InstrumentMetaData)` — drop the intermediate `DWH_dbo.Dim_Instrument via` prefix.
4. Add `Refresh: Daily DELETE+INSERT on DateINT` and `UC Target: _Not_Migrated` to the property table.
5. Add a Tier Legend table above the Elements table in Section 4. Add tier breakdown counts and a quality score to the footer (e.g., `Tiers: 5 T1, 10 T2, 6 T3 | Quality: X.X/10 | Phases: P1,P2,P3`).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide",
  "weighted_score": 5.90,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 5,
    "completeness": 6,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [
    {
      "column": "SymbolFull",
      "upstream_quote": "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API.",
      "wiki_quote": "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CopyEquity",
      "upstream_quote": "Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers.",
      "wiki_quote": "Total AUM managed by this PI through copy relationships: ISNULL(CopyAUM, 0); renamed CopyAUM → CopyEquity; wiki: knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md.",
      "match": "NO",
      "loss": "Verbatim formula ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0) replaced with intermediate column reference ISNULL(CopyAUM, 0); constituent field breakdown (Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL) is lost"
    },
    {
      "column": "NumOfCopiers",
      "upstream_quote": "Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers.",
      "wiki_quote": "Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Manager",
      "upstream_quote": "Account manager display name: FirstName + ' ' + LastName from Dim_Manager.",
      "wiki_quote": "Account manager display name: FirstName + ' ' + LastName from Dim_Manager.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "match": "MINOR",
      "loss": "Description text is verbatim but tier origin tag is wrong: wiki says (Tier 1 — BI_DB_CopyDailyData.Country via DWH_dbo.Dim_Country) but per rubric dim-passthrough rule the root origin should be Dictionary.Country — as cited in BI_DB_CopyDailyData.Country's own Tier 1 tag"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CopyEquity",
      "problem": "Tier 1 description substitutes the verbatim upstream formula from BI_DB_CopyDailyData.CopyAUM — ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0) — with the intermediate column reference ISNULL(CopyAUM, 0). An analyst cannot derive the AUM composition (Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL) from the wiki."
    },
    {
      "severity": "high",
      "column_or_section": "Country",
      "problem": "Tier 1 origin is wrong. BI_DB_CopyDailyData.Country is itself Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country. Per rubric, dim-lookup passthroughs must use the root origin: (Tier 1 — Dictionary.Country), not the intermediate table BI_DB_CopyDailyData."
    },
    {
      "severity": "medium",
      "column_or_section": "SymbolFull",
      "problem": "Tier 1 origin citation includes the intermediate dimension: (Tier 1 — DWH_dbo.Dim_Instrument via Trade.InstrumentMetaData). Rubric requires citing the dim's root origin directly: (Tier 1 — Trade.InstrumentMetaData). The 'via Dim_X' notation is explicitly prohibited."
    },
    {
      "severity": "medium",
      "column_or_section": "Property table",
      "problem": "Missing required fields: Refresh cadence (should be: Daily DELETE+INSERT on DateINT) and UC Target (should be: _Not_Migrated). These are required property table entries per the golden reference shape."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 / Footer",
      "problem": "No Tier Legend table in the Elements section (Section 4). Footer is missing tier breakdown counts (e.g., Tiers: 5 T1, 10 T2, 6 T3), quality score, and phases-completed list. All three are required by the golden reference shape."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix CopyEquity description to verbatim from BI_DB_CopyDailyData.CopyAUM: 'Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers.' — do NOT substitute ISNULL(CopyAUM, 0). (2) Fix Country tier tag to (Tier 1 — Dictionary.Country) — root origin from BI_DB_CopyDailyData.Country entry. (3) Fix SymbolFull tier tag to (Tier 1 — Trade.InstrumentMetaData) — drop 'DWH_dbo.Dim_Instrument via' prefix. (4) Add Refresh and UC Target rows to the property table. (5) Add Tier Legend above Elements table in Section 4 and add tier breakdown counts + quality score + phases-completed list to footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3 status unknown — no Phase Gate Checklist present in wiki footer"]
  }
}
</JUDGE_VERDICT>
