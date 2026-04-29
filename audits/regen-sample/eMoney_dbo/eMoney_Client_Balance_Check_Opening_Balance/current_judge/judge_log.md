## Adversarial Review: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

This is a small (3-column) data quality sentinel table. The wiki is well-crafted for its scope. Let me walk through each dimension.

---

### Dimension 1 — Tier Accuracy: **10/10**

All 3 columns sampled (which is also 100% of columns):

| Column | Claimed Tier | SP Code Evidence | Correct? |
|--------|-------------|-----------------|----------|
| Date | Tier 2 — SP | `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), f.DateID)) AS DATE)` — transform of BalanceDateID | YES |
| Openning_Balance_Gap | Tier 2 — SP via eMoneyClientBalance | `SUM(mcb.OpeningBalanceGAP) ... HAVING SUM<>0` — aggregation | YES |
| UpdateDate | Tier 2 — SP | `@Date` parameter passthrough | YES |

No mismatches. No Tier 1 columns exist, so no paraphrasing failures possible.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns**. All three columns are ETL-computed (transforms or aggregations from eMoneyClientBalance, or SP parameters). The upstream wiki for `eMoneyClientBalance` exists in the bundle, but none of the three target columns are passthroughs or renames — they are all derived via SQL expressions in `SP_eMoney_Client_Balance_Check_Opening_Balance`. Neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist — nothing to evaluate.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES (## 1 through ## 8) |
| Element count = DDL column count | YES (3/3) |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table: Prod Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ASCII pipeline diagram with real names | YES |
| Footer tier breakdown counts | YES (`0 T1, 3 T2, 0 T3, 0 T4, 0 T5`) |
| Section 1: row count and date range | YES (0 rows, sampled 2026-04-21; no date range possible for empty table) |
| Dictionary cols ≤15 values: inline pairs | N/A (no dictionary columns) |
| `.review-needed.md` has no `## 4. Elements` | YES |

10/10 checks pass.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (eToro Money opening balance reconciliation), defines row grain (date with non-zero discrepancy), names the ETL SP and its orchestrator, explains the TRUNCATE + INSERT pattern, states the current 0-row clean state, and provides the exact formula. The typo callout (`Openning`) is a genuinely useful analyst aid. Missing nothing material.

### Dimension 5 — Data Evidence: **7/10**

- Row count present: YES (0 rows, sampled 2026-04-21)
- Date range: N/A (empty table — correctly documented)
- Enum values: N/A
- Footer states `P3 empty table, P10 skipped` — P2/P3 data profiling is meaningfully impossible on a 0-row table, and the writer correctly acknowledged this rather than fabricating claims
- No suspicious fabricated statistics appear anywhere

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1–8 present; tier legend in Section 4; real SQL in Section 7 (both queries are syntactically correct and use the actual typo column name); footer has quality score, phases, and tier breakdown. Minor: footer format `P1-P10A/14` is slightly nonstandard but functionally clear.

---

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS**

### Top Issues

This is a clean wiki. Issues are minor:

1. **Section 2.1 formula comment** — The wiki states the OpeningBalanceGAP formula includes `CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END`. This is actually the formula in `SP_eMoney_ClientBalance` (the upstream), not in `SP_eMoney_Client_Balance_Check_Opening_Balance` itself. The check SP just does `SUM(mcb.OpeningBalanceGAP)`. The wiki correctly attributes this in the Elements table but Section 2.1 could be clearer that this formula lives in the upstream SP.

2. **Review-needed open question about SP schedule** — Not a wiki defect, but the review-needed correctly flags that 0 rows could mean the SP isn't running. This is appropriate uncertainty.

### Regeneration Feedback

No regeneration needed. If polishing:
1. In Section 2.1, clarify that the `CASE WHEN oc.AccountId IS NULL...` formula is from `SP_eMoney_ClientBalance` (which populates `eMoneyClientBalance.OpeningBalanceGAP`), not from the check SP itself.

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Client_Balance_Check_Opening_Balance",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "The OpeningBalanceGAP CASE formula is attributed ambiguously. The formula (CASE WHEN oc.AccountId IS NULL THEN 0 ELSE OpeningBalanceByCB - OpeningBalance END) lives in SP_eMoney_ClientBalance, not in the check SP. Section 2.1 could clarify this is the upstream computation that produces the column the check SP aggregates."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Phase notation 'P1-P10A/14' is slightly nonstandard but functionally clear."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3 (empty table — justified)", "P10"]
  }
}
</JUDGE_VERDICT>
