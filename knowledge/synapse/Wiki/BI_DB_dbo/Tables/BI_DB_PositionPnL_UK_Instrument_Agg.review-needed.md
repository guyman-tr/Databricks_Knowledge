# BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **No UC mapping**: Same as EU_Instrument_Agg — confirm whether this is intentional Synapse-only.
2. **Identical values to EU_Instrument_Agg**: Both aggregate the same #posFCA source data. Confirm this is intended design (separate Entity tags for reconciliation consumers).

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- Column descriptions identical to EU_Custody_Instrument_Agg (Object #2) except Entity = 'UK'.
- Row counts identical (8.66M rows, 839 dates).
