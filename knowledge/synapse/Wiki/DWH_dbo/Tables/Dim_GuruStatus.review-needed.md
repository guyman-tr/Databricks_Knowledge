# DWH_dbo.Dim_GuruStatus - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code) or Tier 3 (live data).

## Columns Needing Clarification

- **GuruStatusID=1 (Certified)**: Is "Certified" a distinct tier between No and Cadet, or is it the same as entry-level Cadet? The tier order 0=No, 1=Certified, 2=Cadet seems unusual - is Certified a pre-Cadet certification step?
- **GuruStatusID=7 (Removed) vs GuruStatusID=8 (Rejected)**: Documentation says Removed = was in program and left, Rejected = applied and declined. Is this correct? Are these set by admin action or automated rules?
- **Guru vs Popular Investor naming**: The internal name "Guru" (GuruStatus, GuruStatusID) is the legacy term while the customer-facing brand is "Popular Investor". Are these fully equivalent or does "Guru" refer to a specific subset?

## Structural Questions

- **No active PI status in 2026**: Given that eToro's PI program may have changed, are all 6 active tiers (1-6) still in use? Or have some been deprecated?
- **GuruStatusID gap possible**: 9 rows cover IDs 0-8 with no gaps. Are there any historical IDs that were deleted?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
