## Human Summary — BI_DB_Deposit_checking_temp_table

### Context

This is a 5-column, 1-row ETL quality-check table. **All five columns are SP-computed values** (SUM aggregations, arithmetic difference, SP-generated string, GETDATE() timestamp). There are no passthrough or rename columns from upstream objects. Consequently the T1 fidelity table is legitimately empty.

---

### Per-Dimension Scores

| Dim | Score | One-Line Justification |
|---|---|---|
| Tier Accuracy (25%) | **10** | All 5 sampled columns correctly Tier 2: SUM aggregates, arithmetic, SP string, and GETDATE() — no mismatches |
| Upstream Fidelity (20%) | **7** | No Tier 1 columns exist; neutral score applies |
| Completeness (20%) | **4** | 7/10 checklist items pass — missing UC Target, ETL diagram in wrong subsection (5.1 not 5.2), no footer tier breakdown |
| Business Meaning (15%) | **9** | Specific, concrete: names domain, row grain, SP, DELETE+INSERT pattern, refresh cadence, sampled value |
| Data Evidence (10%) | **6** | Live sampled date/value present; no formal Phase Gate Checklist in document, so P2+P3 cannot be confirmed |
| Shape Fidelity (10%) | **5** | Missing Tier Confidence Legend in Section 4; footer is a bare property table (no quality score, no phases list) |

**Weighted total: 0.25×10 + 0.20×7 + 0.20×4 + 0.15×9 + 0.10×6 + 0.10×5 = 7.15**

---

### T1 Fidelity Table

No Tier 1 columns exist in this table. All 5 columns are ETL-computed values (SUM aggregations from `Fact_CustomerAction`/`BI_DB_Client_Balance_Aggregate_Level_New`, arithmetic difference, SP-constructed string, and `GETDATE()` timestamp). No upstream wiki passthrough applies. T1 fidelity table is empty by design.

---

### Top 5 Issues

1. **`Error_Message` — factual NULL/empty-string error (Section 3.4 Gotcha + Section 2.1)**
   SP code shows `@v_error_message_deposit` is declared as `VARCHAR(MAX)` with no initialization. When no deposit mismatch occurs, the variable is never SET — so `CAST(@v_error_message_deposit AS VARCHAR(MAX))` inserts NULL, not an empty string. The wiki states "empty string (not NULL) when the check passes" — this contradicts the SP source. The sidecar correctly flags the ambiguity, but the wiki body makes a false definitive claim.

2. **`UpdateDate` — missing critical staleness behavior (Section 1, 3.4)**
   When the opening balance check fires (`@v_Balance_diff <> 0`), the SP issues `RAISERROR(..., 18, -1)`. Depending on execution context, this can abort the batch *before* the `DELETE`/`INSERT` execute — leaving stale data in the table. The wiki never mentions this: it states the table "always holds exactly 1 row (the latest check result)" without caveat. A stale-data scenario is both plausible and operationally significant.

3. **Missing UC Target in property table (Property Table)**
   The property table has Production Source, Refresh, HASH Distribution, and Synapse Index, but omits the `UC Target` row. Other wikis in the same schema include this row even when the target is expected/unconfirmed.

4. **No Tier Confidence Legend in Section 4 (Section 4)**
   The golden reference shape requires a stars/tier legend at the top of the Elements section. It is entirely absent. The upstream bundle shows this pattern clearly in `BI_DB_Client_Balance_Aggregate_Level_New`.

5. **Missing footer tier breakdown and quality score (Footer)**
   Footer contains only a duplicate property table. It is missing: tier breakdown counts (e.g., "Tier 1: 0 | Tier 2: 5 | Tier 3: 0"), a quality score, and a phases-completed list. The ETL ASCII diagram is in Section 5.1 instead of 5.2, conflicting with the golden reference structure.

---

### Regeneration Feedback

1. **Fix `Error_Message` NULL claim**: Remove "empty string (not NULL) when the check passes" from Section 3.4. Replace with: "`Error_Message` is NULL (not empty string) when `Balance_diff_deposit = 0` — `@v_error_message_deposit` is never SET in the passing branch per SP source."
2. **Add staleness warning for `UpdateDate`**: Add gotcha: "If the opening balance check fires `RAISERROR(severity 18)` before reaching the `DELETE`/`INSERT` block, this table retains data from the previous run. Always verify `UpdateDate` matches the expected run date."
3. **Add `UC Target` row** to property table (mark as expected/unconfirmed if not yet known).
4. **Add Tier Confidence Legend** to Section 4 header (4-star to 1-star legend matching the golden shape).
5. **Add footer** with tier breakdown counts (Tier 1: 0, Tier 2: 5), quality score, and phases-completed list.
6. **Restructure Section 5**: Move the ASCII diagram to Section 5.2; relabel current 5.2 "References To" as 5.3 and 5.3 "Referenced By" as 5.4.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposit_checking_temp_table",
  "weighted_score": 7.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 4,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Error_Message (Section 2.1 and Section 3.4 Gotchas)",
      "problem": "Wiki states 'Error_Message is an empty string (not NULL) when the check passes.' SP source shows @v_error_message_deposit is declared VARCHAR(MAX) with no initialization and is never SET in the passing branch. CAST(NULL AS VARCHAR(MAX)) inserts NULL, not empty string. This is a factual error contradicted by the SP code."
    },
    {
      "severity": "high",
      "column_or_section": "UpdateDate (Section 1, 3.4)",
      "problem": "Wiki claims the table 'always holds exactly 1 row (the latest check result).' SP code shows RAISERROR(severity 18) fires when the opening balance check fails, which can abort the batch before the DELETE/INSERT executes, leaving stale data in the table. This critical staleness scenario is not documented."
    },
    {
      "severity": "medium",
      "column_or_section": "Property Table",
      "problem": "UC Target row is missing from the property table. Other wikis in the same schema include this row. Should be added (even if value is 'not yet provisioned' or expected)."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4",
      "problem": "No Tier Confidence Legend present at the top of the Elements section. The golden reference shape requires a stars/tier legend (e.g., 4 stars = Tier 1 verbatim, 3 stars = Tier 2 SP-derived, etc.)."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Section 5",
      "problem": "Footer is a bare duplicate property table — missing tier breakdown counts, quality score, and phases-completed list. Additionally, the ETL ASCII diagram is placed in Section 5.1 instead of 5.2 per the golden reference structure."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Error_Message NULL claim in Section 3.4 Gotchas — @v_error_message_deposit is NULL (not empty string) when Balance_diff_deposit=0, per SP source. (2) Add staleness gotcha for UpdateDate: RAISERROR(severity 18) for opening balance mismatch may abort before DELETE/INSERT runs, leaving stale data. (3) Add UC Target row to property table. (4) Add Tier Confidence Legend to Section 4 (4-star to 1-star table). (5) Add footer with tier breakdown counts (Tier 1: 0, Tier 2: 5, Tier 3: 0), quality score placeholder, and phases-completed list. (6) Restructure Section 5: move ASCII diagram to 5.2, renumber References To as 5.3, Referenced By as 5.4.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["Balance_diff_deposit sampled value 0.000000 (2026-04-27)", "UpdateDate sampled 2026-04-27 03:33:55"],
    "skipped_phases": ["Phase Gate Checklist absent from document — P2 and P3 completion unverifiable"]
  }
}
</JUDGE_VERDICT>
