# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs

## Items Requiring Human Review

### 1. Column Name Typo — CountyByRegIP
- The DDL column name is `CountyByRegIP` (missing "r" — should be "CountryByRegIP")
- This typo exists in the source DDL and SP code. Cannot be changed without an ALTER + SP update.
- **Action**: Confirm whether this is a known/accepted typo or needs a rename request.

### 2. External Table Dependencies — Unresolved Upstream Wikis
The following external tables are used by the SP but have no upstream wiki documentation:
- `BI_DB_dbo.External_etoro_History_Credit_Yesterday` — dynamic external table created by `SP_Create_External_etoro_History_Credit`
- `BI_DB_dbo.External_etoro_Billing_Deposit` — external table pointing to etoro.Billing.Deposit
- `BI_DB_dbo.External_etoro_Billing_DepositRollbackTracking` — external table for rollback tracking
- `BI_DB_dbo.External_etoro_Billing_Funding_Datafactory` — external table for Billing.Funding
- `BI_DB_dbo.External_etoro_Dictionary_Deposittype` — external table for Dictionary.Deposittype
- `BI_DB_dbo.External_etoro_Billimg_ProtocolMIDSettings` — external table for Billing.ProtocolMIDSettings (note: "Billimg" typo in table name)
- `BI_DB_dbo.External_etoro_Billing_Depot` — external table for Billing.Depot
- `BI_DB_dbo.External_etoro_Billing_ConversionFeeOverride` — external table for conversion fee overrides

**Action**: These are pass-through external tables pointing to production. Column descriptions for fields sourced from these are tagged Tier 2 where no upstream wiki was available. If production wikis for `Billing.DepositRollbackTracking`, `Dictionary.Deposittype`, `Billing.ProtocolMIDSettings`, `Billing.Depot`, or `Billing.ConversionFeeOverride` are created in the future, upgrade relevant columns to Tier 1.

### 3. HCAmountUSD Source Verification
- `HCAmountUSD` is sourced from `History.Credit.TotalCashChange` (CreditTypeID=1). This is the net USD cash change for the deposit credit event, which may differ from `Amount * ExchangeRate` due to rounding, fee deductions, or partial processing.
- **Action**: Confirm whether HCAmountUSD should exactly equal the deposit's USD equivalent or if differences are expected and intentional.

### 4. DepositRollbackTracking TOP 1 Without Partition
- The SP uses `SELECT TOP 1 ... FROM DepositRollbackTracking WHERE IsCanceled=0 ORDER BY RollbackID DESC` without a per-deposit partition. This returns the SINGLE most recent non-canceled rollback across ALL deposits, not per-deposit.
- **Action**: Verify whether this is intentional (global latest rollback) or a potential bug (should be partitioned by DepositID). The LEFT JOIN on DepositID downstream may mitigate this, but it means only one deposit's rollback tracking is ever used per SP execution.

### 5. UC Migration Status
- This table is not migrated to Unity Catalog. Marked as `_Not_Migrated`.
- **Action**: Confirm whether UC migration is planned or if this remains a Synapse-only audit table.
