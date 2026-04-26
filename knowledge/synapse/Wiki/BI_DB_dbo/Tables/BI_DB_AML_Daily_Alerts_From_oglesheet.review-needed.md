---
object: BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AML_Daily_Alerts_From_oglesheet

## Tier 4 Items / Uncertainties

1. **AlertCatery typo (Tier 4)**: Column 2 is named `AlertCatery` — a DDL typo for `AlertCategory`. Present since at least Nov 2024 backup. Key questions:
   - Is the Google Sheet column also named `AlertCatery` (the typo was in the original Sheet), or is it properly named `AlertCategory` in the Sheet?
   - Should this column be renamed via an ALTER TABLE? Renaming requires recreating the clustered table (Synapse limitation) and updating any ETL scripts that reference `AlertCatery`.
   - Is there any existing ETL code outside SSDT that references `AlertCatery` by name?

2. **AlertID format (Tier 4)**: The format and uniqueness of AlertID is unknown. Is it a system-generated UUID, a sequential ID from the AML tool, or a manually-entered reference number?

3. **AlertType / AlertCatery values (Tier 4)**: Exact valid values for AlertType and AlertCatery (AlertCategory) are unknown. What are the controlled vocabulary values used in the Google Sheet? Are they free-text or dropdown-enforced?

4. **AlertStatus lifecycle values (Tier 4)**: The investigation lifecycle states are unknown. What statuses does the AML team use? ('Open', 'In Review', 'Closed', 'Escalated', 'False Positive', 'Confirmed', 'Pending'?) — confirm with AML compliance team.

5. **Assigned format (Tier 4)**: Is the analyst stored as a display name, email address, or username? How are unassigned alerts represented — NULL or an empty string or a placeholder like 'Unassigned'?

6. **RelatedAccounts truncation risk (Tier 4)**: `RelatedAccounts` is nvarchar(256). If a customer has many related accounts, the list may be silently truncated at import. Has this ever caused data loss? Confirm with the ETL owner.

7. **Google Sheet identity / URL (Tier 4)**: Which specific Google Sheet feeds this table? The Google Sheet URL/name/ID would enable direct validation of column mapping and current data.

8. **ETL transfer mechanism (Tier 4)**: What script or tool transfers data from this staging table to `BI_DB_AML_Daily_Alerts`? No SSDT SP found. Is it a Python script, a PowerShell script, an Azure Data Factory pipeline, or a Fivetran connector?

9. **Population currently inactive**: Table is empty as of 2026-04-23. Was the Google Sheet integration decommissioned? Is the pipeline paused for a rebuild? Confirm with the AML engineering team.

## Questions for Domain Experts

- Should `AlertCatery` be corrected to `AlertCategory`? If so, who owns the ALTER TABLE migration?
- What is the Google Sheet URL that feeds this table?
- What ETL mechanism transfers data from this staging table to the main `BI_DB_AML_Daily_Alerts` table?
- Are valid AlertType, AlertCatery, and AlertStatus values documented anywhere?
- Is the Google Sheet still maintained? If the pipeline is paused, when will it resume?
- Has RelatedAccounts ever been truncated at 256 chars? Should the limit be increased?

## Column-Level Correction: AlertCatery Mapping

The correct downstream mapping is:
- `BI_DB_AML_Daily_Alerts_From_oglesheet.AlertCatery` → `BI_DB_AML_Daily_Alerts.AlertCategory`

This must be explicitly handled in any ETL transfer script (column alias or SELECT with rename).
