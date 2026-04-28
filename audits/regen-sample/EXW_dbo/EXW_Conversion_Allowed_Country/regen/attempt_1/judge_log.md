I need to verify the Tier 1 claims. The upstream bundle says "NO UPSTREAM WIKI was resolvable," but the wiki claims two columns as Tier 1 from Dictionary.Country. Let me check.
The upstream wikis exist in the repo. Let me read them to verify the Tier 1 claims.
Now I have everything I need. Let me do the full adversarial review.

---

## Adversarial Wiki Judge — EXW_dbo.EXW_Conversion_Allowed_Country

### Dimension 1 — Tier Accuracy: **6/10**

Five random columns sampled: **Country** (1), **CountryID** (2), **CryptoID** (5), **AllowedUserTagType** (8), **FromConversionAllowed** (19).

| Column | Wiki Claim | Correct Tier | Verdict |
|--------|-----------|-------------|---------|
| Country | Tier 1 — Dictionary.Country | Tier 1 — Dictionary.Country (via Dim_Country) | Correct |
| CountryID | Tier 1 — Dictionary.Country | Tier 1 — Dictionary.Country (via Dim_Country) | Correct |
| CryptoID | Tier 2 — SP | Tier 2 (no upstream wiki) | Correct |
| AllowedUserTagType | Tier 2 — SP | Tier 2 (no upstream wiki, complex transform) | Correct |
| FromConversionAllowed | Tier 2 — SP | Tier 2 (CASE expression) | Correct |

0 mismatches → base 10. But both Tier 1 columns are **paraphrased** (not verbatim from `Dim_Country.md`):

- **Country**: Drops "Unique per row." from the upstream Dim_Country.Name description. (-2)
- **CountryID**: Drops "0=Not available (fallback/placeholder for users whose country cannot be determined)". Rewrites "Primary key" to "Primary key in Dim_Country." (-2)

10 - 2 - 2 = **6**.

### Dimension 2 — Upstream Fidelity: **3/10**

The repo contains `Dim_Country.md` and `Dim_State_and_Province.md` as upstream wikis. The bundle incorrectly claimed "NO UPSTREAM WIKI was resolvable," but the writer found the right origin (Dictionary.Country). Despite that, neither Tier 1 column uses verbatim text from the upstream wiki.

#### T1 Fidelity Table

| Column | Upstream Quote (Dim_Country.md) | Wiki Quote | Match | Loss |
|--------|-------------------------------|------------|-------|------|
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country)." | NO | Dropped "Unique per row." Added lineage context that doesn't belong in a Tier 1 verbatim quote. |
| CountryID | "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer." | "Primary key in Dim_Country. 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. Distribution key for this table. CountryID=0 excluded by SP WHERE clause. Passthrough from Dim_Country." | NO | Dropped critical NULL semantics: "0=Not available (fallback/placeholder for users whose country cannot be determined)". Changed "Primary key" → "Primary key in Dim_Country". Added unrelated context (distribution key, SP clause). |

2 paraphrased → **3**.

### Dimension 3 — Completeness: **8/10** (9/10 checklist)

- [x] All 8 sections present
- [x] Element count matches DDL: 21 = 21
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ASCII ETL pipeline with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (51,642) and date (2026-04-15)
- [ ] Dictionary columns with ≤15 values don't list formal `key=value` pairs — `AllowedUserTagType` (3 values), `FromConversionAllowed` (0/1), `ToConversionAllowed` (0/1) are described in prose but not as inline enumerations
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9/10 → **8**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is outstanding. It names:
- Domain: eToroX crypto-to-crypto conversion eligibility
- Row grain: country (or US state) × cryptocurrency
- Row count: 51,642 with the math (250×171 + 53×171)
- ETL SP: SP_EXW_WalletElligibleCountries
- Refresh: TRUNCATE+INSERT
- Current state: all conversions blocked since 2026-04-14
- The tag-priority weight-resolution mechanism is clearly explained

A brand-new analyst would immediately know what this table is, how it works, and that it's currently dormant.

### Dimension 5 — Data Evidence: **7/10**

Strong evidence of live data usage:
- 51,642 row count, 171 active cryptos, 250 countries, 53 US states
- Specific distribution: "33% true, 67% false" for FromSelectedValue
- AllowedUserSelectedValue='false' for all rows — confirmed live
- 73 distinct FromResourceName values
- SP change history dated 2026-04-14

Footer says "Phases: 13/14" but doesn't explicitly mark P2/P3 as checked. Data claims appear credible and specific.

### Dimension 6 — Shape Fidelity: **8/10**

Sections 1-8 numbered correctly. Tier legend present in Section 4. Three real SQL queries in Section 7. Footer has quality score and tier breakdown. Minor deviation: footer format slightly non-standard ("Phases: 13/14" without listing which phase was skipped).

---

### Weighted Total

