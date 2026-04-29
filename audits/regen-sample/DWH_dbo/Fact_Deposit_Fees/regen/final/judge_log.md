## Adversarial Review: DWH_dbo.Fact_Deposit_Fees

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: ModificationDateID (Tier 2 — ETL-computed via CONVERT/DATEADD, correct), UpdateDate (Tier 2 — GETDATE(), correct), CID (Tier 3 — passthrough, no upstream wiki, correct), FundingMethod (Tier 3 — passthrough, correct), Regulation (Tier 3 — passthrough, correct). Zero mismatches. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable" — Tier 3 is the only defensible classification for all 45 passthroughs.

**Dimension 2 — Upstream Fidelity: 7/10**
Zero Tier 1 columns exist because BackOffice.BillingDepositsPCIVersion has no documented wiki. The bundle confirms this. Per rubric, this is the neutral score. No inheritance was available to miss. No paraphrasing failures possible.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 47 elements match 47 DDL columns exactly. Every element row has 5 cells. Every description ends with `(Tier N — source)`. Property table has Production Source, Refresh, Distribution, UC Target. Section 5.2 has a full ETL pipeline ASCII diagram with real ADF pipeline names and SP names. Footer has tier breakdown. Section 1 has row count (14.4M) and date range (2021-12-01 to 2024-06-30). Enum values are listed inline for FundingMethod, Depot, CustomerStatus, Brand, CardCategory, CustomerLevel, Regulation, WhiteLabel, DepositType, FTD, Funnel, Riskstatus. Review-needed sidecar has no `## 4. Elements` section. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (deposit transactions with fees), row grain (one row per approved deposit), ETL SP, dormancy status, row count, date range, and key distributions (CreditCard 56%, eToroMoney 28%, CySEC 55%). A new analyst would immediately know what this table is, that it's dormant, and which columns matter. Only minor gap: doesn't explicitly name the business team that owns this data.

**Dimension 5 — Data Evidence: 8/10**
Row count (14.4M) and date range in Section 1. Specific enum values listed throughout (BinInBlackList, WithdrawWithLowTradingRatio, HRCLoginToRegCountryConflict for Riskstatus). Distribution percentages (CreditCard 56%, eToroMoney 28%, PayPal 12%). NULL-rate claims (Riskstatus ~96% empty, FTD ~8%). Footer says "Phases: 12/14" — two phases were skipped but the data specificity (exact risk flag strings, exact percentage distributions, leading-space quirk in TransactionResponse) strongly indicates live data was queried. Deducting slightly for the 2 skipped phases and inability to confirm which ones.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, three real SQL samples in Section 7 with correct column names, footer with quality score and phases-completed. Minor deviation: footer format uses `Quality: 7.0/10 | Phases: 12/14` rather than a more granular phases-completed list. Otherwise matches the golden shape well.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream source (BackOffice.BillingDepositsPCIVersion) has no wiki in the bundle. This is correctly reflected in the tier assignments.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section 3.4 / SP code** — The SP's WHERE clause is entirely commented out, meaning each execution inserts ALL rows from staging (not just the day's data). The wiki mentions "append-only mode" and flags duplicate risk in Gotchas and review-needed, but Section 1 should state more prominently that the table likely contains duplicates due to the full-reload-without-delete pattern.

2. **Severity: low | Column: DepositCollarAmount (#12)** — Description says "converted to a base currency (USD equivalent)" but this is an inference from data patterns, not confirmed by any upstream documentation. The review-needed file correctly flags this for human review, but the wiki description states the USD-equivalent interpretation as fact rather than as an observed inference.

3. **Severity: low | Section 1** — Claims "predominantly composed of approved deposits (~99.99% Approved in 2024 data)" — the precision of "99.99%" implies only ~1.4 non-approved rows in 14.4M, but the wiki also says there's only 1 ReversedDeposit in 2024 H1. If 2024 data is only H1 (~7M rows), 1/7M is ~99.99986%, so the number checks out. Minor nit but the percentage should match the stated scope (H1 2024 vs full 2024).

4. **Severity: low | Column: ExchangeRate (#22)** — Description says "May differ from BaseExchangeRate due to spread or fee adjustments" — this is speculative. No upstream documentation confirms the relationship between ExchangeRate and BaseExchangeRate. Should be flagged as inferred.

5. **Severity: info | Section 8** — Atlassian scan was skipped ("regen harness mode — Atlassian scan skipped for dormant table"). This is reasonable given dormancy but means potential Jira/Confluence context about why the table was decommissioned is missing.

### Regeneration Feedback

No regeneration required — the wiki passes. For a future polish pass:

1. Strengthen Section 1 to explicitly state the duplicate-risk implication of full-reload-without-delete (currently buried in Gotchas).
2. Mark DepositCollarAmount description as inferred rather than authoritative ("appears to be" rather than "is").
3. Mark ExchangeRate vs BaseExchangeRate relationship as inferred.
4. If a wiki for BackOffice.BillingDepositsPCIVersion is ever created, upgrade all 45 Tier 3 columns to Tier 1 with verbatim descriptions.

### Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
         = 8.95
```

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Fact_Deposit_Fees",
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
      "severity": "low",
      "column_or_section": "Section 1 / SP code",
      "problem": "SP WHERE clause is entirely commented out — each run inserts ALL staging rows. Wiki mentions 'append-only mode' in Gotchas but Section 1 should state duplicate risk more prominently given the full-reload-without-delete pattern."
    },
    {
      "severity": "low",
      "column_or_section": "DepositCollarAmount",
      "problem": "Description states 'Deposit amount converted to a base currency (USD equivalent)' as fact, but this is inferred from data patterns with no upstream documentation. Should be phrased as observed/inferred."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Claims '~99.99% Approved in 2024 data' but 2024 data only covers H1 (through June 2024). The percentage scope should match the stated data scope."
    },
    {
      "severity": "low",
      "column_or_section": "ExchangeRate",
      "problem": "Description says 'May differ from BaseExchangeRate due to spread or fee adjustments' — this is speculative with no upstream documentation confirming the relationship."
    },
    {
      "severity": "info",
      "column_or_section": "Section 8",
      "problem": "Atlassian scan skipped for dormant table. Potential Jira/Confluence context about decommissioning rationale is missing."
    }
  ],
  "regeneration_feedback": "No regeneration required. For polish: (1) Move duplicate-risk warning from Gotchas into Section 1 summary. (2) Mark DepositCollarAmount USD-equivalent interpretation as inferred. (3) Mark ExchangeRate vs BaseExchangeRate relationship as inferred. (4) Upgrade Tier 3 columns to Tier 1 if BackOffice.BillingDepositsPCIVersion wiki is ever created.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 14.4M rows, 2021-12-01 to 2024-06-30",
      "Section 1: CreditCard 56%, eToroMoney 28%, PayPal 12%",
      "Section 1: CySEC 55%, FCA 26%",
      "Riskstatus: ~96% empty",
      "FTD: ~8% in 2024",
      "DepositStatus: ~99.99% Approved"
    ],
    "skipped_phases": ["2 of 14 phases skipped per footer — specific phases not identified"]
  }
}
</JUDGE_VERDICT>
