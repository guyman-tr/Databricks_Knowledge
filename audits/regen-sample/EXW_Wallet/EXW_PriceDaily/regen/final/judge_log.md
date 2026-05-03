## Review of EXW_Wallet.EXW_PriceDaily

### Dimension 1 — Tier Accuracy: **10/10**
Sampled 5 columns: eToroInstrumentID, CryptoID, CryptoName, AvgPrice, FullDate. All correctly tagged Tier 2. No upstream wikis exist for any source table (confirmed by bundle's "NO UPSTREAM WIKI" statement), so Tier 1 is impossible. Computed columns (AvgPrice, FullDateID) and passthroughs without upstream documentation are all appropriately Tier 2. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)
No Tier 1 columns exist because no upstream wiki was resolvable for any source. The bundle explicitly confirms this. Neutral score applies per rubric.

### T1 Fidelity Table

No Tier 1 columns — table is empty. All 10 columns are Tier 2, grounded in SP_Prices source code and DDL. This is correct given the bundle contained zero upstream wikis.

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

| Check | Result |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL count (10/10) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with (Tier N — source) | PASS |
| Property table has required fields | PASS |
| Section 5.2 has ETL pipeline diagram | PASS |
| Footer has tier breakdown | PASS |
| Section 1 has row count + date range | PASS |
| Dictionary columns list key=value pairs | **FAIL** — BlockchainCryptoId has 12 values, only lists "e.g., 1=BTC, 2=ETH" |
| .review-needed lacks ## 4. Elements | PASS |

### Dimension 4 — Business Meaning: **9/10**
Section 1 is specific and actionable: names the domain (eToroX/eToro Money wallet), row grain (one per CryptoID per day, Rn=1 last hourly snapshot), ETL SP (SP_Prices), refresh pattern (daily DELETE+INSERT with @dt parameter), row count (414K), date range (2018-04-23 to 2026-04-25), and asset coverage (173 cryptos, 13 blockchains). A new analyst would know exactly when and how to query this table.

### Dimension 5 — Data Evidence: **7/10**
Row count (414K), date range, NULL rates (83% eToroInstrumentID NULL = 344K/414K), distinct value counts (173 CryptoIDs, 13 networks, 191 InstrumentIDs), and AvgPrice anomalies are all cited with specific numbers. Footer claims "Phases: 11/14" but no explicit P2/P3 checkboxes are shown. The specificity of the numbers (344K/414K, 61 with eToroInstrumentID) strongly suggests live data was queried.

### Dimension 6 — Shape Fidelity: **8/10**
All structural elements present: numbered sections 1–8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and phase count. Minor deviations: Section 8 title is "Atlassian Knowledge Sources" rather than a more standard label; footer format slightly non-standard but readable.

### Weighted Total
```
0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
= 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80 = 8.35
```

### Top 5 Issues

1. **(medium) BlockchainCryptoId** — Has 12 distinct values but only lists "e.g., 1=BTC, 2=ETH". Should enumerate all 12 key=value pairs inline since count is ≤15.
2. **(low) BlockchainCryptoName** — Claims 13 distinct values but BlockchainCryptoId has 12. The one-off discrepancy (13 vs 12) should be clarified — likely one CryptoID maps to multiple names or vice versa.
3. **(low) Phase Gate visibility** — Footer says "Phases: 11/14" but the wiki body doesn't include an explicit Phase Gate Checklist section showing which phases were completed.
4. **(low) InstrumentID description** — Says "Derived from EXW_Currency.Instruments.Id via CryptoMarketRatesMappings join" but the CASE logic actually derives it from eToroInstrumentID or CryptoId. The Instruments.Id is the *original* InstrumentID before the CASE override. Slightly misleading.
5. **(low) Section 2.3 gap-fill detail** — The wiki describes OUTER APPLY forward-fill but doesn't mention that the SP also gap-fills AskLast and LastBid separately (columns s and z in the SP). These aren't in the final PriceDaily output but affect the AvgPrice gap-fill chain.

### Regeneration Feedback

1. Enumerate all 12 BlockchainCryptoId key=value pairs in the column description (≤15 threshold met).
2. Clarify the 13 vs 12 discrepancy between BlockchainCryptoName and BlockchainCryptoId distinct counts.
3. Refine InstrumentID description: the CASE logic produces the value from eToroInstrumentID or CryptoId, not from Instruments.Id directly.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "EXW_PriceDaily",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "BlockchainCryptoId",
      "problem": "Has 12 distinct values (≤15 threshold) but only lists 'e.g., 1=BTC, 2=ETH' instead of enumerating all key=value pairs inline."
    },
    {
      "severity": "low",
      "column_or_section": "BlockchainCryptoName vs BlockchainCryptoId",
      "problem": "BlockchainCryptoName claims 13 distinct values while BlockchainCryptoId claims 12. The discrepancy is not explained."
    },
    {
      "severity": "low",
      "column_or_section": "Section footer",
      "problem": "Footer states 'Phases: 11/14' but no explicit Phase Gate Checklist section is included to show which phases passed or were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentID",
      "problem": "Description says 'Derived from EXW_Currency.Instruments.Id via CryptoMarketRatesMappings join' but the final value comes from a CASE on eToroInstrumentID or CryptoId, not directly from Instruments.Id."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.3",
      "problem": "Gap-fill description omits that AskLast and LastBid are also independently forward-filled via separate OUTER APPLY subqueries in the SP, which can affect downstream AvgPrice computation."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Enumerate all 12 BlockchainCryptoId key=value pairs in the element description. (2) Clarify 13 vs 12 discrepancy between BlockchainCryptoName and BlockchainCryptoId. (3) Refine InstrumentID description to clarify the CASE logic produces the value, not a direct passthrough from Instruments.Id.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["414K rows", "2018-04-23 to 2026-04-25", "173 CryptoIDs", "13 blockchain networks", "83% NULL eToroInstrumentID", "344K/414K"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
