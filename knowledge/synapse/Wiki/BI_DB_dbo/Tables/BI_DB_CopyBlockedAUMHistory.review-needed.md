# BI_DB_dbo.BI_DB_CopyBlockedAUMHistory — Review Needed

Generated: 2026-04-23 | Batch: 74

## Open Items

### HIGH — Disappearing History on Unblock
**When a PI is unblocked, ALL their history rows are silently dropped** on the next daily TRUNCATE+INSERT. The table is scoped to currently-blocked PIs only (JOIN #blockedusers). This means this table cannot be used for permanent audit or compliance tracking of past blocks.
- Action: Confirm this is intentional. If an audit trail is needed, the source is `etoro.Customer.History_BlockedCustomerOperations` (external table).
- Risk: Any report built on this table will silently lose data when PIs are unblocked.

### HIGH — UC Migration Decision
**UC Target is `_Not_Migrated`** — not in Generic Pipeline. With compliance implications around PI blocking, a migration decision is needed.
- Action: Assess with Data Platform and compliance teams whether this history should be persisted in UC.

### MEDIUM — Enrichment Temporal Mismatch
`UserName`, `Country`, and `GuruStatusID` reflect the PI's **current** dimension values at load time (sourced from `#blockedusers`), not their values at the time of the historical block event.
- Action: Document clearly in any consuming report that these columns are not historically accurate. Consider joining to a dimension snapshot if time-correct attributes are needed.

### MEDIUM — `DaysBlocked` NULL for Active Blocks
`DaysBlocked` is NULL when `BlockEnd` IS NULL. Consumers computing total days blocked must handle NULLs by using `ISNULL(DaysBlocked, DATEDIFF(DAY, BlockStart, GETDATE()))`.
- Action: Verify consuming queries handle this case.

### LOW — No Confluence Documentation Found
No DATA space pages identified for this table or the SP_CopyBlockedAUM process.
- Action: Check with Tom Boksenbojm or Dan's team for operational runbooks.

### INFO — PII Columns Removed
`FirstName` and `LastName` columns were removed from this table on 2022-03-13 (Inbal BML, "Move PII columns From tables in BI_DB" task). Any legacy queries referencing these columns will fail.
