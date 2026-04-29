## Human-Readable Summary

### Per-Dimension Scores

**D1 — Tier Accuracy: 7/10**
Sampled 5 columns: `EOM_Club` (✓ Tier 1), `Revenue_Total` (✓ Tier 2), `FirstAction` (✗ should be Tier 1), `EOM_IsFunded` (✓ Tier 2), `Region` (✓ Tier 2). One mismatch on `FirstAction`: the writer tagged it Tier 2 but `BI_DB_First5Actions.FirstActionTypeNew` is fully documented in the bundle — a passthrough rename must be Tier 1. `FirstCross` has the identical problem (also found outside the sample). No paraphrasing penalty on the one correctly tagged Tier 1 column.

**D2 — Upstream Fidelity: 5/10**
Only one Tier 1 column declared (`EOM_Club`). Its description is a near-verbatim copy of the MonthlyPanel wiki with a hyphen/em-dash difference → MINOR. However the writer missed two required Tier 1 inheritances: `FirstAction` (rename of `FirstActionTypeNew`) and `FirstCross` (rename of `FirstCrossNew`), both fully documented in the in-bundle `BI_DB_First5Actions` wiki. Each missed inheritance costs −2: 9 (base) − 2 − 2 = 5.

**D3 — Completeness: 10/10**
All 8 sections present. DDL has 34 columns; wiki documents 34 elements. Every row has 5 cells and ends with a tier tag. Property table is complete. Section 5.2 has a real-name ASCII pipeline. Footer has tier breakdown and quality score. Section 1 has row count and date range. Dictionary columns (`Indicator` = 6 values, `Region` = 4 values, `EOM_Club` = 7 values) all enumerated inline. Review-needed sidecar has no `## 4. Elements` section.

**D4 — Business Meaning: 10/10**
Section 1 is exemplary: names domain (CorpDev dashboard), specifies row grain (pre-aggregated monthly KPIs per region × club), names ETL SP (SP_CorpDevDashboard), gives row count, date range, refresh pattern, dormancy note, and a full indicator cross-reference table. A new analyst can immediately orient themselves.

**D5 — Data Evidence: 7/10**
Row count (7,461) and date range (2012-10 to 2023-10) are present and specific. Indicator enumeration is grounded in SP code. However the Phase Gate Checklist is not shown in the wiki, so P2+P3 completion cannot be verified. The footer says 11/14 phases completed — 3 were skipped — without naming which. Giving benefit of the doubt given the specificity of claims, but not a full 10.

**D6 — Shape Fidelity: 9/10**
Near-perfect structure: all sections, tier legend, real SQL samples in Section 7, correct footer format. Minor deduction: the Phase Gate Checklist section (typical in this format) is absent.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|-----------|-------|------|
| EOM_Club | "eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki)" | "eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000-Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Passthrough from BI_DB_CID_MonthlyPanel_FullData. NULL for FA, Regs, AUA, Soc indicator rows. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki)" | MINOR | Hyphen vs em-dash; extra context added; meaning preserved |
| FirstAction | "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. (Tier 2 — SP_First5Actions)" — BI_DB_First5Actions wiki | "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy', 'Copy Fund'. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstActionTypeNew. (Tier 2 — SP_First5Actions via BI_DB_First5Actions)" | NO | Tier wrong (Tier 2 instead of Tier 1); upstream wiki available in bundle; description should be verbatim from BI_DB_First5Actions wiki |
| FirstCross | "Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses." — BI_DB_First5Actions wiki (col FirstCrossNew) | "Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstCrossNew. (Tier 2 — SP_First5Actions via BI_DB_First5Actions)" | NO | Tier wrong (Tier 2 instead of Tier 1); upstream wiki available; "Preferred over FirstCross for new analyses" note dropped |

---

### Top 5 Issues

