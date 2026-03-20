# DWH_dbo.Dim_Funnel - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

- **PlatformID values**: Inferred as 0=Unspecified, 1=Web, 2=iOS, 3=Android based on funnel name context. No Dim_Platform table to confirm. Needs domain expert verification.

## Columns Needing Clarification

- **PlatformID decoding**: Values 0-3 inferred from funnel names. Is there an authoritative decode for PlatformID? Does it reference Dim_PlatformType (which has similar web/mobile platform content)?
- **FunnelID=-9 (AutomationTest)**: Is this a legitimate test account funnel or should it be filtered from all analytics? Are there customer records with FunnelID=-9?
- **Name not renamed**: Unlike FundingType (Name stays as Name), most other Dim_ tables rename Name to XxxName. Was this an oversight or intentional consistency with Dim_FundingType?
- **HEAP index**: Why HEAP instead of CLUSTERED INDEX? Consistent with Dim_FundingType. Was this a deliberate choice for small lookup tables or an oversight?
- **FunnelID gaps**: Are there gaps in the 129 rows between -9 and 130? If so, do those represent deleted funnels?

## Structural Questions

- **No Dim_Platform link**: PlatformID references platforms but there is no `Dim_Platform` in DWH_dbo. Is PlatformID the same as `Dim_PlatformType.PlatformTypeID`? They both seem to encode web/mobile distinctions.
- **129 rows with max FunnelID=130**: The gap implies one FunnelID (likely 10) is missing. Confirm whether this is a deleted funnel or a data entry gap.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
