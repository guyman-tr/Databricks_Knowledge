# DWH_dbo.Dim_Label -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code (Tier 2) or live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Name | LabelID 0 and LabelID 1 both have Name='eToro'. Was this intentional (two separate system entries for the same brand), or is LabelID=0 a null-sentinel and LabelID=1 the real eToro entry? |

## Structural Questions

| Question |
|----------|
| Which fact tables carry a LabelID foreign key? A scan of SP code suggests customer account tables use LabelID, but confirm which specific fact/dimension tables reference Dim_Label. |
| Are any of the white-label partners (LabelID 2-31) still actively onboarding customers? If several are fully retired, should they be marked as inactive in some way? |
| What does LabelID=28 ('etoro-raf') represent? 'raf' likely stands for 'refer-a-friend' -- confirm if this is eToro's referral program channel. |
| What does LabelID=30 ('Dealing') represent? Is this a system-assigned label for dealing-desk-managed accounts, or an internal eToro team? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
