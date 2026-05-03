Let me verify the upstream wiki that the review-needed sidecar references, and check the DDL column count.
Now I have all the information I need. Let me do the systematic evaluation.

---

## Review of EXW_Wallet.PaymentTransactions Wiki

### Critical Finding: Upstream Bundle vs. Actual Upstream

The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable," yet the upstream wiki **does exist** at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`. The writer correctly found and used it (the review-needed sidecar documents this), so the Tier 1 assignments are valid. This is a harness resolution bug, not a writer error.

### Dimension 1 — Tier Accuracy: 10/10

Five random columns sampled: PaymentId, ToAddress, EtoroFeeCalculated, Occurred, etr_ym.

| Column | Expected Tier | Wiki Claims | Correct? |
|--------|--------------|-------------|----------|
| PaymentId | Tier 1 (passthrough, upstream wiki exists) | Tier 1 — Wallet.PaymentTransactions | YES |
| ToAddress | Tier 1 (passthrough, upstream wiki exists) | Tier 1 — Wallet.PaymentTransactions | YES |
| EtoroFeeCalculated | Tier 1 (passthrough, upstream wiki exists) | Tier 1 — Wallet.PaymentTransactions | YES |
| Occurred | Tier 1 (passthrough, upstream wiki exists) | Tier 1 — Wallet.PaymentTransactions | YES |
| etr_ym | Tier 2 (ETL-added partition) | Tier 2 — Generic Pipeline | YES |

0 mismatches, 0 paraphrasing failures.

### Dimension 2 — Upstream Fidelity: 10/10

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match |
|--------|---------------|-----------|-------|
| Id | Auto-incrementing primary key. | Auto-incrementing primary key. | YES |
| PaymentId | Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment. | Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment. | YES |
| ExchangeRate | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. | YES |
| ToAddress | Blockchain destination address for the purchased crypto. | Blockchain destination address for the purchased crypto. | YES |
| Amount | Amount of crypto being purchased/transferred. | Amount of crypto being purchased/transferred. | YES |
| EtoroFeePercentage | eToro service fee as a percentage. | eToro service fee as a percentage. | YES |
| EtoroFeeCalculated | Calculated eToro fee in crypto units. | Calculated eToro fee in crypto units. | YES |
| ProviderFeePercentage | Payment provider's fee as a percentage. | Payment provider's fee as a percentage. | YES |
| ProviderFeeCalculated | Calculated provider fee in crypto units. | Calculated provider fee in crypto units. | YES |
| EstimatedBlockChainFee | Estimated blockchain network fee. | Estimated blockchain network fee. | YES |
| Occurred | Timestamp of record creation. | Timestamp of record creation. | YES |

All 11 Tier 1 columns are character-for-character verbatim matches. Flawless inheritance.

### Dimension 3 — Completeness: 8/10

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (14 = 14) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | YES |
| Dictionary columns with ≤15 values list inline key=value pairs | **NO** — EtoroFeePercentage (2 values: 1.00, 0.01) and ProviderFeePercentage (2 values: 4.00, 0.04) should have inline listings in the Elements table |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 checks → Score: 8

### Dimension 4 — Business Meaning: 10/10

Section 1 is excellent. It names the specific domain (Simplex fiat-to-crypto payments on eToro Wallet/eToroX), defines the row grain (one per payment transaction), explains the ETL pattern (Generic Pipeline, Append), states the refresh status (frozen since 2022-09-20, Simplex decommissioned), provides row count (24,181) and date range (2019-02-01 to 2022-09-20), yearly distribution, and explains the relationship to the parent Payments table. A new analyst would immediately know what this table is and that it's historical-only.

### Dimension 5 — Data Evidence: 8/10

Strong data evidence throughout:
- Row count (24,181) and date range in Section 1
- Yearly distribution (2019: 2,232; 2020: 6,135; 2021: 8,008; 2022: 7,806)
- Fee percentage distributions (99.97% at standard rates, 7 anomalous rows)
- NULL-rate claims for ExchangeRate and Amount

