## Adversarial Review: Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 3/10**
Not a single one of the 21 element descriptions carries a `(Tier N — source)` tag. Sampled 5 columns (Date, Funds, Fee, TradeId, InsertTime) — zero have tier annotations. `Funds` is clearly Tier 2 (computed as `Price * Quantity`), `ApiFunds` likewise. The rest would be Tier 3 (SP-derived) or Tier 4 (name-inferred). Complete absence of tier tags is a categorical failure.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable." There are zero Tier 1 columns possible, so there is nothing to verify. Neutral score per rubric.

**Dimension 3 — Completeness: 4/10**
Only 3 of 10 checklist items pass:
- [x] Every element row has 5 cells (all 21 rows correct)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`
- [x] Property table has Production Source, Refresh, Distribution (UC Target absent but arguably N/A)
- [ ] All 8 sections present — only Sections 1 and 2 exist; 3–8 are missing entirely
- [ ] Tier tags on descriptions — zero
- [ ] Section 5.2 ETL pipeline diagram — absent
- [ ] Footer tier breakdown counts — absent
- [ ] Section 1 row count and date range — absent
- [ ] Dictionary columns list key=value pairs — `Side` (Buy/Sell) not enumerated inline
- [ ] Element count matches DDL — no DDL available to verify

**Dimension 4 — Business Meaning: 7/10**
Section 1 names the domain (eToroX exchange hedge trades), states the companion table (`Dealing_MarketMakerAllTrade`), identifies the deprecation reason (eToroX decommission), and cites the SR number plus date. This is useful context. However, it lacks row count, date range, and ETL pattern details (the original load was presumably full/incremental via `SP_MarketMakerAllTrade`).

**Dimension 5 — Data Evidence: 2/10**
No row count, no date range, no enum value listings, no NULL-rate claims. Footer says "Phases: 4/14" — P2 and P3 were clearly skipped. Under the rubric, all data claims without P2/P3 are unverified.

**Dimension 6 — Shape Fidelity: 3/10**
Sections 3–8 are entirely absent. No tier legend (Section 4), no lineage detail section (Section 5), no SQL samples (Section 7), no phase gate checklist (Section 8). The footer exists but lacks a tier breakdown. The document is recognizable as a wiki but structurally incomplete.

---

### T1 Fidelity Table

No upstream wikis were available in the bundle. Zero Tier 1 columns exist.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns — no upstream wikis resolvable |

---

### Top 5 Issues

1. **HIGH — All 21 columns (Section 2)**: Zero tier tags anywhere. Every description must end with `(Tier N — source)` per the wiki standard. None do.

2. **HIGH — Sections 3–8 missing**: The wiki jumps from Section 2 straight to the footer. Even for a deprecated table, the structural skeleton (Sections 3: Relationships, 4: Tier Legend, 5: Lineage, 6: Quality Notes, 7: SQL Samples, 8: Phase Gate) should be present, at minimum as stubs noting deprecation.

3. **MEDIUM — Section 1 lacks row count and date range**: A deprecated table with historical data should still report its final row count and the date range it covers (e.g., "Contains ~X rows spanning YYYY-MM-DD to 2024-03-04").

4. **MEDIUM — `Side` column not enumerated**: `Side` is described as "Buy/Sell" in prose but should list values inline as `key=value` pairs per the standard (e.g., `Buy | Sell`).

5. **LOW — No footer tier breakdown**: Footer should include a count like `Tier 1: 0 | Tier 2: 2 | Tier 3: N | Tier 4: M` even for deprecated tables.

---

### Regeneration Feedback

1. Add `(Tier N — source)` tags to all 21 column descriptions. `Funds` and `ApiFunds` are Tier 2 (computed). Columns traceable to `SP_MarketMakerAllTrade` source are Tier 3. Pure name-inferred columns are Tier 4.
2. Add stub Sections 3–8. For a deprecated table, each can be brief (e.g., Section 5: "ETL via SP_MarketMakerAllTrade — eToroX section commented out since SR-239249"). Section 8 should include the Phase Gate Checklist with honest skip markers.
3. Query the table for a final row count and date range (`SELECT COUNT(*), MIN(Date), MAX(Date)`) and add to Section 1.
4. Enumerate `Side` values inline in the Elements table description.
5. Add tier breakdown counts to the footer.
6. Add UC Target row to the property table (value: N/A — deprecated).

---

### Weighted Score Calculation

```
weighted = 0.25×3 + 0.20×7 + 0.20×4 + 0.15×7 + 0.10×2 + 0.10×3
         = 0.75  + 1.40  + 0.80  + 1.05  + 0.20  + 0.30
         = 4.50
```

**Verdict: FAIL**

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_MarketMakerAllTradeEtoroX",
  "weighted_score": 4.50,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 7,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 2,
    "shape_fidelity": 3
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "All 21 columns (Section 2)",
      "problem": "Zero tier tags on any column description. Every description must end with (Tier N — source). None do. Funds and ApiFunds are clearly Tier 2 (computed), others are Tier 3 or Tier 4."
    },
    {
      "severity": "high",
      "column_or_section": "Sections 3–8",
      "problem": "Sections 3 through 8 are entirely missing. Even for a deprecated table, the structural skeleton should be present as stubs noting deprecation status."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "No row count or date range. A deprecated table with historical data should report its final row count and the date range it covers."
    },
    {
      "severity": "medium",
      "column_or_section": "Side",
      "problem": "Described as 'Buy/Sell' in prose but not enumerated as inline key=value pairs per the wiki standard."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Missing tier breakdown counts (Tier 1: N | Tier 2: N | etc.)."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Add (Tier N — source) tags to all 21 columns — Funds/ApiFunds are Tier 2 (computed), SP-traceable columns are Tier 3, name-inferred columns are Tier 4. (2) Add stub Sections 3–8 with deprecation notes. (3) Query table for final row count and date range and add to Section 1. (4) Enumerate Side values inline. (5) Add tier breakdown counts to footer. (6) Add UC Target (N/A — deprecated) to property table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
