## Judge Evaluation: BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide

### Dimension 1 — Tier Accuracy: **7/10**

Sampled 5 columns: CID (#2), Region (#7), Largest_Asset_Class (#10), YTD (#12), IsBlocked (#30).

| Column | Expected Tier | Wiki Tier | Correct? |
|--------|--------------|-----------|----------|
| CID | Tier 1 — Customer.CustomerStatic (passthrough via Dim_Customer) | Tier 1 — Customer.CustomerStatic | YES |
| Region | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse (Dim_Country marks Region as Tier 2) | Tier 1 — Dictionary.Country | **NO** |
| Largest_Asset_Class | Tier 2 — ETL-computed ROW_NUMBER | Tier 2 | YES |
| YTD | Tier 2 — DWH_GainDaily | Tier 2 | YES |
| IsBlocked | Tier 2 — ETL-computed | Tier 2 | YES |

1 mismatch = score 7. Region is wrongly promoted to Tier 1. The Dim_Country wiki explicitly marks Region as Tier 2 (loaded via MarketingRegion JOIN in the SP), yet the writer claims Tier 1 from Dictionary.Country. No paraphrasing failures on actual Tier 1 columns.

Additionally, the lineage file marks Desk as Tier 1, while the wiki marks it Tier 2, and Dim_Country marks it Tier 3. The wiki's Tier 2 is the most defensible of the three but still generous.

---

### Dimension 2 — Upstream Fidelity: **5/10**

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer #1) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | **YES** | — |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." (Dim_Customer #7) | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | **YES** | — |
| PI_level | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration." (Dim_GuruStatus #2) | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus." | **MINOR** | Added "Passthrough from Dim_GuruStatus" — no semantic loss |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." (Dim_Country #4) | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country." | **MINOR** | Added "Passthrough from Dim_Country" — no semantic loss |
| Region | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping." (Dim_Country #6, **Tier 2**) | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Passthrough from Dim_Country." | **NO** | Dropped example values ("ROW", "Africa", "French", "Arabic Other"); dropped "Used for marketing campaign grouping"; wrong tier origin (claimed T1 Dictionary.Country, actually T2 in Dim_Country) |

CID and UserName are verbatim. PI_level and Country have trivial additions. Region has wrong tier origin AND paraphrasing with semantic loss (dropped examples and usage note). Score: 5 (1 paraphrased with semantic loss + wrong tier origin on Region).

---

### Dimension 3 — Completeness: **10/10**

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (32=32) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (~3,400 rows/day, 2020-01-01 to 2024-04-14) |
| Dictionary columns with <=15 values list inline values | YES (Classification 8 vals, TraderType 4 vals, PI/CP 2 vals, IsBlocked Yes/No) |
| review-needed.md does NOT contain ## 4. Elements | YES |

10/10 = score 10.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (PI Dashboard comparison), specifies row grain (one PI/CopyFund per date), names the ETL SP, states refresh pattern (DELETE+INSERT by Date), quantifies population (~3,391 rows on 2024-04-14: 3,215 PIs + 176 CopyFunds), gives exact date range, and describes the shadow-table caching pattern. The three-paragraph ETL explanation and side-effect note demonstrate deep understanding.

---

### Dimension 5 — Data Evidence: **7/10**

Positive: row count estimated (1,501 dates x ~3,400/day), date range stated, Classification distribution with percentages (2024-04-14), TraderType distribution with percentages, population breakdown (3,215 PIs + 176 CopyFunds). These suggest live data was queried.

Negative: DMV permission denied (review-needed #3), so row count is an estimate. Footer says "Phases: 11/14" but does not list which phases were completed. The distributions appear credible but cannot be fully verified without DMV access.

---

### Dimension 6 — Shape Fidelity: **9/10**

All structural elements match: numbered sections 1-8, tier legend in Section 4, real SQL samples in Section 7 (3 queries with correct table/column names), footer with quality score and phases, property table, lineage with production sources table + ETL pipeline diagram. Minor: no explicit Phase Gate Checklist section with [x] marks.

---

### Weighted Total

```
weighted = 0.25*7 + 0.20*5 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 1.75 + 1.00 + 2.00 + 1.35 + 0.70 + 0.90
         = 7.70
```

**Verdict: PASS** (7.70 >= 7.5)

---

### Top 5 Issues

1. **HIGH — Region: Wrong tier and dropped content.** Region is marked Tier 1 from Dictionary.Country, but Dim_Country wiki explicitly marks it Tier 2 (SP-computed from MarketingRegion JOIN). Description drops example values and "Used for marketing campaign grouping."

2. **MEDIUM — Desk: Tier inconsistency.** Lineage file says Tier 1, wiki says Tier 2, Dim_Country wiki says Tier 3. The wiki's Tier 2 is defensible but Tier 3 would match the dim's origin (Ext_Dim_Country_Region_Desk). Also drops NULL semantics and example values from upstream.

3. **LOW — Lineage file / wiki tier disagreement.** The lineage file marks Desk as Tier 1 and Region as Tier 1, but these don't match the upstream dim's tier classifications. Internal consistency between lineage file and wiki Elements table is also broken for Desk (lineage=1, wiki=2).

4. **LOW — Past_Year_Commission hardcoded date bug.** The SP's `#Past_Year_Commission` uses `WHERE ptc1.Date = '2021-03-14'` — this is flagged in review-needed but the wiki's Section 3.4 Gotchas only mentions "depends on BI_DB_PI_Dashboard having a prior-day row with a hardcoded date filter." The actual date should be called out explicitly in the Elements table description.

5. **LOW — Data staleness not in Section 1 summary.** The header block mentions the date range but the "Data stops at 2024-04-14" warning is only in Section 3.4 Gotchas, not in the Section 1 business meaning where an analyst would first look.

---

### Regeneration Feedback

1. Re-tag Region as `(Tier 2 — SP_Dictionaries_Country_DL_To_Synapse via Dim_Country)` and restore the dropped example values ("ROW", "Africa", "French", "Arabic Other") and "Used for marketing campaign grouping" from the Dim_Country wiki.
2. Re-tag Desk as `(Tier 3 — Ext_Dim_Country_Region_Desk via Dim_Country)` to match the upstream Dim_Country wiki's tier classification. Restore NULL semantics and example values.
3. Fix the lineage file to align tier values with the wiki Elements table (both Region and Desk).
4. Add explicit mention of the `'2021-03-14'` hardcoded date in the Past_Year_Commission element description.
5. Add a staleness warning to Section 1 noting data has not been refreshed since 2024-04-14.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide",
  "weighted_score": 7.70,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PI_level",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus.",
      "match": "MINOR",
      "loss": "Added 'Passthrough from Dim_GuruStatus' — no semantic loss"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.",
      "match": "MINOR",
      "loss": "Added 'Passthrough from Dim_Country' — no semantic loss"
    },
    {
      "column": "Region",
      "upstream_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)",
      "wiki_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country)",
      "match": "NO",
      "loss": "Dropped example values ('ROW', 'Africa', 'French', 'Arabic Other'); dropped 'Used for marketing campaign grouping'; wrong tier origin (claimed T1 Dictionary.Country, actually T2 in Dim_Country wiki)"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Region",
      "problem": "Tagged Tier 1 from Dictionary.Country but Dim_Country wiki marks Region as Tier 2 (SP-computed from MarketingRegion JOIN). Description drops example values and 'Used for marketing campaign grouping'."
    },
    {
      "severity": "medium",
      "column_or_section": "Desk",
      "problem": "Lineage file says Tier 1, wiki says Tier 2, Dim_Country wiki says Tier 3 (Ext_Dim_Country_Region_Desk). Wiki's Tier 2 is defensible but Tier 3 matches the dim's origin. Also drops NULL semantics and example values from upstream."
    },
    {
      "severity": "medium",
      "column_or_section": "Lineage file vs wiki",
      "problem": "Lineage file marks both Region and Desk as Tier 1 but the wiki Elements table has Region=T1 and Desk=T2. Internal inconsistency between lineage and wiki."
    },
    {
      "severity": "low",
      "column_or_section": "Past_Year_Commission",
      "problem": "The SP uses hardcoded date WHERE ptc1.Date = '2021-03-14'. This critical bug is mentioned in review-needed and Gotchas but should be explicit in the Elements description."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Data staleness (last refresh 2024-04-14, over 2 years ago) is only mentioned in Section 3.4 Gotchas, not in Section 1 where analysts first look."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag Region as Tier 2 from SP_Dictionaries_Country_DL_To_Synapse via Dim_Country, restoring dropped example values and 'Used for marketing campaign grouping'. (2) Re-tag Desk as Tier 3 from Ext_Dim_Country_Region_Desk via Dim_Country, matching upstream wiki. (3) Fix lineage file to align tier values with wiki Elements table. (4) Add '2021-03-14' hardcoded date to Past_Year_Commission element description. (5) Add staleness warning to Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "~3,400 rows per day",
      "1,501 daily snapshots",
      "3,215 PIs + 176 CopyFunds on 2024-04-14",
      "Classification distribution percentages",
      "TraderType distribution percentages"
    ],
    "skipped_phases": [
      "Phase 10 (Atlassian)"
    ]
  }
}
</JUDGE_VERDICT>
