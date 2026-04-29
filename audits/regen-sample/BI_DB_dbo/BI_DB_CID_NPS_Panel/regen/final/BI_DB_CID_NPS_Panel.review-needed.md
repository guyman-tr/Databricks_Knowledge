# BI_DB_CID_NPS_Panel — Review Needed

> Human review items for `BI_DB_dbo.BI_DB_CID_NPS_Panel`. Regen attempt 1.

---

## 1. Unresolved Source (Tier 3 columns)

### 1.1 External_Fivetran_delighted_response / External_Fivetran_delighted_person

- **Columns affected**: `Date`, `NPS_ID`, `Score`, `Comment`
- **Issue**: No upstream wiki exists for `BI_DB_dbo.External_Fivetran_delighted_response` or `BI_DB_dbo.External_Fivetran_delighted_person`. These are Fivetran-managed external tables syncing data from the Delighted NPS platform. Their schema is vendor-defined.
- **Action needed**: Confirm that `External_Fivetran_delighted_response.id` is indeed the Delighted survey response ID (NPS_ID) and that `score` is the 0–10 NPS rating. A Delighted API/schema reference or a wiki for these External tables would lift these columns to Tier 1.
- **Risk**: LOW — field names (score, comment, created_at, id) are semantically obvious and confirmed by live data (score range 0–10, comment = free text).

---

## 2. Identity Resolution Gaps

### 2.1 NULL RealCID rows (~630 rows)

- **Issue**: ~630 rows (~0.4%) have NULL RealCID after the three-pass identity matching (UserName, Email, UserName_Lower). All DWH-enriched columns are NULL for these rows.
- **Possible causes**: Deleted accounts (GDPR erasure), respondents who submitted with a non-eToro email, or respondents whose Delighted profile doesn't match any Dim_Customer entry.
- **Action needed**: Confirm whether these should be excluded from NPS calculations or tracked separately as "unidentified respondents." Consider whether a fourth matching strategy (e.g., by GCID or phone) is feasible.

---

## 3. SP Behavior Questions

### 3.1 Fact_SnapshotCustomer GROUP BY without aggregation guard

- **Issue**: The `#fsc` CTE groups by `pp.RealCID, dpl.Name, ps.Name, mif.Name, dc1.Name, dr.Name, fsc.IsDepositor`. If a customer has multiple attribute states on the same survey date (rare but possible at SCD2 boundary), this GROUP BY could silently select a non-deterministic row.
- **Action needed**: Confirm whether this is intentional (e.g., they want any active state on the day) or whether the SP should take the most recent open row (max DateRangeID).

### 3.2 FirstAction NULL for depositors

- **Issue**: ~2,505 rows have NULL FirstAction. This could mean the customer exists in BI_DB_First5Actions but has never opened a position. The LEFT JOIN means they get NULL (not filtered out).
- **Action needed**: Confirm that NULL FirstAction means "deposited but never traded" — distinct from "not found in BI_DB_First5Actions." If BI_DB_First5Actions is depositors-only, a non-match could indicate a data lag.

---

## 4. Date Range / Scheduling

### 4.1 Survey date vs. ingestion date

- **Issue**: `Date` is the Delighted survey submission timestamp; `DateID` is the SP parameter `@Date` (the batch ingestion date). If Fivetran ingests responses with a delay, `Date` and `DateID` may not align (e.g., a survey submitted at 2025-07-09 23:59 may be ingested with DateID=20250710).
- **Action needed**: Confirm whether `DateID` should be interpreted as the survey date (current assumption) or the ingestion batch date. This matters for time-series NPS analysis.

---

## 5. UC Migration Status

- **Issue**: Table is not migrated to Unity Catalog (Databricks). No UC target in `_generic_pipeline_mapping.json`.
- **Action needed**: Confirm whether UC migration is planned. If Comment column contains PII (customer email/name sometimes appears in verbatim comments), PII classification will be required before UC export.

---

*Review-needed generated: 2026-04-28 | Regen attempt 1*
*Object: BI_DB_dbo.BI_DB_CID_NPS_Panel*
