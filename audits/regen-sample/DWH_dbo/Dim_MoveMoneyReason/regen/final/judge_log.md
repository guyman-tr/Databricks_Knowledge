# Adversarial Review: DWH_dbo.Dim_MoveMoneyReason

## Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 3 columns checked. MoveMoneyReasonID and MoveMoneyReason are passthroughs from `Dictionary.MoveMoneyReason` with upstream wiki available — correctly tagged Tier 1. UpdateDate is ETL-added (not in production source) — correctly tagged Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 10/10**
Both Tier 1 columns are character-for-character verbatim from the upstream wiki. No paraphrasing, no dropped vendor names, no lost semantics. Excellent.

**Dimension 3 — Completeness: 8/10 (9/10 checks)**
All 8 sections present; element count matches DDL (3/3); all element rows have 5 cells with tier tags; property table has all required fields; Section 5.2 has real ASCII pipeline diagram; footer has tier breakdown; Section 1 has row count (4); dictionary values listed inline. One miss: `.review-needed.md` does not contain `## 4. Elements` (pass). However, footer is missing a phases-completed list — it has `Quality: 8.5/10` but no `Phases: P1/P2/P3` line, which the golden shape expects.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (ActiveCredit ledger money movements), row grain (one row per reason code), row count (4), ETL pattern (Generic Pipeline, Override, daily), production source, and downstream consumers. The data staleness discussion (4 of 9+ codes, 2022 UpdateDates) is a valuable callout. Missing only explicit date range.

**Dimension 5 — Data Evidence: 5/10**
Row count (4 rows) and specific enum values (IDs 1-4) are present. The data staleness analysis comparing DWH vs production is good. However, there is no explicit Phase Gate Checklist showing P2/P3 completion. The footer lacks a phases-completed indicator. Data claims about "4 rows" and "ID 4 = Airdrop" are plausible but unverifiable without phase gate documentation. NULL-rate claims are absent.

**Dimension 6 — Shape Fidelity: 7/10**
Numbered sections, tier legend, real SQL samples all present. Footer has quality score and tier breakdown but lacks the standard phases-completed format (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`). Minor deviation from golden reference shape.

---

## T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| MoveMoneyReasonID | "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures." | "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures." | YES | — |
| MoveMoneyReason | "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens." | "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens." | YES | — |

---

## Top 5 Issues

1. **[medium] Footer** — Missing phases-completed list. Golden shape expects `Phases: P1 ✓, P2 ✓, P3 ✓` or similar. Current footer only has `Quality: 8.5/10` and tier counts.

2. **[low] Section 1** — No explicit date range (min/max of UpdateDate). States "2022" but a specific range like `2022-01-15 to 2022-11-13` would be more precise.

3. **[low] Section 2.1** — The business logic lists "4 = Airdrop" as a DWH value, while the Element description (correctly verbatim from upstream) says "Gap at ID 4." This factual tension is explained in Sections 2.2 and the review-needed sidecar, but Section 2.1 could more explicitly label which values are DWH-observed vs upstream-documented.

4. **[low] Section 4 Elements** — The upstream wiki notes MoveMoneyReasonID is `NOT NULL` in production, but the DWH DDL has it as `NULL`. The element correctly shows `YES` for nullable (matching DWH DDL), which is correct, but a brief note about the nullability difference from production would help analysts.

5. **[info] Section 3.4 Gotchas** — Good coverage of the DWH/production discrepancy, nullable PK, and UpdateDate semantics. No issue here, just noting this is well done.

---

## Regeneration Feedback

1. Add a phases-completed indicator to the footer (e.g., `Phases: P1 ✓, P2 skipped, P3 skipped` or whatever is accurate).
2. Add explicit min/max date range for UpdateDate in Section 1 if live data was queried.
3. Consider a brief note in Section 2.1 header distinguishing "DWH-observed values" from "upstream-documented values" to avoid confusion with the verbatim Tier 1 element description.

---

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_MoveMoneyReason",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "MoveMoneyReasonID",
      "upstream_quote": "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures.",
      "wiki_quote": "Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MoveMoneyReason",
      "upstream_quote": "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens.",
      "wiki_quote": "Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Missing phases-completed list in footer. Golden shape expects explicit P1/P2/P3 completion indicators."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "No explicit min/max date range for UpdateDate. States '2022' generically instead of precise range."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "Lists '4 = Airdrop' as DWH value while Element description (correctly verbatim from upstream) says 'Gap at ID 4'. The tension is explained in Section 2.2 but could be clearer in 2.1."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 — MoveMoneyReasonID",
      "problem": "Production source has NOT NULL constraint on MoveMoneyReasonID but DWH DDL is NULL. Element correctly shows YES but a note about the nullability difference would help analysts."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add phases-completed indicator to footer. (2) Add explicit min/max UpdateDate range in Section 1 if live data was queried. (3) Clarify in Section 2.1 header that values listed are DWH-observed vs upstream-documented.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
