# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody — Review Needed

## Tier 4 Items

None — no Tier 4 or Tier 5 descriptions in this wiki.

## Open Questions

1. **Single-day retention**: The table is TRUNCATEd daily. Is historical data preserved elsewhere for audit purposes, or is the UC Gold export (Append strategy) the historical record?
2. **SettlementTypeID values**: Three distinct values observed (NULL, 0, 1). Source BI_DB_PositionPnL documents this as "Modern settlement type from Dim_Position" — confirm specific value meanings if a Dictionary exists.
3. **Date/DateID from parent**: The parent BI_DB_PositionPnL uses Date as "Snapshot calendar date @dt" and DateID as the YYYYMMDD integer. Confirm these are always consistent (Date = CAST(DateID as date-format)).

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- Column descriptions for InstrumentID through SettlementTypeID are inherited verbatim from BI_DB_PositionPnL wiki (local Synapse wiki, quality 9.0).
- IsCreditReportValidCB and IsValidCustomer descriptions inherited from DWH_dbo.Fact_SnapshotCustomer wiki.
- UK_Custody table (Object #3) shares identical column structure and descriptions (except PositionID_Hashed uses MD5 instead of SHA1).
