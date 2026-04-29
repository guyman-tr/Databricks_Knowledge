## Adversarial Wiki Review: `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 3 columns are Tier 2. `Date` is derived via INT→date conversion of `BalanceDateID`, `Openning_Balance_Gap` is `SUM(OpeningBalanceGAP)` with HAVING filter, and `UpdateDate` is the SP `@Date` input parameter. None are passthroughs — all involve transformation or aggregation. Tiers are correct.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist. The upstream `eMoneyClientBalance` wiki was available and the writer correctly determined that every column undergoes transformation (date conversion, SUM aggregation, parameter assignment). No inheritance was missed. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10 (9/10 checks)**
All 8 sections present. Element count matches DDL (3/3). All element rows have 5 cells with tier tags. Property table complete. ETL pipeline diagram uses real SP names. Footer has tier breakdown. Section 1 has row count (0). `.review-needed.md` does not contain `## 4. Elements`. One miss: no date range in Section 1 (defensible for a 0-row table but the rubric doesn't exempt empty tables).

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToro Money balance reconciliation), the row grain (one summary row per business date with non-zero aggregate gap), the ETL SP and its caller, the TRUNCATE+INSERT refresh pattern, and what empty vs. non-empty means operationally. Author attribution included.

**Dimension 5 — Data Evidence: 6/10**
Footer claims all phases (P1–P11) completed. Row count of 0 is verifiable and credible. However, for a 0-row table, P2 (row counts) is trivially satisfied and P3 (distributions) is not demonstrable. No enum values or NULL-rate analysis possible. The evidence is limited by the table's nature, but claiming P3 completed is a stretch.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8 present. Tier legend in Section 4. Two real SQL samples in Section 7. Footer has quality score and phases-completed list. Minor: no explicit Phase Gate Checklist section (embedded in footer only).

### T1 Fidelity Table

No Tier 1 columns exist. All 3 columns are correctly tagged Tier 2 (ETL-computed).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **(low) Section 2.1 — TRUNCATE timing**: Wiki states "TRUNCATE TABLE is called unconditionally at the start of every SP run." The SP code shows `#final` is built FIRST, then TRUNCATE, then INSERT. The TRUNCATE is mid-SP, not at the start. This matters operationally: if `#final` creation fails, the existing data is preserved.

2. **(low) Section 2.2 — OpeningBalanceGAP formula**: Wiki describes the per-account gap as `ISNULL(prior_day_ClosingBalanceBO - current_OpeningBalance, 0)`. The actual SP code uses `CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END`. Semantically equivalent but the ISNULL framing is technically inaccurate.

3. **(low) Footer — P3 claim**: Footer claims P3 (distribution analysis) completed. For a table with 0 rows, distribution analysis is vacuous. The claim is misleading though not harmful.

4. **(low) Section 1 — missing date range**: No date range stated. Defensible for an empty table, but a note like "no historical data — table is currently empty" would be more explicit.

5. **(informational) Section 7.2 — query assumes non-empty**: The drill-down query uses `SELECT TOP 1 Date` as a subquery filter. Functional when alert is active, but returns no rows (not an error) when table is empty. Could note this for analyst clarity.

### Regeneration Feedback

No regeneration needed. If polishing:
1. Fix TRUNCATE timing in Section 2.1 — state it occurs after `#final` creation, not at SP start.
2. Correct the OpeningBalanceGAP formula from `ISNULL(...)` to `CASE WHEN ... IS NULL THEN 0 ELSE ... END`.
3. Downgrade P3 in the footer phases list or add "(trivial — 0 rows)" qualifier.

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Client_Balance_Check_Opening_Balance",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "Wiki states TRUNCATE is called 'at the start of every SP run' but SP code builds #final first, then TRUNCATEs, then INSERTs. TRUNCATE is mid-SP, not at the start."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2 — Openning_Balance_Gap",
      "problem": "Wiki describes per-account OpeningBalanceGAP formula as ISNULL(prior_day_ClosingBalanceBO - current_OpeningBalance, 0). Actual SP uses CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END — semantically similar but technically different construct."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims P3 (distribution analysis) completed, but table has 0 rows — distribution analysis is vacuous for an empty table."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "No date range stated. While defensible for a 0-row table, an explicit note acknowledging absence would be clearer."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7.2",
      "problem": "Drill-down query uses SELECT TOP 1 Date as subquery; could note that the query returns 0 rows (not an error) when the alert table is empty."
    }
  ],
  "regeneration_feedback": "No regeneration required. Minor polish: (1) Fix TRUNCATE timing in Section 2.1 to state it occurs after #final creation, not at SP start. (2) Correct OpeningBalanceGAP formula from ISNULL() to CASE WHEN pattern matching actual SP code. (3) Qualify P3 in footer as trivial due to 0-row table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
