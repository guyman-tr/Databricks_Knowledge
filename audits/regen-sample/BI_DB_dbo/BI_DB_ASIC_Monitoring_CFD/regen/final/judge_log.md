## Human-Readable Summary

### Per-Dimension Scores

| Dim | Score | Weight | Justification |
|-----|-------|--------|---------------|
| Tier Accuracy | 10 | 25% | All 5 sampled columns (RealCID, RegisteredReal, Country, Club, AccountManager) correctly tiered. Passthroughs from FSC/Dim_Customer/Dim_Country/Dim_PlayerLevel all Tier 1; concatenation correctly Tier 2. |
| Upstream Fidelity | 10 | 20% | All 4 T1 columns verbatim from upstream wikis. No vendor names dropped, no NULL semantics lost. |
| Completeness | 8 | 20% | All 8 sections present, 18/18 elements, DDL match, tier tags, property table all correct. One miss: bit indicator columns (A1_ConcentrationRisk_Ind etc.) don't enumerate 0=not-flagged / 1=flagged inline per rubric. Review-needed sidecar correctly has no Elements section. |
| Business Meaning | 7 | 15% | Excellent row grain, ETL SP name, refresh pattern, alert definitions, and live counts. Drops to 7 due to a material factual error in the population description and a "six alerts" vs five listed inconsistency. |
| Data Evidence | 7 | 10% | Live counts (483,559 customers, alert rates, P&L ranges, 6-date window) present. No explicit P2/P3 phase gate checkboxes, but numbers are clearly from live data sampling. |
| Shape Fidelity | 8 | 10% | Numbered sections, tier legend, real SQL samples all present. Loses 2 points because the footer omits the quality score (present in all reference wikis as "Quality: X.X/10 ★★★★☆"). |

**Weighted score: 8.65 → PASS**

---

### T1 Fidelity Table

| Column | Upstream quote | Wiki quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values." | "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values." | YES | — |
| RegisteredReal | "Account registration date (renamed from Registered). Default=getdate()." | "Account registration date (renamed from Registered). Default=getdate()." | YES | — |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | YES | — |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | YES | — |

---

### Top 5 Issues (Column-Level Citations)

**Issue 1 — HIGH — Section 2.1, Section 3.4 ("Population excludes CFD_Blocked customers")**
The wiki states: *"only customers where ISNULL(CFD_Status, 'CFD_Allowed') = 'CFD_Allowed' are included. Customers explicitly blocked from CFD trading are excluded."* and the gotcha repeats *"Population excludes CFD_Blocked customers."*

This is factually wrong. The SP uses a `LEFT JOIN` to `BI_DB_Scored_Appropriateness_Negative_Market` with the `ISNULL(bdsanm.CFD_Status,'CFD_Allowed')='CFD_Allowed'` condition in the `ON` clause — not in a `WHERE` clause. When a customer has `CFD_Status='CFD_Blocked'`, the ON condition evaluates to FALSE, the bdsanm row is not joined (bdsanm columns become NULL), but the FSC row **remains in the result** because `LEFT JOIN` preserves all left-table rows. All ASIC-regulated customers (RegulationID IN (4,10)) are in `#pop` regardless of CFD_Status.

**Issue 2 — MEDIUM — Section 2.5, Element 13 (A5 ActionTypeID=36 filter claim)**
Section 2.5 states *"From Fact_CustomerAction where ActionTypeID=36 (Compensation):"* and Element 13's description includes *"ActionTypeID=36"* as a filter. The actual SP code for `#Compensation` is:
```sql
INNER JOIN DWH_dbo.Fact_CustomerAction fca ON pop.RealCID=fca.RealCID AND 
    fca.DateID>=@DateID6MonthAgo AND fca.DateID<@DateID
```
There is **no** `ActionTypeID` filter. The SP joins ALL Fact_CustomerAction events for ASIC customers in the 6-month window; `CompensationReasonID=11` is applied only inside the `CASE` expression. The practical result is the same (only ActionTypeID=36 rows carry non-null CompensationReasonID), but the description is inaccurate and could mislead analysts about query cost and scope.

**Issue 3 — MEDIUM — Section 1 header vs. body ("six alert indicators")**
The property-block tagline and Section 1 heading both say *"six alert indicators"* but the body enumerates only five (A1, A2, A4, A5, A6). Alert A3 is missing/unimplemented. Section 3.4 correctly notes *"Alert A3 not computed"*, but the intro creates a contradiction. A new analyst reading the intro will count five, not six.

**Issue 4 — LOW — Section 4 Elements (bit indicator columns missing inline value enumeration)**
The completeness rubric requires dictionary/enum columns with ≤15 values to list inline `key=value` pairs. The five indicator `bit` columns (`A1_ConcentrationRisk_Ind`, `A2_LossInvestmentRatio_Ind`, `A4_Last_BSL_Date_Ind`, `A5_NegativeBalance_Ind`, `A6_HighLeverageTrading_Ind`) only describe the "1 = flagged" case. They should include `0 = not flagged, 1 = flagged` explicitly.

