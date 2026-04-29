# Review Needed: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

## Summary

All 22 columns are Tier 3 (grounded in DDL + data sample + sibling SP pattern). No writer SP exists in the SSDT codebase — the Trades INSERT was removed from `SP_SAXO_Recon_FXnCommed`. This table is orphaned with data stopped 2023-12-05.

## Items Requiring Human Review

### 1. Orphaned Table — Confirm Decommission Status

- **Issue**: No stored procedure writes to this table. Data stopped 2023-12-05 (~16 months stale).
- **Action needed**: Confirm whether this table should be dropped or if an external process (outside SSDT) still references it. The sibling `Dealing_SaxoRecon_FXnCommed_EODHoldings` is actively written by `SP_SAXO_Recon_FXnCommed`.
- **Risk**: If an external pipeline (e.g., Python, ADF, or manual load) writes to this table, the wiki is incomplete.

### 2. Writer SP History — Confirm Removal Timeline

- **Issue**: The Trades INSERT was likely removed during one of these SP changes: SR-247184 (2023-04-09, Gili — logic restructure), SR-282224 (2024-11-25, Gili — Fivetran migration), or SR-282666 (2024-11-27, Gili — removed Saxo's CFD and Shares tables).
- **Action needed**: Verify which SR removed the Trades logic. Git blame on `SP_SAXO_Recon_FXnCommed.sql` would confirm.

### 3. Commission Currency Unconfirmed

- **Issue**: The `Commission` column values are all ≤ 0 (range -559.27 to 0.00). Cannot confirm whether this is in USD or local instrument currency without the writer SP code.
- **Action needed**: Ask the Dealing team (Adar, Gili, or Sarah per SP change history) to confirm the commission currency.

### 4. Client-Side Source Unconfirmed

- **Issue**: `Clients_Units` and `Clients_AmountUSD` are inferred to come from client position data (possibly `DWH_dbo.Dim_Position` or a risk matrix table). The sibling SP's EOD section uses `Dealing_Duco_EODRecon` for client data, but the Trades section may have used a different source.
- **Action needed**: Confirm the original client-side data source for the Trades section.

### 5. InstrumentID NULL Rows

- **Issue**: 2 rows have NULL `InstrumentID` out of 4,226 total. Minor data quality issue.
- **Action needed**: Investigate whether these are data load errors or intentional (e.g., unresolved instruments).

### 6. Potential Candidate for Table Cleanup

- **Issue**: This table has been dormant for ~16 months with no references in any SP, view, or downstream object.
- **Action needed**: Consider adding to a cleanup/deprecation backlog if confirmed unused.

## Tier Distribution

| Tier | Count | Percentage |
|------|-------|-----------|
| Tier 1 | 0 | 0% |
| Tier 2 | 0 | 0% |
| Tier 3 | 22 | 100% |
| Tier 4 | 0 | 0% |

**Reason for 100% Tier 3**: No writer SP code available (orphaned table). No upstream wiki resolvable. All descriptions grounded in DDL structure, live data sample (4,226 rows), and sibling SP (`SP_SAXO_Recon_FXnCommed`) pattern analysis rather than name inference alone.
