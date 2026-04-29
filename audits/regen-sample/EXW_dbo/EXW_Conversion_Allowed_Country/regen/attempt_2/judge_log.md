Let me verify the upstream wikis that the writer claims to have used for Tier 1 inheritance.
Now let me get the Dim_Country element descriptions for the Tier 1 columns.
Now I have everything needed for the review. Let me compile the verdict.

---

## Adversarial Wiki Judge — EXW_dbo.EXW_Conversion_Allowed_Country

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: Country (Tier 1 — Dictionary.Country ✓, dim-lookup passthrough traced to root origin), CryptoID (Tier 2 — no upstream wiki ✓), AllowedUserSelectedValue (Tier 2 — weight-priority-resolved ETL ✓), FromConversionAllowed (Tier 2 — CASE expression ✓), UpdateDate (Tier 2 — GETDATE() ✓). Zero mismatches. No paraphrasing failures on Tier 1 columns.

**Dimension 2 — Upstream Fidelity: 9/10**
Both Tier 1 columns (Country, CountryID) carry the Dim_Country wiki text verbatim, with additional local context appended (e.g., "CountryID=0 excluded by SP WHERE clause"). No semantic loss, no dropped vendor names or NULL semantics. Marked MINOR — additions don't alter meaning. Writer correctly traced through Dim_Country to the root origin (Dictionary.Country) per dim-lookup rules, despite the upstream bundle resolver having failed to include these wikis.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (21) matches DDL (21). Every element row has 5 cells. Every description ends with (Tier N — source). Property table has Production Source, Refresh, Distribution, UC Target. Section 5.2 has real ASCII ETL pipeline diagram. Footer has tier breakdown. Section 1 has row count (51,642) and temporal anchor (2026-04-15). Tag/flag columns list value distributions inline. Review-needed sidecar does NOT contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is exceptionally specific: names the domain (eToroX crypto conversion eligibility), row grain (country/state × cryptocurrency), ETL SP (SP_EXW_WalletElligibleCountries), refresh pattern (TRUNCATE+INSERT), row count (51,642), cross-product math (250×171 + 53×171), and current operational state (all conversions blocked since 2026-04-14). A new analyst would immediately know what this table is, when to use it, and that it's currently dormant.

**Dimension 5 — Data Evidence: 8/10**
Row count (51,642), refresh date (2026-04-15), value distributions for AllowedUserTagType (Default=100%), FromTagType (Default=51,477, Country=165), ToTagType (Default=51,574, Country=68), FromSelectedValue (33% true, 67% false), crypto count (171), country count (250+53 US states). The cross-product arithmetic checks out: (249+53)×171 = 51,642. Phase Gate not explicitly shown as checklist; footer says "Phases: 13/14" suggesting one phase skipped.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: footer format uses a slightly non-standard `Quality: 7.5/10 | Phases: 13/14` rather than a full phases-completed list.

### T1 Fidelity Table

| Column | Upstream Quote (Dim_Country wiki) | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country). CountryID=0 excluded by SP WHERE clause." | MINOR | No loss — additional local context appended |
| CountryID | "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer." | "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. CountryID=0 excluded by SP WHERE clause. Distribution key for this table." | MINOR | No loss — additional local context appended |

### Top 5 Issues

1. **(Low) Upstream bundle resolver failure** — The bundle declared "NO UPSTREAM WIKI was resolvable" despite Dim_Country.md and Dim_State_and_Province.md existing in the repo. The writer manually corrected this, but the tooling bug should be fixed to prevent future misses.

2. **(Low) Phase Gate transparency** — Footer says "Phases: 13/14" but doesn't enumerate which phase was skipped. A reader cannot tell whether P2 (data sampling) or P3 (distribution analysis) was incomplete.

3. **(Low) Dormant table caveat placement** — The all-conversions-blocked state is well-documented in Sections 1, 2.2, and 3.4, but could benefit from a top-level banner/admonition for analysts who skip to the query patterns.

