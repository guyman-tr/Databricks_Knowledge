I need to verify whether upstream wikis for Dim_Country and Dim_State_and_Province exist in the repo, since the bundle claims none were resolvable. Let me also check the DDL types carefully against the wiki.
Dim_Country and Dim_State_and_Province wikis DO exist. The bundle incorrectly claims no upstream wiki was resolvable. Let me read the relevant upstream wikis to check what should have been inherited as Tier 1.
Now let me verify the SP source to understand the actual lineage better.
Now I have all the information needed for a thorough review. Let me compile the findings.

---

## Adversarial Review: EXW_dbo.EXW_Payment_Allowed_Country

### Dimension 1 — Tier Accuracy: **3/10**

Five random columns sampled:

| Column | Expected Tier | Wiki Tier | Correct? |
|--------|--------------|-----------|----------|
| CountryID | Tier 1 (Dictionary.Country, via Dim_Country wiki) | Tier 2 | NO |
| Country | Tier 1 (Dictionary.Country, via Dim_Country wiki — Name column) | Tier 2 | NO |
| StateProvince | Tier 1 (Dim_State_and_Province.Name — wiki exists) | Tier 3 | NO |
| RegionByIP_ID | Tier 1 (Dim_State_and_Province — Tier 1 in upstream wiki) | Tier 3 | NO |
| PaymentAllowed | Tier 2 (CASE WHEN computed) | Tier 2 | YES |

4/5 mismatches = score 3. CountryID and Country are dim-lookup passthroughs from Dim_Country, which has a published wiki documenting CountryID as Tier 1 from Dictionary.Country and Name as Tier 1 from Dictionary.Country. StateProvince is a passthrough from Dim_State_and_Province.Name (documented in that wiki). RegionByIP_ID is explicitly Tier 1 in the Dim_State_and_Province wiki. The writer tagged all of these as Tier 2 or Tier 3, missing the inheritance chain entirely.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

The upstream bundle provided to the writer contained **zero** upstream wikis ("NO UPSTREAM WIKI was resolvable"). Per the rubric, this is the neutral case (score 7). However, I verified that both `DWH_dbo.Dim_Country` and `DWH_dbo.Dim_State_and_Province` have published wikis in the repo at `knowledge/synapse/Wiki/DWH_dbo/Tables/`. The bundle preparation was faulty — it should have resolved these. The wiki consequently has **0 Tier 1 columns** when it should have at least 4.

### T1 Fidelity Table

The wiki claims 0 Tier 1 columns, so there are no T1 descriptions to compare. The following columns **should** have been Tier 1 with verbatim upstream quotes:

| Column | Should-be Upstream | Wiki Description | Match | Loss |
|--------|-------------------|-----------------|-------|------|
| CountryID | Dim_Country: "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code." | "DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key." | NO | Entire upstream description dropped. Sentinel value 0, range 1-250, referenced-by list all lost. Tagged Tier 2 instead of Tier 1. |
| Country | Dim_Country.Name: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Country name from DWH_dbo.Dim_Country.Name. Text label for the country whose payment eligibility is represented." | NO | Upstream description replaced with generic paraphrase. "Unique per row" and usage context dropped. Tagged Tier 2 instead of Tier 1. |
| StateProvince | Dim_State_and_Province.Name: "Full human-readable geographic name of the region — state, province, or territory. Sourced from Dictionary.RegionName.Name. Examples: California, New York, Ontario." | "US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for other countries." | NO | Examples dropped, production source (Dictionary.RegionName) lost, described as "US state" narrowing scope from full description. Tagged Tier 3 instead of Tier 1. |
| RegionByIP_ID | Dim_State_and_Province: "Primary join key. Auto-incrementing surrogate PK from Dictionary.RegionByIP (IDENTITY NOT FOR REPLICATION). Stored in Customer.CustomerStatic.RegionByIP_ID." | "Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries." | NO | Entire upstream description dropped: identity semantics, customer usage context, Dictionary.RegionByIP origin. Tagged Tier 3 instead of Tier 1. |

### Dimension 3 — Completeness: **4/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL column count (16/16) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | **NO** — wiki Section 5 has only a production sources table, no 5.2 pipeline diagram |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | **NO** — neither row count nor date range |
| Dictionary columns with ≤15 values list inline key=value pairs | **NO** — PaymentAllowed {0,1} not listed as key=value |
| .review-needed.md does NOT contain ## 4. Elements | YES |

7/10 = score 4.

**Critical additional issue: 11 of 16 columns have incorrect data types in the wiki vs. DDL:**

| Column | DDL Type | Wiki Type |
|--------|----------|-----------|
| Country | varchar(50) | nvarchar(100) |
| StateProvince | varchar(100) | nvarchar(100) |
| Crypto | nvarchar(256) | nvarchar(100) |
| AllowedUserResource | nvarchar(100) | nvarchar(200) |
| AllowedUserTagType | nvarchar(50) | nvarchar(100) |
| AllowedUserTagValue | nvarchar(50) | nvarchar(200) |
| AllowedUserSelectedValue | nvarchar(50) | nvarchar(100) |
| CryptosResourceName | nvarchar(100) | nvarchar(200) |
| CryptosTagType | nvarchar(50) | nvarchar(100) |
| CryptosTagValue | nvarchar(50) | nvarchar(200) |
| CryptosSelectedValue | nvarchar(50) | nvarchar(100) |

