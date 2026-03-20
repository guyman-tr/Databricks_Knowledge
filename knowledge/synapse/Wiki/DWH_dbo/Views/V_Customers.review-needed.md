# Review Sidecar — DWH_dbo.V_Customers

## Unverified Claims (Tier 3-4)

No Tier 3-4 claims — all columns inherited from documented Fact_SnapshotCustomer (Tier 1).

## Open Questions

1. **Cardinality**: Estimated 300B+ virtual rows is theoretical. Actual Dim_Range has ~1.3M date ranges, not all spanning full history. Real cardinality likely lower but still massive.
2. **IsDepositor without ISNULL**: All other columns use `ISNULL(col, 0)` except `IsDepositor`. Confirm whether this is intentional (BIT type can't be 0?) or an oversight.
3. **WITH(NOLOCK)**: The view uses `WITH(NOLOCK)` on Fact_SnapshotCustomer. This means dirty reads are possible — should be noted for regulatory reporting consumers.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
