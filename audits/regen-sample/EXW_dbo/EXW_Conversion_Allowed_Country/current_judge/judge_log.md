Let me verify whether upstream wikis for Dim_Country and Dim_State_and_Province exist in the repo before scoring.
Dim_Country and Dim_State_and_Province wikis exist. Let me read the relevant columns from them.
Now I have all the information needed for a thorough review. The Dim_Country and Dim_State_and_Province wikis exist in the repo — this is critical for tier accuracy assessment. Let me compile the full review.

---

## Adversarial Wiki Review: EXW_dbo.EXW_Conversion_Allowed_Country

### Dimension 1 — Tier Accuracy: **3/10**

I sampled 5 columns: Country, CountryID, RegionByIP_ID, CryptoID, FromConversionAllowed.

| Column | Wiki Tier | Correct Tier | Match? |
|--------|-----------|-------------|--------|
| Country | Tier 2 (SP) | **Tier 1 — Dictionary.Country** (dim-lookup passthrough via Dim_Country.Name, which is Tier 1 in the Dim_Country wiki) | NO |
| CountryID | Tier 2 (SP) | **Tier 1 — Dictionary.Country** (dim-lookup passthrough via Dim_Country.CountryID, Tier 1 in Dim_Country wiki) | NO |
| RegionByIP_ID | Tier 3 (inferred) | **Tier 1 — Dictionary.RegionByIP** (dim-lookup passthrough via Dim_State_and_Province.RegionByIP_ID, Tier 1 in that wiki) | NO |
| CryptoID | Tier 3 (inferred) | Tier 3 — no upstream wiki for crypto dimension | YES |
| FromConversionAllowed | Tier 2 (SP) | Tier 2 — CASE expression | YES |

3 mismatches out of 5 → base score 3. Plus paraphrasing failures on all 3 wrong-tier columns (descriptions are not verbatim upstream).

**Root cause**: The upstream bundle was empty ("NO UPSTREAM WIKI was resolvable"), but `DWH_dbo.Dim_Country` and `DWH_dbo.Dim_State_and_Province` wikis exist in the repo with high quality scores (8.8 and 8.0). The writer followed the bundle but the bundle was incomplete.

---

### Dimension 2 — Upstream Fidelity: **4/10**

The wiki claims **0 Tier 1 columns**. In reality, at least 3 columns should be Tier 1 (Country, CountryID, RegionByIP_ID) with a 4th candidate (StateProvince → Dim_State_and_Province.Name, Tier 2 in that wiki). Since the wiki declares no Tier 1 columns, there's nothing to fidelity-check against. But the wikis DO exist:

**Columns that should be Tier 1 with verbatim upstream descriptions:**

| Column | Upstream Wiki Description (verbatim) | Wiki Description | Match |
|--------|--------------------------------------|-----------------|-------|
| Country | Dim_Country #4 Name: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Country name from DWH_dbo.Dim_Country.Name. Text label for the country." | NO — paraphrased, lost "English", "Unique per row", usage context |
| CountryID | Dim_Country #1 CountryID: "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code." | "DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state." | NO — lost 0=Not available sentinel, lost 1-250 range, fabricated "For US, one row per state" context |
| RegionByIP_ID | Dim_State_and_Province #1: "Primary join key. Auto-incrementing surrogate PK from `Dictionary.RegionByIP` (IDENTITY NOT FOR REPLICATION). Stored in `Customer.CustomerStatic.RegionByIP_ID` and used to identify the sub-country region detected from a customer's IP address at registration." | "Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries." | NO — lost Dictionary.RegionByIP origin, lost IDENTITY semantics, lost CustomerStatic reference |

