# BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **PII sensitivity**: This table contains real CID and PositionID. Confirm access controls are appropriate — it effectively de-anonymizes the EU/UK custody books.
2. **UC Gold accumulation**: With Append strategy, the UC Gold table should accumulate daily resolver snapshots. Confirm this is the intended historical record.

## Reviewer Corrections

None pending.
