# BI_DB_dbo.BI_DB_Trading_Failures_Risk — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **AirDrop_Type unpopulated**: Column exists in DDL but not in SP INSERT. Is it planned for future use, or a deprecated column?
2. **RegulationID/Regulation NULL before Oct 2024**: Data from April-October 2024 lacks regulation. Should these rows be backfilled?
3. **UC Append strategy**: The Generic Pipeline uses Append, not Override. This means corrections via re-running the SP (DELETE+INSERT) on Synapse won't propagate to UC — the UC table will have both the old and new versions of corrected rows.
4. **Volume computation inconsistency**: Open failures use raw Amount*Leverage, while Succeeds(Open) uses InitialAmountCents/100*Leverage and Succeeds(Close) uses VolumeOnClose. Are these truly comparable?
5. **FailReason column**: The SP reads pf.FailReason but does not include it in the output. Should it be added for root cause analysis?

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- Regulation description matches DWH_dbo.Dim_Regulation.Name (Tier 1 — Dictionary.Regulation) ✓