Three missed Tier 1 inheritances with paraphrased descriptions. Score: 4 (wikis exist but weren't in bundle — partial mitigation).

---

### Dimension 3 — Completeness: **4/10**

| Check | Pass? | Detail |
|-------|-------|--------|
| All 8 sections present | YES | Sections 1-8 all present |
| Element count = DDL count | YES | 21/21 |
| Every element row has 5 cells | YES | All 21 rows have 5 cells |
| Every description ends with (Tier N — source) | YES | All 21 do |
| Property table has required fields | YES | Writer SP, Refresh, Distribution, UC Target all present |
| Section 5.2 ETL pipeline ASCII diagram | **NO** | Wiki only has 5.1 table; no ASCII pipeline diagram |
| Footer has tier breakdown counts | YES | Present |
| Section 1 has row count and date range | **NO** | Neither row count nor date range |
| Dictionary columns ≤15 values list inline | **NO** | FromConversionAllowed/ToConversionAllowed (all 0) not listed inline |
| .review-needed does NOT contain ## 4. Elements | YES | Clean |

7/10 → score 4.

**Critical additional finding — 16 DDL type mismatches not in checklist:**

| Column | DDL | Wiki Claims | Error |
|--------|-----|-------------|-------|
| Country | `varchar(50)` | `nvarchar(100)` | Wrong type AND length |
| StateProvince | `varchar(100)` | `nvarchar(100)` | varchar→nvarchar |
| CryptoID | `int NOT NULL` | `int YES` | **Nullable WRONG** |
| Crypto | `nvarchar(256)` | `nvarchar(100)` | Length shrunk 256→100 |
| AllowedUserResource | `nvarchar(100)` | `nvarchar(200)` | Length inflated |
| AllowedUserTagType | `nvarchar(50)` | `nvarchar(100)` | Length inflated |
| AllowedUserTagValue | `nvarchar(50)` | `nvarchar(200)` | Length inflated |
| AllowedUserSelectedValue | `nvarchar(50)` | `nvarchar(100)` | Length inflated |
| FromResourceName | `nvarchar(100)` | `nvarchar(200)` | Length inflated |
| FromTagType | `nvarchar(50)` | `nvarchar(100)` | Length inflated |
| FromTagValue | `nvarchar(50)` | `nvarchar(200)` | Length inflated |
| FromSelectedValue | `nvarchar(50)` | `nvarchar(100)` | Length inflated |
| ToResourceName | `nvarchar(100)` | `nvarchar(200)` | Length inflated |
| ToTagType | `nvarchar(50)` | `nvarchar(100)` | Length inflated |
| ToTagValue | `nvarchar(50)` | `nvarchar(200)` | Length inflated |
| ToSelectedValue | `nvarchar(50)` | `nvarchar(100)` | Length inflated |

16 of 21 columns have wrong types. The writer systematically inflated string lengths and converted varchar to nvarchar. CryptoID is `NOT NULL` in the DDL but the wiki says nullable. This is catastrophic for any analyst relying on the Elements table for schema information.

---

### Dimension 4 — Business Meaning: **7/10**

Section 1 is genuinely good. It explains directional conversion (From/To), the three eligibility levels, the current state (all 0, discontinued), and the audit/reactivation rationale. An analyst can immediately understand the table's purpose and current relevance.

Missing: row count and date range. ETL SP name is in the property table but not in the Section 1 narrative.

---

### Dimension 5 — Data Evidence: **4/10**

- No row count in Section 1
- No date range
- "All values are 0" is stated but could be inferred from settings logic alone
- Footer says "Phases: 13/14" but no Phase Gate Checklist with P2/P3 checkboxes visible
- No distribution analysis or NULL-rate claims

---

### Dimension 6 — Shape Fidelity: **7/10**

Numbered sections 1-8 present. Tier legend in Section 4. Real SQL in Section 7. Footer has quality score and tier counts. Missing: Section 5.2 ETL pipeline diagram (only 5.1 table exists). Minor: no phases-completed breakdown in footer beyond "13/14".

---

### Weighted Total

```
weighted = 0.25×3 + 0.20×4 + 0.20×4 + 0.15×7 + 0.10×4 + 0.10×7
         = 0.75 + 0.80 + 0.80 + 1.05 + 0.40 + 0.70
         = 4.50
```

**Verdict: FAIL**

---

### T1 Fidelity Table

The wiki claims 0 Tier 1 columns, but 3 columns should be Tier 1. Showing should-be-T1 columns:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| Country | Dim_Country #4: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki)" | "Country name from DWH_dbo.Dim_Country.Name. Text label for the country. (Tier 2 — SP_EXW_WalletElligibleCountries)" | NO | Wrong tier (2→1), paraphrased, lost "English", "Unique per row", usage context, wrong origin |
| CountryID | Dim_Country #1: "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. (Tier 1 - Dictionary.Country upstream wiki)" | "DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries)" | NO | Wrong tier (2→1), lost 0=sentinel, lost 1-250 range, wrong origin (should be Dictionary.Country) |
| RegionByIP_ID | Dim_State_and_Province #1: "Primary join key. Auto-incrementing surrogate PK from `Dictionary.RegionByIP` (IDENTITY NOT FOR REPLICATION). Stored in `Customer.CustomerStatic.RegionByIP_ID`. (Tier 1 — Dictionary.RegionByIP)" | "Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries. (Tier 3 — inferred)" | NO | Wrong tier (3→1), lost Dictionary.RegionByIP origin, lost IDENTITY semantics, lost CustomerStatic FK |

---

### Top 5 Issues

1. **HIGH — 16/21 columns have wrong data types**: The writer systematically inflated string lengths (nvarchar(50)→100/200) and converted varchar to nvarchar. CryptoID is NOT NULL in DDL but wiki says nullable. An analyst trusting the Elements table will have wrong schema assumptions.

2. **HIGH — Country, CountryID tagged Tier 2 instead of Tier 1**: Both are dim-lookup passthroughs from Dim_Country, which documents them as Tier 1 from Dictionary.Country. Descriptions are paraphrased instead of verbatim. CountryID lost the 0=Not available sentinel.

3. **HIGH — RegionByIP_ID tagged Tier 3 instead of Tier 1**: Dim-lookup passthrough from Dim_State_and_Province.RegionByIP_ID, which is Tier 1 from Dictionary.RegionByIP. Description completely rewrites the upstream meaning.

4. **MEDIUM — No row count or date range in Section 1**: Business meaning is otherwise good but lacks the quantitative grounding needed for completeness.

5. **MEDIUM — No ETL pipeline ASCII diagram**: Section 5 only has a source table (5.1) with no 5.2 pipeline diagram. The lineage file has one, but the wiki itself does not.

---

### Regeneration Feedback

1. Fix all 16 DDL type mismatches — use the actual DDL types verbatim: `varchar(50)` not `nvarchar(100)` for Country, `NOT NULL` for CryptoID, `nvarchar(256)` for Crypto, `nvarchar(50)` not `nvarchar(100)` for tag columns, etc.
2. Re-tag Country and CountryID as `(Tier 1 — Dictionary.Country)` using verbatim descriptions from the Dim_Country wiki (elements #4 and #1).
3. Re-tag RegionByIP_ID as `(Tier 1 — Dictionary.RegionByIP)` using the verbatim description from Dim_State_and_Province wiki (element #1).
4. Re-tag StateProvince as `(Tier 2 — SP_Dictionaries_DL_To_Synapse via Dim_State_and_Province)` since the Dim_State_and_Province.Name column is Tier 2.
5. Add row count and date range (from UpdateDate) to Section 1.
6. Add Section 5.2 ETL pipeline ASCII diagram to the wiki (not just the lineage file).
7. List inline values for FromConversionAllowed and ToConversionAllowed (currently only `0`).
8. Ensure the upstream bundle includes Dim_Country and Dim_State_and_Province wikis for the next run.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_Conversion_Allowed_Country",
  "weighted_score": 4.50,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 4,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 4,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki)",
      "wiki_quote": "Country name from DWH_dbo.Dim_Country.Name. Text label for the country. (Tier 2 — SP_EXW_WalletElligibleCountries)",
      "match": "NO",
      "loss": "Wrong tier (2 instead of 1). Paraphrased: lost 'English', 'Unique per row', usage context. Wrong origin (should be Dictionary.Country, not SP)."
    },
    {
      "column": "CountryID",
      "upstream_quote": "Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. (Tier 1 - Dictionary.Country upstream wiki)",
      "wiki_quote": "DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries)",
      "match": "NO",
      "loss": "Wrong tier (2 instead of 1). Lost 0=Not available sentinel, lost 1-250 range. Wrong origin (should be Dictionary.Country)."
    },
    {
      "column": "RegionByIP_ID",
      "upstream_quote": "Primary join key. Auto-incrementing surrogate PK from Dictionary.RegionByIP (IDENTITY NOT FOR REPLICATION). Stored in Customer.CustomerStatic.RegionByIP_ID and used to identify the sub-country region detected from a customer's IP address at registration. (Tier 1 — upstream wiki, Dictionary.RegionByIP)",
      "wiki_quote": "Geographic region identifier from Dim_State_and_Province.RegionByIP_ID for US states; NULL for non-US countries. (Tier 3 — inferred)",
      "match": "NO",
      "loss": "Wrong tier (3 instead of 1). Lost Dictionary.RegionByIP origin, IDENTITY semantics, CustomerStatic FK reference. Completely rewritten description."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "16 of 21 columns (Country, StateProvince, CryptoID, Crypto, AllowedUserResource, AllowedUserTagType, AllowedUserTagValue, AllowedUserSelectedValue, FromResourceName, FromTagType, FromTagValue, FromSelectedValue, ToResourceName, ToTagType, ToTagValue, ToSelectedValue)",
      "problem": "DDL type mismatches: varchar(50) written as nvarchar(100) for Country, varchar(100) as nvarchar(100) for StateProvince, nvarchar(256) shrunk to nvarchar(100) for Crypto, CryptoID NOT NULL shown as nullable, and 12 tag/resource columns have inflated lengths (nvarchar(50)→100/200, nvarchar(100)→200). An analyst trusting the Elements table will have wrong schema assumptions."
    },
    {
      "severity": "high",
      "column_or_section": "Country, CountryID",
      "problem": "Tagged Tier 2 (SP_EXW_WalletElligibleCountries) but these are dim-lookup passthroughs from Dim_Country, which documents them as Tier 1 from Dictionary.Country. Descriptions are paraphrased. CountryID lost the 0=Not available sentinel value."
    },
    {
      "severity": "high",
      "column_or_section": "RegionByIP_ID",
      "problem": "Tagged Tier 3 (inferred) but is a dim-lookup passthrough from Dim_State_and_Province.RegionByIP_ID, which is Tier 1 from Dictionary.RegionByIP. Description completely rewritten — lost upstream origin, IDENTITY semantics, and CustomerStatic FK reference."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "No row count or date range. Business meaning is otherwise good but lacks quantitative grounding."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No Section 5.2 ETL pipeline ASCII diagram. Only a 5.1 source table is present. The lineage file has a pipeline diagram but the wiki itself does not."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix all 16 DDL type mismatches — use DDL types verbatim: varchar(50) for Country, NOT NULL for CryptoID, nvarchar(256) for Crypto, nvarchar(50) for all tag columns, nvarchar(100) for resource columns. (2) Re-tag Country and CountryID as Tier 1 — Dictionary.Country using verbatim descriptions from Dim_Country wiki elements #4 and #1. (3) Re-tag RegionByIP_ID as Tier 1 — Dictionary.RegionByIP using verbatim description from Dim_State_and_Province wiki element #1. (4) Re-tag StateProvince as Tier 2 since Dim_State_and_Province.Name is Tier 2. (5) Add row count and date range to Section 1. (6) Add Section 5.2 ETL pipeline ASCII diagram. (7) List inline values for FromConversionAllowed and ToConversionAllowed. (8) Ensure upstream bundle includes Dim_Country and Dim_State_and_Province wikis.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["AllowedUserSelectedValue: 'Currently false for all rows'", "FromSelectedValue: 'Currently false for all rows'", "ToSelectedValue: 'Currently false for all rows'", "FromConversionAllowed: 'Currently 0 for all rows'", "ToConversionAllowed: 'Currently 0 for all rows'"],
    "skipped_phases": ["P2 and P3 not explicitly shown in Phase Gate Checklist — footer claims 13/14 but no visible checklist"]
  }
}
</JUDGE_VERDICT>
