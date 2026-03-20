# DWH_dbo.Dim_PlayerStatus -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 15 DWH columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **Missing CanCopy**: Production has `CanCopy` (bit) -- controls whether the account can be copied by other users. Not loaded into DWH. Is this an intentional drop? Analysts cannot derive social-trading eligibility from DWH alone.
- **Missing GetsInterest**: Production has `GetsInterest` (bit) -- controls interest accrual eligibility. Not loaded into DWH. Intentional exclusion?
- **PlayerStatusID=15 (SuspiciousActivity)**: Upstream wiki does not enumerate all status IDs. Confirmed via MCP SELECT TOP that ID=15 exists with Name="SuspiciousActivity". Verify this is the correct status name and whether additional IDs (16+) have been added since last wiki update.
- **IsBlocked vs. permission bits**: When IsBlocked=1, all permission bits (CanLogin, CanOpenPosition, etc.) are also 0. Is this enforced at the ETL layer or is it possible for IsBlocked=1 with some permissions still set to 1?
- **CanBeCopied vs. missing CanCopy**: DWH has `CanBeCopied` (whether others can copy this account) but lacks `CanCopy` (whether this account can copy others). Confirm the distinction and whether analysts rely on CanCopy from a different source.

## Structural Questions

- **HEAP index**: Like Dim_PlayerLevel, this table uses HEAP instead of CLUSTERED INDEX. With 16 rows it is not a performance concern, but the pattern is unusual for Dim_ tables. Oversight or intentional?
- **ID=0 sentinel all-zero permissions**: The placeholder row has all bit columns = 0 (false), Name = 'N/A', IsBlocked = 0. Is IsBlocked=0 correct for the placeholder (it implies "not blocked" which could be misleading for unmatched FKs)?
- **DWHPlayerStatusID redundancy**: Always equals PlayerStatusID. Safe to use PlayerStatusID directly in all join contexts?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
