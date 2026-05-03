# EXW_Wallet.SentTransactionOutputs — Review Needed

## Summary

All 16 columns documented. No upstream wiki available (`_no_upstream_found.txt` present). All production-origin columns assigned Tier 3 (grounded in DDL + data evidence + reader SP usage). ETL-added columns assigned Tier 2.

## Items for Human Review

### 1. SourceIdType Values

- Observed values: 1 (~1.13M), NULL (~1.08M), 2 (~1.4K), 0 (8)
- **Question**: What do SourceIdType = 0 and SourceIdType = 2 represent? Type 1 appears to be PositionId based on SP_EXW_FactRedeemTransactions JOIN logic. No dictionary or enum documentation found.
- **Recommendation**: Confirm with WalletDB team or check WalletDB source code for the enum definition.

### 2. BlockchainFees Column

- This column is mostly NULL in live data. SP_EXW_FactRedeemTransactions calculates `SentTransactions.BlockchainFee / COUNT(outputs)` instead of using this column.
- **Question**: Is this column deprecated or only populated for specific transaction types? Consider whether it should be flagged as deprecated.

### 3. EtoroFees at Output Level

- Predominantly 0 in sampled data. eToro fees are calculated at the Redemptions / ConversionTransactions level in downstream SPs.
- **Question**: Under what conditions is EtoroFees populated at the output level?

### 4. Production Source Wiki

- No upstream wiki exists for WalletDB.Wallet.SentTransactionOutputs. All descriptions are Tier 3 (DDL + data evidence).
- **Recommendation**: If a WalletDB wiki is created in the future, re-run documentation to upgrade Tier 3 columns to Tier 1.

### 5. SynapseUpdateDate

- All sampled rows show NULL for SynapseUpdateDate.
- **Question**: Is this column actively populated by the Generic Pipeline, or is it only set during specific re-processing runs?
