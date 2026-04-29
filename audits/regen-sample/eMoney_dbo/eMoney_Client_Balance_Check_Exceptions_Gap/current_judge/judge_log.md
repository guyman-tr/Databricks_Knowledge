## Adversarial Review — eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

### Dimension 1 — Tier Accuracy: **10/10**

All 3 columns sampled (all that exist). Each is ETL-computed via the SP:

| Column | Claimed Tier | Verified Tier | Correct? |
|--------|-------------|--------------|----------|
| Date | T2 — SP transform | T2 — `CAST(CONVERT(…BalanceDateID))` | YES |
| Exceptions_Gap | T2 — SP aggregation | T2 — `SUM(CheckCalc) … HAVING <> 0` | YES |
| UpdateDate | T2 — SP parameter | T2 — `@Date` passthrough | YES |

No mismatches. No paraphrasing failures (no T1 columns exist).

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. All three columns are ETL-computed transformations or SP parameters — none are passthroughs from the upstream `eMoneyClientBalance` wiki. This is correct: `Date` applies CAST/CONVERT to `BalanceDateID`, `Exceptions_Gap` is `SUM(CheckCalc)` with GROUP BY/HAVING, and `UpdateDate` is the `@Date` input parameter. Per rubric, score is 7 (neutral — no upstream wiki to inherit from).

#### T1 Fidelity Table

*No Tier 1 columns — table is empty.*

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (3/3) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ETL pipeline diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (0) and date context | YES |
| Dictionary columns list values | N/A (none) |
| `.review-needed.md` has no `## 4. Elements` | YES |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable. Names the domain (eToro Money balance reconciliation), defines the row grain (date with exception), names the ETL SP and orchestrator, explains TRUNCATE+INSERT semantics, provides the CheckCalc formula, and states the operational signal ("empty = green"). One minor inaccuracy costs it the last point (see issues below).

### Dimension 5 — Data Evidence: **7/10**

Row count stated (0, sampled 2026-04-21). Table is genuinely empty, so data profiling is inherently limited. The writer is honest about this — no fabricated distributions or invented enum values. Footer notes "P3 empty table" which is accurate. No false claims.

### Dimension 6 — Shape Fidelity: **9/10**

All structural elements present: numbered sections, tier legend, property table, SQL samples, ASCII pipeline diagram, footer with quality score and phases. Minor: footer phase notation ("P1-P10A/14") is slightly non-standard but readable.

---

### Top Issues

1. **Medium — UpdateDate description is misleading (Section 4, Element #3 & Section 3.4)**
   The wiki states: *"Date and UpdateDate can be different"* and *"UpdateDate … represents the execution date of the SP, which may differ from Date."* This is incorrect for normal operation. In the SP code, `@DateID = CAST(CONVERT(CHAR(8), @Date, 112) AS INT)`, and the query filters `WHERE BalanceDateID = @DateID`. The output `Date = CAST(CONVERT(DATETIME, CONVERT(CHAR(8), f.DateID)) AS DATE)` reconstructs `@Date`. Since `UpdateDate = @Date`, they are algebraically identical in every call. They can only differ if someone manually inserts rows outside the SP.

2. **Low — Orchestrator calling convention not fully precise (Section 1)**
   The wiki says the SP "is not part of the SP_eMoney_Execute_Group_One pipeline." This is useful context, but the statement that it's "called with an explicit @Date parameter" could mislead — the orchestrator (`SP_eMoney_ClientBalance`) passes its own `@d` parameter, not an independently chosen date.

3. **Low — Footer phase notation (Footer)**
   "P1-P10A/14 (P3 empty table, P10 skipped)" — P2 (data profiling) status is ambiguous. Should explicitly state P2 was skipped or not applicable due to empty table.

### Regeneration Feedback

1. Fix UpdateDate description: remove the claim that Date and UpdateDate "may differ." State clearly that both derive from the same `@Date` parameter and are always equal in normal SP execution.
2. In Section 3.4 Gotchas, correct the "Date vs UpdateDate" bullet to reflect that they are the same value, not potentially different.
3. Clarify P2 status in footer — note explicitly that data profiling was skipped because the table has 0 rows.

---

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Client_Balance_Check_Exceptions_Gap",
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
      "severity": "medium",
      "column_or_section": "UpdateDate (Element #3, Section 3.4)",
      "problem": "Wiki claims 'Date and UpdateDate can be different' and that UpdateDate 'represents the execution date of the SP, which may differ from Date.' In the SP code, both Date and UpdateDate derive from the same @Date parameter: Date = CAST(CONVERT(DATETIME, CONVERT(CHAR(8), @DateID))) and UpdateDate = @Date, where @DateID = CAST(CONVERT(CHAR(8), @Date, 112) AS INT). They are algebraically identical in every normal SP call."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Statement that SP is 'called with an explicit @Date parameter' is slightly misleading — the orchestrator SP_eMoney_ClientBalance passes its own @d parameter automatically, not an independently chosen date."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Phase notation 'P1-P10A/14 (P3 empty table, P10 skipped)' does not explicitly address P2 (data profiling) status. Should state P2 skipped/N/A due to empty table."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Correct UpdateDate description in Element #3 — remove claim that Date and UpdateDate 'may differ'; state both derive from the same @Date parameter and are always equal in normal operation. (2) Fix Section 3.4 'Date vs UpdateDate' gotcha to reflect they are identical, not potentially different. (3) Clarify P2 status in footer as skipped/N/A due to 0-row table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2 status ambiguous", "P10 skipped"]
  }
}
</JUDGE_VERDICT>
