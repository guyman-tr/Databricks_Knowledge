# Review Sidecar — DWH_dbo.Fact_Guru_Copiers

## Unverified Claims (Tier 3-4)

No Tier 3-4 claims — all columns traced to SP logic and Confluence documentation (Tier 2).

## Open Questions

1. **Row count**: Synapse MCP dropped before query. The table is daily append since 2018 — estimated hundreds of millions of rows but unverified.
2. **DetachedPosInvestment vs Dit_PnL**: Confluence "AUM Life Cycle" confirms the distinction (detached = copier took manual control), but the exact trigger for detachment (manual close vs. SP detach vs. BO action) is not specified.
3. **CID type**: Fact table uses `bigint` for CID, while Fact_SnapshotCustomer.RealCID is `int`. Confirm whether any CID values actually exceed INT range.
4. **V_M2M_Date_DateRange JOIN semantics**: The SP joins on `fsc.DateRangeID = bb.DateRangeID AND DateID = bb.DateKey`. This means it only aggregates copiers whose SnapshotCustomer date range spans the target DateID. Copiers with closed snapshot ranges would be excluded.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
