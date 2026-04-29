# Adversarial Review: DWH_dbo.Fact_Deposit_Fees

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: **3/10**
Sampled 5 columns. The SP code (`SP_Fact_Deposit_Fees_DL_To_Synapse`) is a flat `SELECT ... FROM staging` — every column except `ModificationDateID` and `UpdateDate` is a passthrough visible in SP source. Yet the writer inconsistently tags identical passthroughs: `CID` gets Tier 2, `DepositValueDate` gets Tier 4, `Regulation` gets Tier 3, `BaseExchangeRate` gets Tier 4. Three out of five sampled columns carry the wrong tier.

| Column | Wiki Tier | Correct Tier | Match? |
|--------|-----------|-------------|--------|
| CID | Tier 2 (SP passthrough) | Tier 2 | YES |
| ModificationDateID | Tier 2 (SP computed) | Tier 2 | YES |
| DepositValueDate | Tier 4 (Confluence) | Tier 2 (SP passthrough) | NO |
| BaseExchangeRate | Tier 4 (Confluence) | Tier 2 (SP passthrough) | NO |
| Regulation | Tier 3 (live data) | Tier 2 (SP passthrough) | NO |

The writer seems to have assigned tiers based on *where they found the description content* rather than *where the column transform is documented*. If the SP shows it's a passthrough, the tier is Tier 2 regardless of whether Confluence was consulted to enrich the prose.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)
The upstream bundle explicitly states: "NO UPSTREAM WIKI was resolvable." The wiki correctly reports 0 Tier 1 columns. No missed inheritance is possible since no upstream wikis exist. Neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained no resolvable wikis. Table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (8 of 10 checks pass)
Failures:
- **Element count mismatch**: DDL has 47 columns. Wiki lists 49 element rows with rows 48-49 as "duplicates." The wiki text then claims "the actual table has 49 unique columns as defined in the DDL" — factually wrong.
- **Dictionary inline values**: DepositStatus (9 values) is listed in the element description, which is good. But other low-cardinality columns (e.g., `FTD`, `CardCategory`) don't list values inline in the Elements table despite likely having ≤15 distinct values.

### Dimension 4 — Business Meaning: **9/10**
Section 1 is excellent: specific domain (deposit fee analysis), row grain (deposit event at final status), row count (14.4M), date range (2020-03-05 to 2024-06-30), ETL SP named, pipeline status (STOPPED with specific date), source origin explained including underlying production tables. An analyst can immediately understand what this table is and whether it's useful.

### Dimension 5 — Data Evidence: **7/10**
Row count (14,429,422 total from status distribution), date range, specific value distributions for DepositStatus/FundingMethod/Regulation are present and appear genuine. NULL behavior mentioned for PIPsinUSD. Footer says "Phases: 13/14" but no explicit Phase Gate Checklist with P2/P3 checkboxes is shown in the wiki body. Data claims appear credible but the phase evidence is indirect.

### Dimension 6 — Shape Fidelity: **7/10**
Numbered sections 1-8 present. Tier legend in Section 4. Real SQL in Section 7. Footer has quality score and tier breakdown. Deductions: duplicate element rows (48-49) break the clean shape; Section 8 is "Atlassian Knowledge Sources" rather than the standard section title; no explicit Phase Gate Checklist section.

---

## Top 5 Issues

1. **HIGH — Systematic tier misassignment across ~20 columns.** Columns like `DepositValueDate`, `BaseExchangeRate`, `ExchangeRate`, `DepositCollarAmount`, `CountryByRegIP`, `CardCategory`, `FTD`, `CustomerLevel` are tagged Tier 4 (Confluence-inferred) despite being visible as direct passthroughs in the SP code → should be Tier 2. Similarly, `DepositStatus`, `FundingMethod`, `Depot`, `Threedsresponse`, `Regulation`, `WhiteLabel`, `Brand` are tagged Tier 3 (live data) when they're SP passthroughs → Tier 2.

2. **HIGH — Duplicate element rows 48-49 (Depot, AccountManager).** The wiki lists these twice, inflating the count to 49 and then incorrectly claims "the actual table has 49 unique columns." DDL has 47 columns.

3. **MEDIUM — Inconsistent tier logic.** `CID` and `DepositID` are tagged Tier 2 as "SP passthrough" while `DepositAmount` and `Currency` — identical passthroughs in the same SELECT — are also Tier 2, but `FundingMethod` (also identical passthrough) is Tier 3. No principled distinction exists.

