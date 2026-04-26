---
object: BI_DB_dbo.BI_DB_AMLComment_Risk_Score_Report_Ext
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AMLComment_Risk_Score_Report_Ext

## Tier 4 Items / Uncertainties

1. **CID (Tier 4)**: `CID` — assigned Tier 4 because the external AML tool that populates this table is unknown. If a writer SP or external integration is identified, upgrade to Tier 2 or Tier 3.

2. **AuditDate (Tier 4)**: `AuditDate` — purpose is inferred from the table name. Could represent: (a) the date an AML compliance officer audited the customer, (b) the date a risk score comment was recorded, or (c) a date filter for generating the report. Confirm with AML compliance team.

3. **Table purpose**: The exact downstream use of this table is unknown. It may drive a Power BI report, an Excel extract, or another Synapse SP that was not found in the SSDT repo (possibly outside the BI_DB_dbo scope).

4. **"Ext" suffix meaning**: In BI_DB_dbo, "Ext" sometimes means "External table staging" (like BI_DB_AppFlyer_Geo_Ext which stages AppFlyer data). In this case it may mean the data comes from an external compliance system. Confirm the population mechanism.

## Questions for Domain Experts

- What external system populates this table? (AML case management tool? Manual CSV upload? Fivetran?)
- Is this table currently active or decommissioned?
- What report or process reads from this table?
- Is there a related table `BI_DB_AMLComment_Risk_Score_Report` (without the _Ext suffix)?

## No Cross-Object Corrections Needed

Only 2 columns, both Tier 4. No tier conflicts with other wikis.
