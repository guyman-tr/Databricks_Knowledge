# BI_DB_AML_BI_Alerts_New_Singapore — Review Needed

**Schema**: BI_DB_dbo | **Reviewed**: 2026-04-22 | **Batch**: 43

## Items Requiring Reviewer Attention

### RQ-01 — FCA Population Dominance
75.4% of rows belong to FCA regulation despite this being a MAS/Singapore-focused table. This is because the population filter uses `RegulationID=13 OR DesignatedRegulationID=13` — customers with a Singapore designation but non-MAS primary regulation are included. Reviewer should confirm:
- Is this the intended behavior from a compliance perspective?
- Should downstream consumers filter to `Regulation = 'MAS'` only, or use the full table?

### RQ-02 — SGNew011A Historical Data Quality
The SP header documents a bug (2025-05-21): `SGNEW011A alerts - wrongly taking answers from Q15 instead of Q18`. This means all SGNew011A alert rows before 2025-05-21 may be based on incorrect KYC question answers. Reviewer should confirm:
- Were historical SGNew011A rows retroactively corrected, or do bad rows remain?
- Should a data quality flag be applied to SGNew011A rows before 2025-05-21?

### RQ-03 — AdditionalInfoExpiryDate Source Table
`AdditionalInfoExpiryDate` is populated from an expiry date table for SGNew028, referenced as `nep.LatestExpiryDate` in the SP. The exact source table name was not captured from SP code. Reviewer should confirm:
- What is the full source table/view name for document expiry dates?
- Is it in BI_DB_dbo, external, or from BackOffice?

### RQ-04 — SGNew024/SGNew028/SGNew029 Not in Live Data
Three alert types (SGNew024: U-Turn of Funds, SGNew028: Expiring ID, SGNew029: Buy & Transfer Out Cryptos) show zero rows in live data as of 2026-04-03. Reviewer should confirm:
- Are these alerts genuinely firing zero rows (correct), or are they disabled/broken?
- SGNew028 may be conditionally active only when document expiry dates are near — is this expected?

### RQ-05 — AlertDate Type Mismatch
`AlertDate` is declared as `datetime` in the DDL but only stores date-level precision (time = 00:00:00). The base table `BI_DB_AML_BI_Alerts_New` uses `date` type. Reviewer should confirm whether the datetime type is intentional or a historical oversight.

### RQ-06 — CID bigint vs int
`CID` is `bigint` here vs `int` in `BI_DB_AML_BI_Alerts_New` and `BI_DB_AML_BI_Alerts_New_Master_SubAccount`. This prevents seamless UNION operations across the three tables. Reviewer should confirm whether type alignment is planned.

### RQ-07 — UC Migration Status
`UC Target: Not Migrated`. Reviewer should confirm whether this table is in scope for Unity Catalog migration.

## Tier 4 Items

None — all columns sourced with clear SP code evidence.

## Cross-Schema Dependencies

Changes to these tables may break `SP_AML_BI_Alerts_New_Singapore`:
- `DWH_dbo.Fact_SnapshotCustomer` — MAS population and risk classification
- `DWH_dbo.Fact_BillingDeposit` / `Fact_BillingWithdraw` — deposit/withdrawal aggregation
- `DWH_dbo.Fact_CustomerAction` — login, deposit, cashout event detection
- `DWH_dbo.Dim_Position` — trading activity check for dormancy
- `BI_DB_dbo.BI_DB_KYC_Panel` — Q9/Q15/Q18 KYC answers
- `DWH_dbo.Dim_*` (Regulation, Country, PlayerStatus, PlayerLevel, AccountType, Customer, EvMatchStatus, RiskClassification)

## SP Author

SP_AML_BI_Alerts_New_Singapore — Author: Pavlina Masoura (2025-02-20). Last modified: 2025-08-25.
