# Review Needed: BI_DB_dbo.BI_DB_BODailyCompensations

**Generated**: 2026-04-23 | **Batch**: 56 | **Reviewer**: Pending

## Tier 4 Items (Low Confidence — Needs Confirmation)

None — all columns are Tier 2 with direct SP code evidence or Propagation (IDENTITY/GETDATE()).

## Open Questions

1. **CreditTypeID=6 stability**: The SP hardcodes `CreditTypeID=6` to filter compensation credits. Confirm this value has not changed in etoro.History.Credit since the SP was created and that it exclusively maps to BO compensations (not shared with another credit subtype).

2. **Manager NULL semantics**: ~39% of recent rows have Manager=NULL. Confirm whether NULL means (a) system-generated compensation with no manager in the source, (b) the ManagerID was present but the LEFT JOIN to Dim_Manager returned no match, or (c) ManagerID was NULL at source. This affects interpretation of "unattributed" compensations.

3. **Payment currency**: Payment is typed as `money` but the column description assumes USD. Confirm whether all compensation credits in etoro.History.Credit (CreditTypeID=6) are denominated in USD or if multi-currency records exist.

4. **ID uniqueness across re-runs**: The IDENTITY column is re-generated on every DELETE+INSERT cycle. Confirm that downstream consumers use CreditID (not ID) as the stable business key, since the same credit will have a different ID after a data correction re-run.

5. **Occurred vs. business event date**: Confirm that `Occurred` is the timestamp of the credit event in the source system (not an accounting date or settlement date). For compensation adjustments applied retroactively, the Occurred value may differ from when the decision was made.

## Known Issues / Notes

- Manager, Country, Country, and Regulation are resolved at load time and stored as denormalized strings — they are not FK-constrained. If Dim_Manager or Dim_Customer is updated after load, this table will not reflect the update until the row is re-loaded by a re-run.
- No upstream wiki exists for etoro.History.Credit or etoro.BackOffice.CompensationReason. Column semantics for CreditID, Payment, Description, and Category are inferred from SP code and column names only.
- HEAP distribution means full table scans on large range queries; queries filtering by Occurred date should be aware of this.

## Cross-Object Consistency Checks

| Column | Canonical Source | Check Status |
|--------|-----------------|-------------|
| CID | DWH_dbo.Dim_Customer | ✓ Standard FK pattern — consistent with other BI_DB tables |
| Country | DWH_dbo.Dim_Country.Name | ✓ Resolution pattern consistent with other BI_DB tables (via Dim_Customer) |
| Regulation | DWH_dbo.Dim_Regulation.Name | ✓ Resolution pattern consistent with other BI_DB tables (via Dim_Customer) |
