# AML_InstrumentMetaData_Daily_Email_DayToDay_Changes — Review Notes

**Generated**: 2026-04-23
**Reviewer**: —

## Items Needing Human Verification

1. **Empty table behavior**: Sample on 2026-04-23 returned 0 rows. Confirm this is expected (no ISIN changes that day) rather than a pipeline failure. Request a sample from a day with known ISIN changes to verify the table populates correctly.

2. **Yesterday definition**: The SP filters `SysEndTime >= yesterday's date`. Confirm the exact cutoff (midnight UTC? midnight local?). The `ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY SysEndTime ASC) = 1` picks the earliest record from yesterday — confirm this correctly represents "start of yesterday ISIN state" rather than "end of yesterday".

3. **OpsDB orchestration**: Listed as P0. Confirm the SP runs after the parent table SP and after the history External Table is refreshed to ensure both snapshots reflect the same calendar day.

4. **ISIN validity filter for #currentIsins**: Confirm it uses the same 6-pattern filter as the parent table SP. The SP was written by the same author (Eyal Boas) — verify the filter is consistent.

5. **Downstream consumers**: Only the AML daily email process identified. Confirm no other consumers (dashboards, compliance reports) reference this change table.

6. **External_etoro_History_InstrumentMetaData existence**: The SP reads from this External Table (inferred from SP logic). Confirm this external table exists in the BI_DB_dbo schema and points to the correct Bronze path.

## Quality Score

9.0/10 — 5-column event-driven table. InstrumentID/InstrumentDisplayName/SymbolFull Tier 1 from DWH wiki. New_ISINCode/Old_ISINCode Tier 2 from SP logic clearly documented. Business meaning clear (ISIN change detection). Data evidence limited (0 rows observed) — deduction for lack of sample rows showing actual change data.
