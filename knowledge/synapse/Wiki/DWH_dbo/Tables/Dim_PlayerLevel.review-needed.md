# DWH_dbo.Dim_PlayerLevel -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 12 DWH columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **Missing RealizedEquityFrom/To**: These are the primary tier qualification thresholds (e.g., Bronze = $0-$5000, Diamond = $250K-$100M). They exist in production but are NOT loaded into the DWH. Is this intentional? Analysts cannot perform tier-equity analysis from DWH data alone.
- **Missing DaysInRiskBeforeDowngrade**: The grace period before downgrade (0=immediate, 180=6mo, 365=1yr) is not in DWH. Intentionally dropped?
- **FromSumLotCount/ToSumDeposit with -1**: Confirmed "disabled" for upper tiers. But are the Bronze/Silver/Gold values (e.g., Bronze: lots 1-3000) still in use anywhere? Or fully superseded by equity thresholds?

## Structural Questions

- **HEAP index**: Why is this table using HEAP instead of CLUSTERED INDEX (like most Dim_ tables)? Oversight or intentional?
- **ID=0 sentinel midnight date**: Confirmed @ddate convention. The staging table apparently does NOT include ID=0 -- it's hardcoded in SP. Confirm whether the staging table for PlayerLevel includes any placeholder rows.
- **DWHPlayerLevelID redundancy**: Like other DWH surrogate columns (DWHCurrencyID, etc.), this always equals PlayerLevelID. Confirm it's safe to use PlayerLevelID directly in all contexts.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
