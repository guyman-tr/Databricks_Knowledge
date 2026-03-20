# DWH_dbo.Dim_Regulation - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DWHRegulationID | This column always equals ID - it is `[ID] as [DWHRegulationID]` in SP_Dictionaries. Why does this alias exist? Is there legacy code that expects a column named DWHRegulationID specifically? |
| StatusID | Hardcoded to 1 (Active) for all rows. Is this a soft-delete flag - could rows ever have StatusID != 1? The production source has no StatusID, so this is pure ETL artifact. |
| ClusterRegulationID grouping | IDs 0, 1, 5 are grouped into Cluster 1 (None, CySEC, BVI). Is this intentional - are None and BVI treated as equivalent to CySEC in analytics? Or is this a historical artifact? |

## Structural Questions

- **6 production columns dropped**: IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID are all dropped by the DWH ETL. This means DWH analysts cannot determine the US/non-US split directly from Dim_Regulation. Was this intentional? Should IsUSA be added back?
- **DWHRegulationID vs ID**: These always have the same value. Is DWHRegulationID used in any active DWH procedures or views that cannot be changed? If not, it could be deprecated.
- **InsertDate = UpdateDate**: Since the table is TRUNCATE+INSERTed daily, InsertDate and UpdateDate are always equal (both GETDATE()). Is InsertDate meaningful in this context?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
