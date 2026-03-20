# Review Sidecar — DWH_dbo.V_Dim_Date

## Unverified Claims (Tier 3-4)

No Tier 3-4 claims — all columns are derived from view DDL (Tier 2).

## Open Questions

1. **Column name typo**: `IscURRENTWeekClosingDate` — is this a known issue or has it been fixed in production? Downstream consumers may reference either casing.
2. **Is8wBenchmark semantics**: Excludes yesterday itself (`FullDate < CAST(DATEADD(DD,-1,GETDATE()) AS DATE)`) — is this intentional? Some reports may expect the current day included.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
