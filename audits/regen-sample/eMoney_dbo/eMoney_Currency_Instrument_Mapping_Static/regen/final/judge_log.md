## Adversarial Wiki Judge — eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: `Currency`, `InstrumentID`, `BuyCurrencyID`, `SellCurrency`, `UpdateDate`. The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable." No writer SP exists. All 10 columns are correctly tagged Tier 3 (DDL + live data). Every description contains concrete data evidence (specific values, counts, ranges), confirming they are not Tier 4 name-only inferences. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns exist because no upstream wiki was available in the bundle and no writer SP was found. This is the correct outcome — the writer did not fabricate Tier 1 claims. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10**

| Check | Result |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL count (10=10) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 has ETL pipeline ASCII diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 contains row count and date range | PASS |
| Dictionary columns ≤15 values list inline key=value pairs | FAIL — `BuyCurrencyID` and `SellCurrencyID` use internal IDs where `1 = USD` is the critical sentinel value; this should be stated inline in the element description, not just in Section 2 |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

9/10 checks → score 8.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific, concrete, and actionable. It names the domain (eMoney FX currency mapping), row grain (one row per currency–instrument pair), row count (145), date of load (2022-11-21), consumer SPs by name, refresh pattern (none — static), and the primary join pattern (`SellCurrencyID = 1` for USD conversion). A new analyst would immediately understand when and how to query this table. Slight deduction: no explicit mention of the absence of a writer SP in the opening summary sentence (it's in the fourth paragraph).

### Dimension 5 — Data Evidence: **8/10**

Strong live-data grounding throughout:
- Row count (145) and single load timestamp (2022-11-21 14:12:06.137)
- 21 distinct currencies enumerated by ISO code
- Specific instrument IDs cited (1=EUR/USD, 350=EURUSD_conversion, 600–610=ETORIAN series, 666=GBX/USD)
- DWHInstrumentID = InstrumentID equality noted across all 145 rows
- Footer claims "Phases: 13/14" suggesting P2+P3 were executed

Minor deduction: no explicit NULL-rate or distribution analysis (though all columns are NOT NULL per DDL, so this is less critical).

### Dimension 6 — Shape Fidelity: **9/10**

Matches the golden reference shape closely: numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, property table, ASCII pipeline diagram, footer with quality score (7.5/10), phases (13/14), and tier breakdown. Minor deviation: footer format uses `Quality: 7.5/10` rather than a canonical `quality_score:` label, but this is cosmetic.

---

### Weighted Total

```
0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×9
= 2.50 + 1.40 + 1.60 + 1.35 + 0.80 + 0.90
= 8.55
```

**Verdict: PASS**

---

### Top 5 Issues

1. **Medium — `BuyCurrencyID` / `SellCurrencyID` sentinel values not inline.** The critical sentinel `1 = USD` is documented only in Section 2 business logic, not in the Element descriptions themselves. An analyst scanning Element 6/7 wouldn't immediately know that `1` means USD.

2. **Low — Currency list not in Element description.** The 21 currency codes are listed in Section 1 but not repeated in the `Currency` element row. With 21 values this is above the 15-value threshold, so technically not required, but close enough that inline listing would help.

3. **Low — `CurrencyISO` join key names slightly imprecise.** Element 2 says it's the "Primary join key used by consumer SPs to match against eMoney_Account_Mappings.CurrencyBalanceISON" — this is accurate but could cite the exact SP names for traceability (they are in the lineage file but not in the element row).

4. **Low — Section 1 fourth-paragraph structure.** The "no writer SP" fact appears in the fourth paragraph of Section 1 rather than the summary blockquote. The blockquote does mention it ("No writer SP identified") but the detail about UpdateDate evidence supporting this claim is buried.

5. **Low — Self-assigned quality score.** Footer says "Quality: 7.5/10" which is the writer's self-assessment. This is reasonable but the actual content quality exceeds 7.5 for a static table with no upstream — the writer was conservative.

---

### Regeneration Feedback

No regeneration needed (PASS). Minor improvements if re-run:

1. Add `1 = USD` sentinel notation inline in `BuyCurrencyID` and `SellCurrencyID` element descriptions.
2. Move "no writer SP found" evidence (shared UpdateDate) into the summary blockquote or first paragraph of Section 1.

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Currency_Instrument_Mapping_Static",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "BuyCurrencyID, SellCurrencyID",
      "problem": "Sentinel value 1 = USD is documented only in Section 2 business logic, not inline in the Element descriptions. An analyst scanning Element rows 6/7 would miss this critical filter value."
    },
    {
      "severity": "low",
      "column_or_section": "Currency",
      "problem": "21 distinct currency codes are listed in Section 1 but not in the Element description. At 21 values this exceeds the 15-value inline threshold, but is close enough that inline listing would aid usability."
    },
    {
      "severity": "low",
      "column_or_section": "CurrencyISO",
      "problem": "Element 2 references join targets (eMoney_Account_Mappings.CurrencyBalanceISON) without citing which SP performs the join. Traceability is in the lineage file but not in the element row."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "The UpdateDate evidence supporting 'no writer SP' (all 145 rows share 2022-11-21 14:12:06.137) is in the fourth paragraph rather than the summary blockquote."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Self-assigned quality score of 7.5/10 is conservative for the actual content quality of this wiki."
    }
  ],
  "regeneration_feedback": "No regeneration needed (PASS). Minor polish: (1) Add '1 = USD' sentinel inline in BuyCurrencyID and SellCurrencyID element descriptions. (2) Move shared-UpdateDate evidence into the Section 1 summary blockquote.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