### Dimension 4 — Business Meaning: **7/10**

Section 1 is specific and actionable: names the domain (Simplex crypto payment eligibility), the row grain (country/crypto combination), the dual-condition design (AllowedUser AND Cryptos), and the current state (all 0, discontinued). It correctly identifies the writer SP. Missing: row count and date range. Also does not mention that as of 2026-04-14, the SP comment history states the payment section was **removed** from the SP — the table is orphaned and will never be refreshed again, which is a stronger statement than "discontinued."

### Dimension 5 — Data Evidence: **4/10**

No row count. No date range. No NULL-rate analysis. No Phase Gate Checklist visible. The wiki claims "Currently 0 for all rows" and "Currently 'false' for all rows" but provides no evidence source for these claims (no P2/P3 phase markers). The footer says "Phases: 13/14" without specifying which phases were completed. The Crypto source is identified only as "crypto lookup dimension" — the actual source is `EXW_Wallet.CryptoTypes` (visible in SP line 999).

### Dimension 6 — Shape Fidelity: **7/10**

Numbered sections present. Tier legend in Section 4. Real SQL samples in Section 7. Footer format includes quality score and phase count. Minor deviations: no 5.2 subsection, no Phase Gate Checklist table, tier legend missing the stars column from the golden reference.

### Weighted Score

```
weighted = 0.25*3 + 0.20*7 + 0.20*4 + 0.15*7 + 0.10*4 + 0.10*7
         = 0.75 + 1.40 + 0.80 + 1.05 + 0.40 + 0.70
         = 5.10
```

**Verdict: FAIL**

### Top 5 Issues

1. **HIGH — 11/16 columns have fabricated data types**: Country, Crypto, and all 8 Settings-derived columns have wrong types/lengths vs. DDL. The writer appears to have guessed lengths rather than reading the DDL.

2. **HIGH — 4 columns mis-tiered (CountryID, Country, StateProvince, RegionByIP_ID)**: These are dim-lookup passthroughs from Dim_Country and Dim_State_and_Province, both of which have published wikis. Should be Tier 1 with verbatim upstream descriptions, not Tier 2/3.

3. **HIGH — Upstream bundle gap**: The bundle claimed no upstream wikis were resolvable, but Dim_Country.md and Dim_State_and_Province.md both exist. This caused a cascade failure: 0 Tier 1 columns where there should be 4+.

4. **MEDIUM — SP no longer writes this table**: The SP change history (2026-04-14) explicitly removes the payment, staking, and conversion sections. The wiki says "Full refresh (TRUNCATE + INSERT)" but the table is now orphaned — it will never be refreshed. This should be flagged prominently.

5. **MEDIUM — Missing row count, date range, ETL pipeline diagram**: Section 1 lacks data evidence. Section 5 lacks a 5.2 ETL pipeline ASCII diagram. CryptoID/Crypto source identified only as "crypto lookup dimension" instead of the actual `EXW_Wallet.CryptoTypes`.

### Regeneration Feedback

