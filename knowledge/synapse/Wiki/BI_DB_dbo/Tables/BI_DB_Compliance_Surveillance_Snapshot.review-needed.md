# Review Flags: BI_DB_Compliance_Surveillance_Snapshot

## Flag 1 — Fivetran External Table Dependency (SOFT)
The instrument list and @lookbackdays parameter are sourced from `External_Fivetran_compliance_snapshot_report_instrumentids`, a Google Sheets document managed by Ed Drake in Compliance and synced via Fivetran. If the Fivetran sync fails, the SP will run against the stale list from the previous day. No error handling visible in SP for missing/stale Fivetran data. Recommend monitoring Fivetran sync status for this table.

## Flag 2 — @lookbackdays Encoding Hack (SOFT)
The lookback window parameter is embedded in the instrument list as a special row with `instrument_id < 100`. This is a fragile encoding: if a legitimate instrument ever has InstrumentID < 100, it would be misinterpreted as the lookback parameter rather than an instrument to include. Conversely, if the lookback entry is missing, the SP defaults to 13 days silently.

## Flag 3 — Tuesday Snapshot Logic Anomaly (INFO)
When run on Tuesday, `DATEADD(DAY, -3, Tuesday) = Saturday`. The snapshot time becomes Saturday 00:00:00 − 1 second = Friday 23:59:59, same as the Monday run. This means Monday and Tuesday produce identical snapshots (both reflecting Friday end-of-day). This appears intentional — Tuesday is a fallback day if Monday's run fails — but is not documented in SP comments. Verify with Compliance team.

## Flag 4 — eToro Employee Inclusion (INFO)
eToro employees (Region='eToro') are included even with `IsValidCustomer = 0`. This was explicitly added 2024-05-10 "for UK Compliance". 63 'Internal' rows in current data. Downstream analysis should handle these separately — employee trading behavior should not be mixed with client surveillance data.

## Flag 5 — UnrealisedPositionPnL Zero vs Missing (SOFT)
Both `UnrealisedPositionPnL_Snapshot` and `UnrealisedPositionPnL_ReportDate` use `ISNULL(..., 0)`. This means a position with no PnL record in BI_DB_PositionPnL (e.g., position opened but no snapshot exists for that date) will show 0, indistinguishable from a position that genuinely had 0 PnL movement. Compliance consumers should be aware that 0 ≠ "no change" in all cases.

## Flag 6 — PII Exposure (INFO)
Contains LastName, Postcode, LastIPAddress — moderate-sensitivity PII. IP address enables geolocation. Dynamic data masking recommended in UC migration.

## Flag 7 — CloseOccurred Sentinel (SOFT)
Open positions store '1900-01-01 00:00:00' as CloseOccurred. Filtering for open-only positions requires `WHERE CloseOccurred = '1900-01-01 00:00:00'` (or `CloseOccurred LIKE '1900%'`), not `IS NULL`. This is consistent with the ShortTermTrades table pattern.
