# Review Needed: Dealing_dbo.Dealing_Apex_PnL_EE_Daily

## Summary

All 8 columns are Tier 2 (SP-derived). No Tier 1 upstream inheritance is possible because this table's data originates from Apex Clearing LP external files via staging tables that have no wiki documentation. The upstream wikis in the bundle (`Dealing_Apex_PnL_EE`, `Dealing_Apex_PnL`, etc.) are sibling tables loaded by the same SP, not upstream sources.

## Items for Human Review

### 1. Stale Data -- Pipeline Status

- **Issue**: Last data load was 2024-06-08 09:19. No rows after 2024-06-07.
- **Question**: Is the Apex LP pipeline permanently decommissioned or temporarily paused? If decommissioned, should this table be marked as deprecated?

### 2. Account Mapping Verification

- **Issue**: The SP hardcodes an AccountNumber-to-HedgeServerID mapping (`#AccountToHS`) used for the symbol-level Zero calculation. This mapping is used by the sibling tables but not directly by EE_Daily.
- **Question**: Are there any new Apex accounts added since 2024-06-07 that would need to be added to the hardcoded mapping if the pipeline resumes?

### 3. Equity_Start NULL Rows (7.6%)

- **Issue**: 190 of 2,491 rows have NULL Equity_Start. The PnL formula treats these as 0 via ISNULL.
- **Question**: Do NULL Equity_Start rows represent genuinely new accounts (first day), or data gaps from missing Apex equity files?

### 4. Transfers Precision

- **Issue**: Transfers is `decimal(16,8)` while Equity columns are `decimal(16,6)`. This suggests sub-cent precision from the Apex feed.
- **Recommendation**: No action needed, but consumers should be aware of precision differences in reconciliation.

### 5. UC Target Pending

- **Issue**: UC target not yet configured for this table.
- **Action**: Resolve during write-objects phase.