1. **[HIGH] `FirstAction` — wrong tier.** Tagged `Tier 2 — SP_First5Actions via BI_DB_First5Actions`. The `BI_DB_First5Actions` wiki is present in the bundle; `FirstActionTypeNew` is fully documented there. A passthrough rename from a documented upstream must be Tier 1. Correct tag: `(Tier 1 — BI_DB_dbo.BI_DB_First5Actions wiki)` with description verbatim from that wiki.

2. **[HIGH] `FirstCross` — wrong tier.** Same pattern as `FirstAction`. Renamed from `BI_DB_First5Actions.FirstCrossNew`, which is documented in the bundle wiki. Should be `Tier 1 — BI_DB_dbo.BI_DB_First5Actions wiki`.

3. **[MEDIUM] Age UNION in SP_CorpDevDashboard has no Active_Month date filter.** All other UNIONs (All, FA, Regs, Soc) filter to `@SdateINT`. The Age UNION scans all 353.8M MonthlyPanel rows where `IsFunded_New=1` without a date predicate. On every SP run, Age rows for ALL historical months are written to `#tmp`, then only the current month is deleted from the target table before INSERT. Over multiple runs, this would produce duplicate Age rows for historical months. Neither the wiki's Section 2.6 (Age Calculation) nor the review-needed sidecar flags this. This is a real data integrity concern that should be in the review-needed sidecar at minimum.

4. **[MEDIUM] Phase Gate Checklist absent.** The wiki footer claims "Phases: 11/14" but doesn't show the `[ ]` / `[x]` checklist. Three phases were skipped without identification. If any of the 3 skipped phases include P2 (live row-count query) or P3 (distribution analysis), data claims (7,461 rows, date range, indicator counts) are unverified.

5. **[LOW] Section 8 / Atlassian skip is documented but the table could have Confluence entries.** `SP_CorpDevDashboard` was written by Amir Gurewitz in 2021 — a named author on a CorpDev-facing table is exactly the kind of object that would have Confluence documentation. The wiki acknowledges Phase 10 was skipped but doesn't flag this as a gap worth pursuing.

---

### Regeneration Feedback

