# BI_DB_Crypto_Dashboard — Review Needed

**Batch**: 20 | **Generated**: 2026-04-22 | **Reviewer**: Pending

## Tier 4 Items (Unverified — need confirmation)

None. All columns traced to confirmed SP code and upstream DWH sources.

## Questions for Domain Expert / Reviewer

1. **"Acvtive Hold" typos — intentionally preserved?**: Columns 22 (`Acvtive Hold by Inst`) and 24 (`Acvtive Hold`) contain a clear misspelling from the original 2021 SP code. The DDL column names are misspelled. Are there any downstream dashboards, reports, or Power BI datasets that reference these column names? Has anyone attempted to rename them (via ALTER TABLE or a CTAS rebuild), or is this frozen due to downstream dependencies?

2. **Active Hold / Active Hold Real / Active Hold CFD non-dimensioned behavior**: These three columns (#24, #25, #26) are computed by grouping #positionpnl on DateID only — not on the row's Regulation/Country/BuyCurrency/Real-CFD/Manual-Copy grain. The same count repeats across all rows for a DateID. Is this the intended design (a "header" metric repeated for convenience), or was it supposed to be dimension-segmented like `Acvtive Hold by Inst` (#22)? Downstream consumers must know not to SUM these columns across rows.

3. **Revenue=0 for Real crypto positions**: On recent dates (e.g., 2026-04-12), does Revenue appear as 0 for `Real/CFD = 'Real'` rows? If so, is this because real crypto opens/closes generate zero commission, or is there a known gap in how Fact_CustomerAction captures real crypto fees vs. CFD fees? Understanding this prevents false data quality alerts.

4. **FA Amount Total negation**: The SP computes `SUM(-ffca.Amount)` — negating Fact_FirstCustomerAction.Amount. Is this consistently negative in Fact_FirstCustomerAction for open actions (ActionTypeID=1)? Have there been any sign convention changes since 2021 that could have introduced double-negation for a subset of dates?

5. **Population definition drift**: The customer population filter (IsValidCustomer=1, IsDepositor=1, PlayerLevelID≠4) is applied via Fact_SnapshotCustomer as of @date. If a customer's PlayerLevel changed to 4 (demo) mid-day, they may appear on some historical dates but not others. Is this the intended population definition for crypto reporting, or should it use a different baseline (e.g., all-time crypto traders)?

6. **BI_DB_PositionPnL dependency**: Columns 14–16 (AUA, Amount in Units, PnL) and 21, 24–26 (Open Positions, Acvtive Hold variants) all depend on BI_DB_PositionPnL being populated for DateID=@dateID before SP_CryptoDashboard runs. Is there a documented execution order / SB_Daily schedule constraint ensuring BI_DB_PositionPnL is always ready first?

## Potential Data Quality Issues

- **"Acvtive Hold" column names**: Misspelled DDL column names are the actual names in production. Downstream tools must reference the misspelled names. SSMS autocomplete will suggest the misspelled version — do not "fix" in ad-hoc queries.
- **Non-dimensioned active holder counts**: Summing `Acvtive Hold`, `Active Hold Real`, or `Active Hold CFD` across rows for a given date will produce inflated figures. These are date-level metrics repeated across all dimension rows. Use a single-row-per-date deduplication (ROW_NUMBER or TOP 1) before aggregating.
- **Real crypto revenue reporting**: Revenue for Real crypto positions may structurally differ from CFD revenue. Confirm that commission action types (1,2,3,4,5,6,39,40) and rollover (35) capture all applicable fee types for settled positions.

## Correction Log

*(Empty — no corrections yet)*
