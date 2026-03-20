# Fact_CustomerUnrealized_PnL — Review Sidecar

## Unverified Claims

### 1. TransURPnL Always NULL
**Claim**: TransURPnL is never populated by the current ETL SP and is always NULL.
**Evidence**: The column does not appear in any INSERT statement within SP_Fact_CustomerUnrealized_PnL. It is listed in the target table DDL but not in the SP's INSERT column list.
**Risk**: Medium — if another process populates this column outside the main SP, the wiki description is wrong.
**Suggested verification**: `SELECT TOP 10 TransURPnL FROM DWH_dbo.Fact_CustomerUnrealized_PnL WHERE TransURPnL IS NOT NULL`

### 2. GuruCopiesPNL_Dit "Dit" Meaning
**Claim**: "Dit" stands for "direct copy without guru position linkage" — positions opened via copy but where ConnectedGuruCopies = 0 (ParentPositionID = 0).
**Evidence**: SP shows `ConnectedGuruCopies = 0 AND MirrorID > 0`. The name "Dit" is not documented anywhere in Confluence or code comments.
**Risk**: Low — the SP logic is clear, only the naming etymology is uncertain.
**Suggested verification**: Ask Boris Slutski or check original JIRA ticket for column naming.

### 3. CopyFund Detection Logic
**Claim**: CopyFund is identified by the parent CID having AccountTypeID=9 at the time the copy relationship was opened, using History.BackOfficeCustomer validity window matching.
**Evidence**: SP code builds #copyfund by joining History.Mirror (MirrorOperationID=1) with #fund_dates where AccountTypeID=9 and matching ValidFrom/ValidTo with OpenOccurred.
**Risk**: Medium — this temporal matching logic is complex and could have edge cases around account type transitions.
**Suggested verification**: Validate with BI team whether the fund detection logic correctly handles mid-day account type changes.

### 4. V0 vs V1 PnL Coexistence
**Claim**: Both V0 (PositionPnL_old) and V1 (PositionPnL) are populated for all records. The difference depends on PnLVersion flag per position.
**Evidence**: The INSERT statements show both PositionPnL_old (SUM of CalculatedNetProfit from price difference formula) and PositionPnL (SUM of PnLInDollars). PnLVersion controls which formula is used for CalculatedNetProfit but PnLInDollars is always summed for PositionPnL.
**Risk**: High — the PositionPnL_old column name contains "_old" suggesting it should be deprecated, but it's still being computed. Confirm whether the V0 formula is still needed or can be removed.
**Suggested verification**: Check SP_PNL_Alerts_Gap_Old_VS_New to see if it's still actively monitored, and whether any downstream consumers rely on PositionPnL_old.

### 5. Instrument Correlation Removed (2026-01-04)
**Claim**: SP_Dim_Instrument_Correlation was removed from the DL_To_Synapse orchestration SP on 2026-01-04 by Eitan Lipo ("Remove For New Engine Instrument Corralation").
**Evidence**: The DL_To_Synapse SP shows the EXEC SP_Dim_Instrument_Correlation call is commented out. However, the main SP still reads Dim_Instrument_Correlation for StandardDeviation calculation.
**Risk**: High — if the correlation table is no longer being refreshed, the StandardDeviation values may be stale or based on outdated covariance data.
**Suggested verification**: Check when Dim_Instrument_Correlation was last updated and whether a new pipeline has replaced the old refresh process.

### 6. Futures Exclusion from Stock/Crypto Metrics
**Claim**: Guy M's 2025-07-29 fix ensures futures instruments are excluded from stock, crypto, and mirror metrics to prevent cross-classification.
**Evidence**: SP code shows `AND f.InstrumentID IS null` or `AND f.IsFuture = 0` conditions on all stock/crypto PnL and commission calculations.
**Risk**: Low — the code is clear and consistent. However, the "else" branch (pre-2013) uses `f.IsFuture = 0` while the main branch uses `f.InstrumentID IS null` (LEFT JOIN pattern). These should be functionally equivalent but could differ on NULL handling edge cases.
**Suggested verification**: Confirm that no instruments with IsFuture=1 have InstrumentTypeID IN (5,6,10) — if any exist, the two branches could produce different results.

### 7. FullCommissionByUnitsCrypto_TRS Settled Filter Bug
**Claim**: The code comment `-- guy 2025-07-16 - not important, but the definition here is wrong` indicates a known issue where FullCommissionByUnitsCrypto_TRS uses `IsSettled = 0` but should use `IsSettled = 1` (or may not need a settled filter at all for TRS).
**Evidence**: SP line shows `IsSettled = 0 /*1*/` with the original value `1` commented out and replaced with `0`. The SP comment by Guy M explicitly notes this is wrong but unimportant.
**Risk**: Low — explicitly acknowledged as incorrect but immaterial.
**Suggested verification**: Confirm with Guy M whether this should be corrected for data accuracy.

### 8. Stock Margin Metrics Missing Notional
**Claim**: NOP_StocksMargin exists but there is no corresponding Notional_StocksMargin column. Also no commission breakdown for stock margin.
**Evidence**: DDL has NOP_StocksMargin and PositionPnLStocksMargin but no Notional_StocksMargin, CommissionByUnitsStocksMargin, etc.
**Risk**: Low — this may be intentional as stock margin is a newer category (added 2025-09-25) and may not need the same granular breakdown.
**Suggested verification**: Ask Daniel Kaplan whether a Notional_StocksMargin column should be added for completeness.

## Reviewer Corrections

*(None yet — awaiting domain expert review)*
