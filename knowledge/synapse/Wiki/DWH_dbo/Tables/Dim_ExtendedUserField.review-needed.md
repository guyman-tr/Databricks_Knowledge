# DWH_dbo.Dim_ExtendedUserField - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. Columns resolved to Tier 2 (SP code) or Tier 3 (live data).

## Columns Needing Clarification

- **FieldTypeID interpretation**: Values are inferred from the field names (e.g., 0=address because province and SubBuildingNumber are address fields). No authoritative FieldTypeID codebook found. Domain expert should confirm the type groupings.
- **FieldTypeID=8 is missing**: IDs go 0-7 then 9. Was FieldTypeID=8 removed/deprecated? What was it?
- **DedicatedEv (FieldTypeID=9)**: What does "DedicatedEv" mean? Is this related to Dim_EvMatchStatus or a separate EV verification flow?
- **No FK consumers**: Despite being loaded daily, Dim_ExtendedUserField has no active FK references in DWH. What system or process uses FieldID to decode extended fields?

## Structural Questions

- **HEAP vs CLUSTERED INDEX**: Most DWH Dim_ tables use a clustered index. Why does Dim_ExtendedUserField use HEAP? Was this intentional?
- **UserApiDB staging mechanism**: Similar to Dim_EvMatchStatus, the UserApiDB staging load mechanism is unclear. Is this via Generic Pipeline Bronze export or a separate DWH-only staging process?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
