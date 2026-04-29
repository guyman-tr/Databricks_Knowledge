# BI_DB_dbo.BI_DB_PositionPnL_UK_Custody — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **EU vs UK book naming**: The SP description says "daily reconciliation for the UK real stocks book vs. an EU (broker) book." Confirm which entity maps to SHA1 vs MD5 and why two different hash algorithms are used.
2. **Single-day retention**: Same as EU_Custody — UC Gold export (Append) is the historical record.

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- Column descriptions are identical to EU_Custody (Object #1) except for PositionID_Hashed (MD5 vs SHA1).
- Both tables have the same row count (20.5M) and same DateID — produced from the same #posFCA temp table.
