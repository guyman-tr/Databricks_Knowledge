# BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard — Review Needed

*Generated: 2026-04-28*

---

## Items Requiring Human Review

### 1. RiskScoreName source — unresolved wiki (Tier 3)

**Column**: `RiskScoreName`
**Source**: `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake`
**Issue**: No upstream wiki found for `External_RiskClassification_dbo_V_RiskClassificationDataLake`. The object is a LEFT JOIN source on `CID` that supplies the `RiskScoreName` column. Live data shows three values: Medium (87.4%), High (12.3%), Low (0.2%), with 0.2% NULL. The column is marked Tier 3.
**Action**: Locate or create a wiki for `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake` to document the scoring model, source system, and value definitions (Low/Medium/High). Confirm whether this is a Databricks lake view or a Synapse external table.

---

### 2. AMLEntity / AMLSubEntity / AMLSubEntity_2 — columns not individually documented in BI_DB_AML_SubEntity_Categorization wiki

**Columns**: `AMLEntity`, `AMLSubEntity`, `AMLSubEntity_2`
**Source**: `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization`
**Issue**: The upstream wiki for `BI_DB_AML_SubEntity_Categorization` documents 9 elements but lists only `AML_Sub_Entity` (a STRING_AGG comma-separated column). The SP reads separate columns `AMLEntity`, `AMLSubEntity`, `AMLSubEntity_2` from that table, suggesting the table has more columns than the wiki documents. These are marked Tier 1 (upstream wiki present, entity meanings described in wiki Section 1 and 2.x), but the specific column-level descriptions are inferred from business context, not verbatim from an Element table row.
**Action**: Update the `BI_DB_AML_SubEntity_Categorization` wiki to document `AMLEntity`, `AMLSubEntity`, and `AMLSubEntity_2` as individual elements. Confirm the SP_AML_SubEntity_Categorization step that writes these separate columns (vs. the STRING_AGG AML_Sub_Entity column).

---

### 3. High-risk country ID list — no country name mapping confirmed

**Column**: Population filter (affects which CIDs appear in the table)
**Issue**: The SP filters on 20 CountryIDs: `(109, 217, 167, 15, 155, 123, 97, 179, 105, 63, 138, 3, 235, 98, 99, 113, 198, 229, 210, 209)`. These represent specific terrorism/AML-risk monitored countries. The wiki identifies the list exists but does not map each ID to a country name (to avoid potential sensitivity/accuracy issues with guessed mappings).
**Action**: A compliance team member should confirm and document which countries these 20 IDs represent (e.g., via `SELECT CountryID, Name FROM DWH_dbo.Dim_Country WHERE CountryID IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209)`) and whether the list is static or subject to periodic compliance review.

---

### 4. UpdateDate — data appears stale (2024-12-28)

**Column**: `UpdateDate`
**Issue**: All 270,341 rows show `UpdateDate = '2024-12-28 04:47:13.517'`. This suggests the table has not been refreshed since December 2024 (approximately 4 months before the sampling date of 2026-04-28). This could indicate:
  - The SP is no longer scheduled
  - The table was deprecated or replaced by another object
  - The sampling was performed against a non-production or archived copy
**Action**: Verify whether `SP_AML_Terror_Monitor_Dashboard` is still active in the SB_Daily scheduler. If deprecated, update the wiki to mark the table as dormant and document its successor.

---

### 5. UC target — not confirmed

**Issue**: No UC target table was identified for this object. The lineage does not include a Databricks gold layer target.
**Action**: Check `knowledge/synapse/Wiki/_generic_pipeline_mapping.json` or the Generic Pipeline configuration to determine if this table is exported to Databricks UC and, if so, under which catalog/schema/table name.

---

*No ## 4. Elements section in this file per pipeline convention.*
