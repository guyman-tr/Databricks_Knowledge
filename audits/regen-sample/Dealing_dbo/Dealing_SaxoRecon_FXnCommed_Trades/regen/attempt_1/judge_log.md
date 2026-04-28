## Adversarial Review: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: `Date`, `InstrumentID`, `SAXO-eToro_Units`, `Commission`, `HedgeServerID`. All tagged Tier 3. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable for any source." No writer SP exists. Tier 3 is the only defensible assignment for all 22 columns. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because zero upstream wikis were available in the bundle. This is the neutral-score scenario per the rubric. The writer cannot inherit what does not exist. No paraphrasing failures, no missed inheritance — there was nothing to inherit.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items pass:
- All 8 sections present (1–8)
- 22 DDL columns = 22 wiki elements (exact match)
- Every element row has 5 cells
- Every description ends with `(Tier 3 — ...)`
- Property table includes Production Source, Refresh, Distribution, UC Target
- Section 5.2 has ASCII ETL diagram with real object names
- Footer has tier breakdown counts
- Section 1 has row count (4,226) and date range (2022-01-02 to 2023-12-05)
- Dictionary-like columns list values: `Side` (Buy/Sell with counts), `HedgeServerID` (7/8/23 with counts), `InstrumentID` (15 values with examples)
- `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent. It names the exact domain (SAXO Bank FX/commodities three-way reconciliation), defines the row grain (instrument × hedge-server × side × date), names the ETL SP (and its removal), states the refresh pattern (orphaned/none), gives row count and date range, and explains the three perspectives (SAXO, eToro, Clients). An analyst would immediately know this is dormant historical recon data and should use the sibling `EODHoldings` table instead.

**Dimension 5 — Data Evidence: 8/10**
Rich and specific: row count (4,226), date range, instrument distribution with counts, HedgeServerID breakdown with percentages, Side split (Buy 1,868 / Sell 2,358), ISINCode NULL rate (1,468/4,226 = ~35%), Commission range (-559.27 to 0.00), InstrumentID 2 NULL rows. Footer says "P9, P9B skipped" — P2/P3 are not listed as skipped, consistent with real data profiling. One deduction: Commission currency is explicitly flagged as unconfirmed, which is honest but still a gap.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, three real SQL queries in Section 7 with correct bracket-quoting for special-character columns, property table, ASCII pipeline diagram, footer with quality score and phase list. Minor deviation: no explicit tier legend in a formal box format (it's there but compact). Overall shape is clean and recognizable.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns exist; upstream bundle contained zero wikis |

---

### Top 5 Issues

1. **Medium — All 22 columns are Tier 3**: Every column is grounded in DDL + data + sibling SP inference rather than confirmed SP code or upstream wiki. This is inherent to orphaned status, not a writer error, but it means every description could be wrong. The writer was transparent about this.

2. **Low — Commission currency unconfirmed** (`Commission`): The description says "likely USD given the column context" — this is a guess. The review-needed sidecar correctly flags this for human confirmation.

3. **Low — Client-side data source unconfirmed** (`Clients_Units`, `Clients_AmountUSD`): The lineage says "Client positions (inferred)" with a guess at `DWH_dbo.Dim_Position or risk matrix`. This is speculative lineage.

4. **Low — Differential formulas are inferred** (`SAXO-eToro_Units`, `SAXO-Clients_Units`, etc.): The wiki states `SAXO_Units − eToro_Units` as the formula, marked as "inferred from sibling SP pattern and data values." Reasonable inference but unconfirmed.

5. **Low — Section 8 Atlassian links are generic**: Three Confluence links are tangentially related to SAXO/recon but none is specific to this table. The writer honestly notes "No Jira ticket or Confluence page specific to Dealing_SaxoRecon_FXnCommed_Trades was found."

---

### Regeneration Feedback

No regeneration required — the wiki passes. For incremental improvement:

1. If the writer SP's removal can be confirmed via `git blame` on `SP_SAXO_Recon_FXnCommed.sql`, add the specific SR number and date to Section 1.
2. Confirm Commission currency with the Dealing team (Adar/Gili/Sarah) and upgrade from "likely USD" to confirmed.
3. If any external pipeline (ADF, Python) writes to this table outside SSDT, update the Production Source property and remove the "ORPHANED" tag.

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_SaxoRecon_FXnCommed_Trades",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "All 22 columns",
      "problem": "100% Tier 3 — every column description is inferred from DDL + data + sibling SP pattern. No writer SP code or upstream wiki available. Inherent to orphaned status but means all descriptions are unconfirmed."
    },
    {
      "severity": "low",
      "column_or_section": "Commission",
      "problem": "Currency is unconfirmed — wiki says 'likely USD given the column context' which is a guess. Review-needed sidecar correctly flags this."
    },
    {
      "severity": "low",
      "column_or_section": "Clients_Units, Clients_AmountUSD",
      "problem": "Client-side data source is speculative ('DWH_dbo.Dim_Position or risk matrix — inferred'). The sibling SP's EOD section uses Dealing_Duco_EODRecon but the Trades section may have used a different source."
    },
    {
      "severity": "low",
      "column_or_section": "SAXO-eToro_Units, SAXO-Clients_Units, SAXO-eToro_Rate, SAXO-eToro_AmountUSD, SAXO-Clients_AmountUSD",
      "problem": "Differential formulas (e.g., SAXO_Units − eToro_Units) are inferred from sibling SP pattern and data values, not confirmed from actual SP code."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Three Atlassian links are tangentially related (general trade reporting, SAXO connectivity, SOD recon) but none is specific to this table. Acknowledged by the writer."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P9", "P9B"]
  }
}
</JUDGE_VERDICT>