4. **(Info) EXW_Settings/CryptoTypes no wiki** — 19 of 21 columns are Tier 2 because their upstream sources (EXW_Settings.*, EXW_Wallet.CryptoTypes) have no wiki. This is correctly documented and flagged in the review-needed sidecar.

5. **(Info) Sibling table consistency** — The review-needed sidecar correctly flags that EXW_Payment_Allowed_Country, EXW_Staking_Allowed_Country, etc. follow the same pattern. No issue in this wiki but worth tracking for cross-table consistency.

### Regeneration Feedback

No regeneration needed. This wiki passes. Minor improvements for a future polish pass:

1. Enumerate the specific skipped phase in the footer (e.g., "Phases: 13/14 — P14 skipped: no Atlassian sources").
2. Consider a top-level `> **NOTE: All conversions currently blocked**` admonition for quick scanning.
3. When EXW_Settings or CryptoTypes wikis become available, upgrade the 19 Tier 2 columns per the review-needed sidecar instructions.

### Weighted Score

```
weighted = 0.25×10 + 0.20×9 + 0.20×10 + 0.15×10 + 0.10×8 + 0.10×9
         = 2.50 + 1.80 + 2.00 + 1.50 + 0.80 + 0.90
         = 9.50
```

**Verdict: PASS (9.50)**

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_Conversion_Allowed_Country",
  "weighted_score": 9.50,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country). CountryID=0 excluded by SP WHERE clause.",
      "match": "MINOR",
      "loss": "No loss — additional local context appended (passthrough note, exclusion note)"
    },
    {
      "column": "CountryID",
      "upstream_quote": "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer.",
      "wiki_quote": "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. CountryID=0 excluded by SP WHERE clause. Distribution key for this table.",
      "match": "MINOR",
      "loss": "No loss — additional local context appended (exclusion note, distribution key note)"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Upstream Bundle",
      "problem": "Bundle resolver declared 'NO UPSTREAM WIKI was resolvable' despite Dim_Country.md and Dim_State_and_Province.md existing in the repo. Writer manually corrected this — tooling bug, not a wiki quality issue."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer says 'Phases: 13/14' but does not enumerate which phase was skipped. Reader cannot determine whether a data-critical phase (P2/P3) was incomplete."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Section 3.4",
      "problem": "All-conversions-blocked state is documented in multiple sections but lacks a top-level admonition/banner for quick scanning by analysts."
    },
    {
      "severity": "info",
      "column_or_section": "Elements 5-18 (EXW_Settings/CryptoTypes columns)",
      "problem": "19 of 21 columns are Tier 2 because upstream sources (EXW_Settings.Resources, EXW_Settings.Tags, EXW_Settings.SystemRestrictions, EXW_Wallet.CryptoTypes) have no wiki documentation. Correctly flagged in review-needed sidecar."
    },
    {
      "severity": "info",
      "column_or_section": "Section 8",
      "problem": "No Atlassian sources identified. The SP change history note (Inessa K, 2026-04-14) is included inline — acceptable given no formal Jira ticket was linked."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Wiki passes at 9.50. Optional polish: (1) Enumerate skipped phase in footer. (2) Add top-level admonition for dormant/blocked conversion state. (3) Upgrade Tier 2 columns when EXW_Settings/CryptoTypes wikis become available.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 51,642 in Section 1",
      "AllowedUserTagType distribution (Default=51,642) in element #8",
      "FromTagType distribution (Default=51,477, Country=165) in element #12",
      "ToTagType distribution (Default=51,574, Country=68) in element #16",
      "FromSelectedValue distribution (33% true, 67% false) in element #14",
      "Crypto count (171 active) in element #5",
      "FromResourceName (73 distinct values) in element #11"
    ],
    "skipped_phases": ["Phase 14 of 14 (inferred — exact phase unknown from footer)"]
  }
}
</JUDGE_VERDICT>