4. **MEDIUM — No Phase Gate Checklist.** The footer references "Phases: 13/14" but the wiki body contains no Phase Gate Checklist section with explicit P2/P3 checkboxes, making it impossible to verify which phases were actually completed.

5. **LOW — `CustomerLevel` tagged Tier 4 (inferred) with `[UNVERIFIED]`.** The writer had Confluence documentation about eToro Club tiers (Bronze/Silver/Gold/Platinum/Diamond) AND the SP shows it as a passthrough. This should be Tier 2 at minimum, not Tier 4 with an UNVERIFIED flag.

---

## Regeneration Feedback

1. **Re-tier all 45 passthrough columns to Tier 2** — the SP source code shows every column except `ModificationDateID` and `UpdateDate` is a direct `SELECT col FROM staging` passthrough. Use `(Tier 2 — SP_Fact_Deposit_Fees_DL_To_Synapse passthrough from BackOffice.BillingDepositsPCIVersion)` consistently. Reserve Tier 3 only for columns where the SP does NOT list them (none in this case). Reserve Tier 4 only for columns not visible in SP at all (none here — all 45 are in the INSERT list).
2. **Remove duplicate element rows 48-49** and correct the count claim to 47 columns matching the DDL.
3. **Add a Phase Gate Checklist section** with explicit P2/P3 checkboxes so data evidence claims are auditable.
4. **List inline values for low-cardinality columns** (`FTD`, `CardCategory`, `CustomerLevel`, `DepositType`) in the Elements table descriptions where data was sampled.
5. **Enrich Tier 2 descriptions with Confluence knowledge** — being Tier 2 doesn't prevent including rich domain context from Confluence; the tier reflects the *confidence source* (SP code), not a ceiling on description quality.

---

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Fact_Deposit_Fees",
  "weighted_score": 6.60,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "DepositValueDate, BaseExchangeRate, ExchangeRate, DepositCollarAmount, CountryByRegIP, CardCategory, FTD, CustomerLevel, DepositStatus, FundingMethod, Depot, Threedsresponse, Regulation, WhiteLabel, Brand",
      "problem": "~20 columns tagged Tier 3 or Tier 4 despite being direct passthroughs visible in SP_Fact_Deposit_Fees_DL_To_Synapse SELECT list. All 45 non-computed columns should be Tier 2 (SP passthrough). Writer assigned tier based on description enrichment source (Confluence/live data) rather than transformation confidence source (SP code)."
    },
    {
      "severity": "high",
      "column_or_section": "Section 4 Elements rows 48-49",
      "problem": "Duplicate element rows for Depot and AccountManager. Wiki claims '49 unique columns as defined in the DDL' but DDL has 47 columns. Element count does not match DDL."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 Elements (tier consistency)",
      "problem": "Inconsistent tier application: CID and DepositID are Tier 2 (SP passthrough) while FundingMethod, DepositStatus, Regulation — identical passthroughs in the same SELECT — are Tier 3 (live data). No principled distinction."
    },
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist (missing)",
      "problem": "Footer says 'Phases: 13/14' but no Phase Gate Checklist section exists in the wiki body. Cannot verify which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "CustomerLevel",
      "problem": "Tagged Tier 4 [UNVERIFIED] despite Confluence documentation of eToro Club tiers AND SP code showing it as a passthrough. Should be Tier 2 with Confluence-enriched description."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tier all 45 passthrough columns to Tier 2 — SP source shows every column except ModificationDateID and UpdateDate as SELECT col FROM staging. Use consistent tag: '(Tier 2 — SP_Fact_Deposit_Fees_DL_To_Synapse passthrough from BackOffice.BillingDepositsPCIVersion)'. (2) Remove duplicate element rows 48-49 (Depot, AccountManager) and fix count to 47 matching DDL. (3) Add explicit Phase Gate Checklist section with P2/P3 checkboxes. (4) List inline values for low-cardinality columns (FTD, CardCategory, CustomerLevel, DepositType) in Elements descriptions. (5) Confluence knowledge should enrich Tier 2 descriptions — tier reflects confidence source, not description ceiling.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "DepositStatus distribution (14,412,657 Approved, 9,263 Refund, etc.)",
      "FundingMethod distribution (CreditCard 63.3%, PayPal 17.6%, etc.)",
      "Regulation distribution (CySEC 53.5%, FCA 30.8%, etc.)",
      "Row count 14.4M, date range 2020-03-05 to 2024-06-30"
    ],
    "skipped_phases": ["Phase Gate Checklist section not present in wiki body"]
  }
}
</JUDGE_VERDICT>
