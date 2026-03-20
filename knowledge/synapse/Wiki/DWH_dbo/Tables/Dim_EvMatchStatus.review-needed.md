# DWH_dbo.Dim_EvMatchStatus - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code).

## Columns Needing Clarification

- **EvMatchStatusID=1 (PartiallyVerified)**: Clarify what "partial" means in practice - which identity attributes matched vs failed? Does this state persist or does it auto-progress to Verified/NotVerified?
- **UserApiDB upstream wiki**: No upstream wiki found for UserApiDB.Dictionary.EvMatchStatus. If documentation exists elsewhere (Confluence, internal wiki), it would upgrade these columns to Tier 1.

## Structural Questions

- Is `EvMatchStatusID=0` (None) the default for all new registrations, or does it only apply when the EV process is skipped entirely?
- Are there other EV match status values (4, 5, etc.) planned or in use in non-production environments that haven't appeared in DWH yet?
- The UserApiDB staging pipeline mechanism is unclear - is this loaded via the Generic Pipeline to Bronze, or via a separate DWH_staging load process?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