1. Fix all 11 data type mismatches — read the DDL and use exact types: `Country varchar(50)`, `Crypto nvarchar(256)`, `AllowedUserResource nvarchar(100)`, etc.
2. Re-tag CountryID as `(Tier 1 — Dictionary.Country)` using verbatim description from Dim_Country wiki: "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code."
3. Re-tag Country as `(Tier 1 — Dictionary.Country)` using Dim_Country.Name verbatim: "Full country name in English. Unique per row."
4. Re-tag StateProvince as `(Tier 1 — Dim_State_and_Province)` using the Name description verbatim from that wiki.
5. Re-tag RegionByIP_ID as `(Tier 1 — Dictionary.RegionByIP)` using the Dim_State_and_Province wiki verbatim.
6. Update Refresh property to note the SP payment section was removed (2026-04-14) — table is orphaned, not actively refreshed.
7. Add Section 5.2 ETL pipeline ASCII diagram showing Dim_Country + Dim_State_and_Province + EXW_Wallet.CryptoTypes + EXW_Settings flow.
8. Name the crypto source explicitly as `EXW_Wallet.CryptoTypes` (not "crypto lookup dimension").
9. Add row count and date range to Section 1 (requires P2 live query).
10. Add inline key=value for PaymentAllowed: `0 = payment not allowed, 1 = payment allowed`.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_Payment_Allowed_Country",
  "weighted_score": 5.10,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 7,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 4,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "CountryID",
      "upstream_quote": "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki)",
      "wiki_quote": "DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries)",
      "match": "NO",
      "loss": "Entire Tier 1 upstream description dropped. Sentinel value 0, range 1-250, referenced-by list all lost. Wrong tier (Tier 2 instead of Tier 1)."
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki)",
      "wiki_quote": "Country name from DWH_dbo.Dim_Country.Name. Text label for the country whose payment eligibility is represented. (Tier 2 — SP_EXW_WalletElligibleCountries)",
      "match": "NO",
      "loss": "Upstream description replaced with generic paraphrase. 'Unique per row' and usage context dropped. Wrong tier (Tier 2 instead of Tier 1)."
    },
    {
      "column": "StateProvince",
      "upstream_quote": "Full human-readable geographic name of the region — state, province, or territory. Sourced from Dictionary.RegionName.Name. Examples: \"California\", \"New York\", \"Ontario\". Used in reporting to display readable geographic labels. (Tier 2 — SP_Dictionaries_DL_To_Synapse)",
      "wiki_quote": "US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for other countries. (Tier 3 — inferred)",
      "match": "NO",
      "loss": "Examples dropped, production source (Dictionary.RegionName) lost, narrowed from 'state, province, or territory' to 'US state'. Wrong tier (Tier 3 instead of Tier 1)."
    },
    {
      "column": "RegionByIP_ID",
      "upstream_quote": "Primary join key. Auto-incrementing surrogate PK from Dictionary.RegionByIP (IDENTITY NOT FOR REPLICATION). Stored in Customer.CustomerStatic.RegionByIP_ID and used to identify the sub-country region detected from a customer's IP address at registration. (Tier 1 — upstream wiki, Dictionary.RegionByIP)",
      "wiki_quote": "Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries. (Tier 3 — inferred)",
      "match": "NO",
      "loss": "Entire upstream description dropped: identity semantics, customer usage context, Dictionary.RegionByIP origin. Wrong tier (Tier 3 instead of Tier 1)."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Country, Crypto, AllowedUserResource, AllowedUserTagType, AllowedUserTagValue, AllowedUserSelectedValue, CryptosResourceName, CryptosTagType, CryptosTagValue, CryptosSelectedValue, StateProvince",
      "problem": "11 of 16 columns have fabricated data types. DDL says Country is varchar(50), wiki says nvarchar(100). DDL says Crypto is nvarchar(256), wiki says nvarchar(100). All 8 Settings-derived columns have inflated lengths (e.g., DDL nvarchar(50) → wiki nvarchar(100) or nvarchar(200)). StateProvince is varchar(100) in DDL but nvarchar(100) in wiki."
    },
    {
      "severity": "high",
      "column_or_section": "CountryID, Country, StateProvince, RegionByIP_ID",
      "problem": "All four dim-lookup passthrough columns are mis-tiered. CountryID and Country should be Tier 1 (Dictionary.Country, via Dim_Country wiki). StateProvince and RegionByIP_ID should be Tier 1 (via Dim_State_and_Province wiki). Writer tagged them Tier 2 and Tier 3 respectively."
    },
    {
      "severity": "high",
      "column_or_section": "Upstream bundle",
      "problem": "Bundle claimed no upstream wikis were resolvable, but DWH_dbo.Dim_Country.md and DWH_dbo.Dim_State_and_Province.md both exist in the repo. This caused 0 Tier 1 columns where there should be at least 4."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1, Property table (Refresh)",
      "problem": "SP change history (2026-04-14) explicitly removes payment, staking, and conversion sections. Table is orphaned — will never be refreshed again. Wiki says 'Full refresh (TRUNCATE + INSERT)' which is now false. Should say 'Orphaned — SP payment section removed 2026-04-14'."
    },
    {
      "severity": "medium",
      "column_or_section": "CryptoID, Crypto",
      "problem": "Crypto source identified only as 'crypto lookup dimension' and 'Crypto dimension (no upstream wiki)'. Actual source is EXW_Wallet.CryptoTypes (SP lines 995-999). Writer failed to trace the source table."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5, Section 1",
      "problem": "Missing Section 5.2 ETL pipeline ASCII diagram. Missing row count and date range in Section 1. Missing inline key=value for PaymentAllowed {0=not allowed, 1=allowed}."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix all 11 data type mismatches — read DDL exactly: Country varchar(50), Crypto nvarchar(256), AllowedUserResource nvarchar(100), AllowedUserTagType nvarchar(50), etc. (2) Re-tag CountryID and Country as Tier 1 (Dictionary.Country) using verbatim descriptions from Dim_Country wiki. (3) Re-tag StateProvince and RegionByIP_ID as Tier 1 using verbatim descriptions from Dim_State_and_Province wiki. (4) Update Refresh to note SP payment section removed 2026-04-14 — table is orphaned. (5) Name crypto source as EXW_Wallet.CryptoTypes explicitly. (6) Add Section 5.2 ETL pipeline diagram. (7) Add row count and date range to Section 1. (8) Add inline key=value for PaymentAllowed. (9) Include upstream bundle with Dim_Country and Dim_State_and_Province wikis in next run.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "PaymentAllowed: 'Currently 0 for all rows' — no P2 evidence",
      "AllowedUserSelectedValue: 'Currently false for all rows' — no P2 evidence",
      "CryptosSelectedValue: 'Currently false for all rows' — no P2 evidence"
    ],
    "skipped_phases": [
      "P2 (live data sampling) — no row count or date range",
      "P3 (distribution analysis) — no NULL-rate or value distribution"
    ]
  }
}
</JUDGE_VERDICT>
