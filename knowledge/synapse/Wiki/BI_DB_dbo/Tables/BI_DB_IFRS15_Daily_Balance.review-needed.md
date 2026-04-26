# Review Needed: BI_DB_dbo.BI_DB_IFRS15_Daily_Balance

**Generated**: 2026-04-22 | **Batch**: 26 | **Pipeline phase**: 12 (Post-generation review sidecar)

---

## Questions for Domain Expert

1. **ExcelOrder 15 gap**: The SP skips ExcelOrder 15 (sequence goes 14 → 16). Was this a metric that was removed? What did it represent, and is it safe to document this as "intentionally absent" or could it return?

2. **DltStatusID=4 meaning**: The SP uses `Fact_SnapshotCustomer.DltStatusID = 4` to identify DLT users. What does DltStatusID=4 specifically represent in the customer lifecycle (e.g., "fully enrolled in DLT custody", "DLT-eligible", etc.)?

3. **TanganyStatus values**: What are the possible values of TanganyStatus (from BI_DB_Client_Balance_CID_Level_New)? The wiki infers 'Internal' and 'Customer' but this needs confirmation. The updated Sep 2025 change (`#SR-333553`) suggests these may have changed.

4. **ChangeTypeID 12 vs 13**: The SP filters `ChangeTypeID IN (12,13)` from Dim_PositionChangeLog. ChangeTypeID=13 = CFD→Real or Real→CFD conversion (CFDRealChangeType). What is ChangeTypeID=12? The SP deletes positions where MAX(ChangeTypeID)=12 — this suggests ChangeTypeID=12 represents a reversal or pre-conversion event.

5. **IsTransferOut**: `ClosePositionReasonID=22` triggers IsTransferOut=1. Confirm this is an account transfer (customer moves positions to another eToro entity) vs. any other reason coded as 22.

6. **Zero metrics (ExcelOrder 22–25)**: The "Zero" metrics represent "uncommitted balance" from `Client_Balance_Breakdown_Instrument_Level`. What is the financial meaning of "zero" in the IFRS 15 context? Is this the balance that eToro holds on behalf of customers but that is not yet recognized as revenue?

7. **C2P identification**: C2P positions are identified via `CompensationReasonID=134` in `External_Bronze_etoro_Trade_AdminPositionLog`. Is this the authoritative/sole way to identify C2P positions? Could there be C2P positions not captured by this filter?

8. **`USDValue` column name**: In some SELECT branches USDValue is aliased from `Volume` (flow metrics) while in others it is truly a USD notional value (balance metrics). This semantic dual-use may confuse downstream consumers. Is there a plan to rename or split this column in UC migration?

---

## Known Issues / Anomalies

| Issue | Severity | Description |
|-------|----------|-------------|
| Two-day loop retroactive correction | Medium | The last date in any daily run may be slightly incorrect (late redeems) until the next day's run corrects it. This is documented in the SP comment (2024-04-30). Real-time reporting on the most recent day should caveat this. |
| DLT rows written outside loop | Medium | ExcelOrder 32,33 are not refreshed when re-running historical dates via the main loop — only the loop dates are corrected. A separate manual DELETE + re-run of the DLT section is needed for historical DLT corrections. |
| ExcelOrder 15 absent | Low | Intentional numbering gap. Downstream Tableau reports must not assume sequential ExcelOrder values or join on ExcelOrder range conditions. |
| float precision | Low | TotalUnits and USDValue are FLOAT. Aggregations of many positions may accumulate rounding errors. Financial reconciliation should use DECIMAL casts when precision is critical. |
| `USDValue` semantic ambiguity | Medium | In balance metric branches this is `SUM(TotalNOP)` (true USD NOP). In flow branches it is aliased from `Volume` (computed volume). In commission branches it is `SUM(-FullCommission)`. One column name, three different financial meanings. |
| NOLOCK on position-level reads | Low | Extensive NOLOCK hints. Under concurrent ETL writes, dirty reads are theoretically possible. The 2-day loop provides a retroactive correction mechanism. |

---

## UC Migration Notes

- **UC Target**: Not Migrated
- **No `.alter.sql`** — this session ran in wiki-only mode
- When UC migration is planned:
  - Consider splitting `USDValue` into purpose-specific columns (BalanceUSD, VolumeUSD, CommissionUSD) to eliminate the semantic ambiguity
  - The WHILE loop pattern (2-day retroactive correction) will need redesign in a Databricks context — consider a merge/upsert pattern instead
  - The self-referencing read of `BI_DB_IFRS_15_Daily_Positions` within the same SP run requires careful orchestration (write positions first, then read for balance aggregation)
  - DLT rows (ExcelOrder 32,33) will need a separate pipeline step outside the main daily loop
  - float → decimal/double migration should be considered for financial accuracy