```
weighted = 0.25×6 + 0.20×3 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.50 + 0.60 + 1.60 + 1.35 + 0.70 + 0.80
         = 6.55
```

**Verdict: FAIL** (6.55 < 7.5)

---

### Top 5 Issues

1. **HIGH — Country (Tier 1 paraphrased)**: Drops "Unique per row." from Dim_Country.Name upstream description. Tier 1 requires verbatim text.
2. **HIGH — CountryID (Tier 1 paraphrased, NULL semantics dropped)**: Removes "0=Not available (fallback/placeholder for users whose country cannot be determined)" from Dim_Country.CountryID upstream description. This is critical semantics about the sentinel value.
3. **MEDIUM — Both T1 columns add non-upstream context inline**: "Passthrough from Dim_Country", "Distribution key for this table", "CountryID=0 excluded by SP WHERE clause" are writer additions mixed into what should be a verbatim upstream quote. Move supplementary context after the upstream quote.
4. **LOW — Dictionary enums not listed as key=value**: `AllowedUserTagType` has 3 known values, `FromConversionAllowed`/`ToConversionAllowed` are binary. Should use inline enumeration format.
5. **LOW — Upstream bundle gap unacknowledged**: The bundle said "NO UPSTREAM WIKI was resolvable" but `Dim_Country.md` and `Dim_State_and_Province.md` exist. The writer correctly traced origins but didn't flag the bundle discrepancy in the review-needed sidecar.

### Regeneration Feedback

1. For **Country**: Replace description with verbatim Dim_Country.Name text: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." Append lineage context AFTER the upstream quote if needed.
2. For **CountryID**: Replace description with verbatim Dim_Country.CountryID text: "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer." Then append "CountryID=0 excluded by SP WHERE clause. Distribution key for this table." as supplementary context.
3. Add inline `key=value` pairs for `AllowedUserTagType` (Default, Country, CountryAndRegion), `FromConversionAllowed` (0=blocked, 1=allowed), `ToConversionAllowed` (0=blocked, 1=allowed).
4. Add a note in `.review-needed.md` that the upstream bundle failed to resolve Dim_Country.md and Dim_State_and_Province.md despite them existing in the repo.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_Conversion_Allowed_Country",
  "weighted_score": 6.55,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country).",
      "match": "NO",
      "loss": "Dropped 'Unique per row.' Added non-upstream lineage context ('Passthrough from Dim_Country (c.Name AS Country)')."
    },
    {
      "column": "CountryID",
      "upstream_quote": "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer.",
      "wiki_quote": "Primary key in Dim_Country. 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. Distribution key for this table. CountryID=0 excluded by SP WHERE clause. Passthrough from Dim_Country.",
      "match": "NO",
      "loss": "Dropped critical sentinel semantics: '0=Not available (fallback/placeholder for users whose country cannot be determined)'. Changed 'Primary key' to 'Primary key in Dim_Country'. Added unrelated context (distribution key, SP WHERE clause, passthrough note)."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Country",
      "problem": "Tier 1 column paraphrased: dropped 'Unique per row.' from Dim_Country.Name upstream description. Added non-upstream lineage context inline."
    },
    {
      "severity": "high",
      "column_or_section": "CountryID",
      "problem": "Tier 1 column paraphrased: dropped '0=Not available (fallback/placeholder for users whose country cannot be determined)' sentinel semantics from Dim_Country.CountryID upstream description. Rewrote 'Primary key' to 'Primary key in Dim_Country'. Added distribution key and SP WHERE clause context that is not part of the upstream quote."
    },
    {
      "severity": "medium",
      "column_or_section": "Country, CountryID",
      "problem": "Both Tier 1 columns mix supplementary writer context into what should be a verbatim upstream quote. Lineage notes (passthrough, distribution key) should follow after the quoted text, not replace parts of it."
    },
    {
      "severity": "low",
      "column_or_section": "AllowedUserTagType, FromConversionAllowed, ToConversionAllowed",
      "problem": "Dictionary-like columns with ≤15 distinct values described in prose rather than formal inline key=value pair enumeration."
    },
    {
      "severity": "low",
      "column_or_section": "review-needed.md",
      "problem": "Upstream bundle claimed 'NO UPSTREAM WIKI was resolvable' but Dim_Country.md and Dim_State_and_Province.md exist in the repo. This discrepancy is not flagged in the review-needed sidecar."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace Country description with verbatim Dim_Country.Name text: 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' Append lineage context after the quote. (2) Replace CountryID description with verbatim Dim_Country.CountryID text: 'Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer.' Append 'CountryID=0 excluded by SP WHERE clause. Distribution key for this table.' as supplementary context. (3) Add inline key=value enumeration for AllowedUserTagType, FromConversionAllowed, ToConversionAllowed. (4) Flag upstream bundle resolution gap in review-needed sidecar.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