**Issue 5 — LOW — Footer (missing quality score)**
All reference wikis in the bundle include a quality score in the footer (e.g., `Quality: 8.8/10 (★★★★☆)`). This wiki's footer reads `Generated: 2026-04-28 | Phases: 11/14 (no Atlassian)` with no quality score. Minor, but breaks the standard shape.

---

### Regeneration Feedback

1. **Fix population description (Sections 2.1 and 3.4):** Replace all claims that CFD_Blocked customers are excluded. The correct statement is: *"The LEFT JOIN to `BI_DB_Scored_Appropriateness_Negative_Market` uses the CFD_Allowed condition in the ON clause, not a WHERE clause. All ASIC-regulated customers (RegulationID IN (4,10)) appear in the table; CFD_Blocked customers have NULL bdsanm columns but are not excluded."*
2. **Fix A5 filter description (Section 2.5 and Element 13):** Remove the `ActionTypeID=36` filter claim. Correctly describe the join as: all `Fact_CustomerAction` rows for ASIC customers over the 6-month window are joined; `CompensationReasonID=11` is applied only in the `CASE` expression.
3. **Fix alert count (header and Section 1):** Change *"six alert indicators"* to *"five implemented alert indicators (A1, A2, A4, A5, A6); Alert A3 is referenced in SP comments but not implemented."*
4. **Add 0/1 enumeration to bit indicator columns (Section 4):** For each of the five `_Ind` columns, add `0=not flagged, 1=flagged` inline.
5. **Add quality score to footer** in the format used by reference wikis: `Quality: X.X/10 (★★★★☆)`.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_ASIC_Monitoring_CFD",
  "weighted_score": 8.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 8,
    "business_meaning": 7,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values.",
      "wiki_quote": "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RegisteredReal",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Section 2.1 / Section 3.4 (Population)",
      "problem": "Wiki claims 'Customers explicitly blocked from CFD trading are excluded' and the gotcha repeats 'Population excludes CFD_Blocked customers.' This is factually wrong. The SP uses LEFT JOIN BI_DB_Scored_Appropriateness_Negative_Market with the CFD_Allowed condition in the ON clause, not a WHERE clause. When CFD_Status='CFD_Blocked', the ON condition fails and bdsanm columns are NULL, but the FSC row remains in #pop because LEFT JOIN preserves all left-table rows. All RegulationID IN (4,10) customers are in the population regardless of CFD_Status."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2.5 / Element 13 (A5_NegativeBalance_Ind)",
      "problem": "Section 2.5 and Element 13 both claim the A5 alert queries 'Fact_CustomerAction where ActionTypeID=36 (Compensation)'. The SP has no ActionTypeID filter in the #Compensation CTE — it joins ALL Fact_CustomerAction rows for ASIC customers over the 6-month period and applies CompensationReasonID=11 only inside the CASE expression. The result is identical in practice but the description is inaccurate and overstates the filter selectivity."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 header / tagline (alert count)",
      "problem": "The property-block tagline and Section 1 both state 'six alert indicators' but the body enumerates only five implemented alerts (A1, A2, A4, A5, A6). Alert A3 is not computed in the current SP. Section 3.4 correctly flags this but the intro creates a contradiction that will confuse new analysts."
    },
    {
      "severity": "low",
      "column_or_section": "A1_ConcentrationRisk_Ind / A2_LossInvestmentRatio_Ind / A4_Last_BSL_Date_Ind / A5_NegativeBalance_Ind / A6_HighLeverageTrading_Ind",
      "problem": "All five bit indicator columns describe only the '1 = flagged' condition. Per the completeness rubric, enum/dictionary columns with ≤15 values must list inline key=value pairs (0=not flagged, 1=flagged)."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer is missing the quality score field (e.g., 'Quality: 8.65/10 (★★★★☆)') present in all reference wiki footers in the bundle."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix population description in Sections 2.1 and 3.4 — LEFT JOIN does NOT exclude CFD_Blocked customers; all RegulationID IN (4,10) customers are in #pop regardless of CFD_Status. Replace exclusion claim with: 'The LEFT JOIN NULLs bdsanm columns for CFD_Blocked customers but does not remove them from the population.' (2) Fix A5 filter description in Section 2.5 and Element 13 — remove ActionTypeID=36 claim; the SP joins all FCA rows for ASIC customers over 6 months; CompensationReasonID=11 is checked only in the CASE expression. (3) Change 'six alert indicators' to 'five implemented alert indicators (A1, A2, A4, A5, A6); A3 referenced in SP comments but not implemented.' (4) Add 0=not flagged / 1=flagged inline enumeration to all five _Ind bit columns in Section 4. (5) Add quality score to footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "A1_ConcentrationRisk_Ind: '6.6% of customers flagged'",
      "A2_LossInvestmentRatio_Ind: '3.9% of customers flagged'",
      "A4_Last_BSL_Date_Ind: '<0.01% of customers flagged'",
      "A5_NegativeBalance_Ind: '<0.01% of customers flagged'",
      "A6_HighLeverageTrading_Ind: '1.9% of customers flagged'",
      "TotalNetProfit: 'Range: -$16.7M to +$11.5M observed'"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