1. **Re-tag `FirstAction`** as `(Tier 1 — BI_DB_dbo.BI_DB_First5Actions wiki)` and replace the description with the verbatim text for `FirstActionTypeNew` from the First5Actions wiki: *"First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy."* Add the indicator-scope note as a supplement after the tier tag.
2. **Re-tag `FirstCross`** as `(Tier 1 — BI_DB_dbo.BI_DB_First5Actions wiki)` using the verbatim description for `FirstCrossNew`: *"Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses."*
3. **Add a note in review-needed.md** about the missing `Active_Month = @SdateINT` filter in the Age UNION branch of `SP_CorpDevDashboard`. Confirm whether this is an intentional full-refresh or a latent SP bug causing duplicate historical Age rows.
4. **Add the Phase Gate Checklist** (P1–P14 with `[x]`/`[ ]`) to Section 5 or footer, or explicitly name which 3 phases were skipped and why.
5. Update the tier breakdown in the footer from "1 T1, 33 T2" to "3 T1, 31 T2" once FirstAction and FirstCross are corrected.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CorpDevDashboard",
  "weighted_score": 7.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "EOM_Club",
      "upstream_quote": "eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000\u2013Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. (Tier 1 \u2014 DWH_dbo.Dim_PlayerLevel wiki)",
      "wiki_quote": "eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000-Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Passthrough from BI_DB_CID_MonthlyPanel_FullData. NULL for FA, Regs, AUA, Soc indicator rows. (Tier 1 \u2014 DWH_dbo.Dim_PlayerLevel wiki)",
      "match": "MINOR",
      "loss": "Hyphen vs em-dash; extra context appended; semantic meaning preserved"
    },
    {
      "column": "FirstAction",
      "upstream_quote": "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. (Tier 2 \u2014 SP_First5Actions) [BI_DB_First5Actions wiki, col FirstActionTypeNew]",
      "wiki_quote": "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy', 'Copy Fund'. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstActionTypeNew. (Tier 2 \u2014 SP_First5Actions via BI_DB_First5Actions)",
      "match": "NO",
      "loss": "Tier wrong: marked Tier 2, must be Tier 1. BI_DB_First5Actions wiki is present in bundle and documents FirstActionTypeNew. Passthrough rename requires Tier 1 with upstream wiki origin."
    },
    {
      "column": "FirstCross",
      "upstream_quote": "Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses. (Tier 2 \u2014 SP_First5Actions) [BI_DB_First5Actions wiki, col FirstCrossNew]",
      "wiki_quote": "Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstCrossNew. (Tier 2 \u2014 SP_First5Actions via BI_DB_First5Actions)",
      "match": "NO",
      "loss": "Tier wrong: marked Tier 2, must be Tier 1. BI_DB_First5Actions wiki is present in bundle. 'Preferred over FirstCross for new analyses' note dropped."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "FirstAction",
      "problem": "Tagged (Tier 2 \u2014 SP_First5Actions via BI_DB_First5Actions) but BI_DB_First5Actions wiki is available in the bundle and documents FirstActionTypeNew. A passthrough rename with an available upstream wiki must be Tier 1. Should be (Tier 1 \u2014 BI_DB_dbo.BI_DB_First5Actions wiki) with the FirstActionTypeNew description copied verbatim."
    },
    {
      "severity": "high",
      "column_or_section": "FirstCross",
      "problem": "Same problem as FirstAction. Tagged Tier 2 but is a passthrough rename of FirstCrossNew from BI_DB_First5Actions, which is documented in the bundle. Must be Tier 1. 'Preferred over FirstCross for new analyses' note also dropped from the description."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2.6 / review-needed",
      "problem": "The Age UNION in SP_CorpDevDashboard lacks an Active_Month = @SdateINT filter (present in all other 5 UNION branches). Every SP run scans all 353.8M MonthlyPanel rows where IsFunded_New=1 and inserts Age rows for ALL historical months into #tmp. Since only the current month is deleted before INSERT, re-runs accumulate duplicate Age rows for historical months. Neither Section 2.6 nor the review-needed sidecar flags this potential SP bug."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer states 'Phases: 11/14' but no Phase Gate Checklist is shown in the wiki and the 3 skipped phases are unnamed. If P2 (live row-count) or P3 (distribution analysis) were among the skipped phases, the row count and date range claims in Section 1 are unverified."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Atlassian",
      "problem": "SP_CorpDevDashboard was authored by a named individual (Amir Gurewitz, 2021) for a CorpDev-facing dashboard \u2014 a strong candidate for Confluence documentation. Phase 10 (Atlassian search) was skipped without investigation. The review-needed sidecar does not flag this gap."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag FirstAction as (Tier 1 \u2014 BI_DB_dbo.BI_DB_First5Actions wiki) and replace description with verbatim text from that wiki for FirstActionTypeNew. (2) Re-tag FirstCross as (Tier 1 \u2014 BI_DB_dbo.BI_DB_First5Actions wiki) using verbatim text for FirstCrossNew, including the 'Preferred over FirstCross for new analyses' note. (3) Add a review-needed item flagging the missing Active_Month filter in the Age UNION of SP_CorpDevDashboard. (4) Add a Phase Gate Checklist to the wiki or explicitly name the 3 skipped phases. (5) Update footer tier breakdown from '1 T1, 33 T2' to '3 T1, 31 T2'.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["7,461 rows (Section 1)", "Date range 2012-10 to 2023-10 (Section 1)", "Last refresh 2023-10-08 (Section 1 and property table)"],
    "skipped_phases": ["Phase 10 (Atlassian, documented in Section 8)", "2 additional unnamed phases (footer: 11/14 completed)"]
  }
}
</JUDGE_VERDICT>
