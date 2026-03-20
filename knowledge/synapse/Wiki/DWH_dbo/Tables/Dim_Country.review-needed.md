# DWH_dbo.Dim_Country - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| CFKey | What does CFKey represent? The column name suggests "Clearing Firm Key" or "Cashflow Key" but exact business meaning is not documented. It is set per marketing region via Ext_Dim_Country_Region_Desk. |
| Desk | Desk is joined from Ext_Dim_Country_Region_Desk via MarketingRegionID - confirming this is a sales/support desk assignment per marketing region, not per individual country? |
| IsHighRiskCountry vs RiskGroupID | The DWH SP recomputes IsHighRiskCountry from RiskGroupID (RiskGroupID IN (0,4) -> 0, else 1). Is this formula still aligned with the production Dictionary.Country.IsHighRiskCountry values? Has there been any divergence since introduction? |
| IsSettlementRestricted (dropped) | This compliance-critical column from etoro.Dictionary.Country is NOT loaded to DWH. Is there a plan to add it? Analysts querying settlement eligibility currently have no DWH-accessible path. |
| StatusID | StatusID is hardcoded to 1 for all rows including CountryID=0. Was there ever a plan to use StatusID for active/inactive country status? Upstream source has IsActive bit column (not loaded). |
| RegulationID | What does RegulationID map to? The source is ComplianceStateDB.Compliance.RegulationCountry. Is there a DWH dimension for regulation entities (DWH_dbo.Dim_Regulation or similar)? |

## Structural Questions

| Question |
|----------|
| Ext_Dim_Country is a manual extension table (no ETL loader beyond migration scripts). Who owns updates to EU/IsEuropeanCountry/MarketingRegionManualName in this table? How often does it change? |
| Ext_Dim_Country_Region_Desk has no active ETL either. Who maintains CFKey/Desk mappings? Is this still current? |
| DWHCountryID always equals CountryID per SP code. Is there a legacy reason for this column? Can it be deprecated? |
| InsertDate is reset to GETDATE() on every daily TRUNCATE+INSERT - the column name is misleading (it is not the original insert date). Is this a known issue? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
