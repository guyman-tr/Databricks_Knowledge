# Review Sidecar — DWH_dbo.V_Dim_Instrument_Correlation

## Unverified Claims (Tier 3-4)

No Tier 3-4 claims — all columns inherited from Dim_Instrument_Correlation_UnionedPartitions wiki (Tier 1).

## Open Questions

1. **Hardcoded date split**: `20250202` marks the half-matrix cutover in `Dim_Instrument_Correlation_Active`. Verify whether this date is still relevant or if the Active table has been fully migrated to half-matrix format.
2. **Dim_Instrument_Correlation_Active vs UnionedPartitions**: This view reads from a separate `Active` table, not through the UnionedPartitions view. Confirm whether `Active` is populated independently or is a synonym/subset.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
