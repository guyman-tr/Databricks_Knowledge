# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **No UC mapping**: This table has no Generic Pipeline entry. Confirm whether it should be exported to the data lake or if it is Synapse-only.
2. **IsBuy type mismatch**: EU_Custody has IsBuy as `bit`, but this aggregation table has it as `int`. Confirm if this causes any issues downstream.

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- UK_Instrument_Agg (Object #5) has identical structure with Entity = 'UK'.
- Aggregated columns inherit descriptions from EU_Custody with SUM() transform noted.