No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer claims "Phases: 12/14" but the individual phase gates are not enumerated. Data claims appear specific and consistent, suggesting real queries were run.

### Dimension 6 — Shape Fidelity: 9/10

Numbered sections (1–8), tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and phases-completed. Minor deviation: no explicit phase gate checklist section. Otherwise matches the golden shape well.

### Weighted Total

```
weighted = 0.25*10 + 0.20*10 + 0.20*8 + 0.15*10 + 0.10*8 + 0.10*9
         = 2.50 + 2.00 + 1.60 + 1.50 + 0.80 + 0.90
         = 9.30
```

**Verdict: PASS**

### Top Issues

1. **EtoroFeePercentage / ProviderFeePercentage** — low-cardinality columns (2 distinct values each) should have inline key=value pairs in the Elements table, not just in the business logic section.
2. **No explicit Phase Gate Checklist** — the footer claims 12/14 phases but individual gates are not enumerated.
3. **Upstream bundle resolution failure** — the harness said "no upstream found" but the wiki exists. The writer worked around this correctly, but the harness routing for WalletDB/Wallet schema needs fixing.

### Regeneration Feedback

1. Add inline value listings in Elements descriptions for EtoroFeePercentage (`1.00 = standard (99.97%), 0.01 = anomalous (0.03%)`) and ProviderFeePercentage (`4.00 = standard (99.97%), 0.04 = anomalous (0.03%)`).
2. Add an explicit Phase Gate Checklist section enumerating which phases were completed.
3. Fix harness upstream resolution for WalletDB/Wallet schema routing so future runs don't need manual wiki discovery.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "PaymentTransactions",
  "weighted_score": 9.3,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Id",
      "upstream_quote": "Auto-incrementing primary key.",
      "wiki_quote": "Auto-incrementing primary key.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PaymentId",
      "upstream_quote": "Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment.",
      "wiki_quote": "Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ExchangeRate",
      "upstream_quote": "Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto.",
      "wiki_quote": "Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ToAddress",
      "upstream_quote": "Blockchain destination address for the purchased crypto.",
      "wiki_quote": "Blockchain destination address for the purchased crypto.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Amount",
      "upstream_quote": "Amount of crypto being purchased/transferred.",
      "wiki_quote": "Amount of crypto being purchased/transferred.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "EtoroFeePercentage",
      "upstream_quote": "eToro service fee as a percentage.",
      "wiki_quote": "eToro service fee as a percentage.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "EtoroFeeCalculated",
      "upstream_quote": "Calculated eToro fee in crypto units.",
      "wiki_quote": "Calculated eToro fee in crypto units.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ProviderFeePercentage",
      "upstream_quote": "Payment provider's fee as a percentage.",
      "wiki_quote": "Payment provider's fee as a percentage.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ProviderFeeCalculated",
      "upstream_quote": "Calculated provider fee in crypto units.",
      "wiki_quote": "Calculated provider fee in crypto units.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "EstimatedBlockChainFee",
      "upstream_quote": "Estimated blockchain network fee.",
      "wiki_quote": "Estimated blockchain network fee.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Occurred",
      "upstream_quote": "Timestamp of record creation.",
      "wiki_quote": "Timestamp of record creation.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "EtoroFeePercentage, ProviderFeePercentage",
      "problem": "Low-cardinality columns (2 distinct values each) should have inline key=value pairs in Elements descriptions. Values are documented in Section 2.2 but not at the element level."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section. Footer claims 12/14 phases but individual gates are not enumerated."
    },
    {
      "severity": "info",
      "column_or_section": "Upstream Bundle",
      "problem": "Harness upstream resolution failed (marked _no_upstream_found.txt) but wiki exists at knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md. Writer correctly found and used it. Harness routing for WalletDB/Wallet schema needs fixing."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add inline value listings in Elements for EtoroFeePercentage (1.00=standard 99.97%, 0.01=anomalous 0.03%) and ProviderFeePercentage (4.00=standard 99.97%, 0.04=anomalous 0.03%). (2) Add explicit Phase Gate Checklist section. (3) Fix harness upstream resolution for WalletDB/Wallet schema.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
