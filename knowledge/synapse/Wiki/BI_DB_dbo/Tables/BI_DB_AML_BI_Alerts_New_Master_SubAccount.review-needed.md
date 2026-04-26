# BI_DB_AML_BI_Alerts_New_Master_SubAccount — Review Needed

**Schema**: BI_DB_dbo | **Reviewed**: 2026-04-22 | **Batch**: 43

## Items Requiring Reviewer Attention

### RQ-01 — Risk Source Discrepancy vs Base Table
`RiskScoreName` in this table is sourced from `DWH_dbo.Dim_RiskClassification` (via Fact_SnapshotCustomer change history with LAG()), while the base table `BI_DB_AML_BI_Alerts_New` uses `External_RiskClassification_dbo_V_RiskClassificationDataLake`. This means:
- The vocabulary includes 'Unacceptable' here vs 'None' in the base table
- The recency/lag behavior differs (change-history last row vs. current external snapshot)
Reviewer should confirm: is this discrepancy intentional design, or should both tables use the same risk source?

### RQ-02 — AlertCategory Trailing Space
All 12 alert branches write `'OnBoarding'` as AlertCategory. Earlier SP branches in some code paths write `'OnBoarding '` (with trailing space). The live data should be checked for contamination. Reviewer should confirm via: `SELECT DISTINCT AlertCategory, LEN(AlertCategory) FROM BI_DB_AML_BI_Alerts_New_Master_SubAccount`

### RQ-03 — MA008 Recurring Semantics
MA008 fires every time the combined lifetime deposits cross an additional $1M milestone above $2M. Unlike all other alerts, there is no first-time filter. Reviewer should confirm:
- Is Total_Alerts_of_TheCategory always 1 for MA008 rows (since the counter uses MasterAccountCID and each $1M milestone is a different threshold date)?
- Or can a MasterAccountCID have multiple MA008 rows with increasing Total_Alerts values?

### RQ-04 — AlertDate Coverage Gap
Live data shows `MIN(AlertDate) = 2025-01-01` — the SP was first deployed in February 2025 (per header comment `Date: 2025/02/10`) but the historical back-fill loop ran from 2025-01-01. The gap between SP creation and first backfill date should be understood by consumers. Reviewer should confirm whether 2025-01-01 represents complete historical coverage.

### RQ-05 — External_etoro_BackOffice_Customer Lifecycle
MasterAccountCID relationships are defined in `BI_DB_dbo.External_etoro_BackOffice_Customer`. If a customer later dissolves their master/sub relationship, existing alert rows in this table still carry the old MasterAccountCID. Reviewer should confirm whether alerts are ever retroactively corrected when account relationships change.

### RQ-06 — UC Migration Status
`UC Target: Not Migrated`. Reviewer should confirm whether this table is in scope for Unity Catalog migration.

## Tier 4 Items

None — all columns sourced with clear SP code evidence.

## Cross-Schema Dependencies

Changes to these tables may break `SP_AML_BI_Alerts_New_Master_SubAccount`:
- `BI_DB_dbo.External_etoro_BackOffice_Customer` — master/sub relationship spine
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot; risk classification history
- `DWH_dbo.Dim_RiskClassification` — risk label vocabulary
- `DWH_dbo.Fact_BillingDeposit` — deposit aggregation
- `DWH_dbo.Fact_CustomerAction` (ActionTypeID=7) — deposit event detection
- `BI_DB_dbo.BI_DB_KYC_Panel` — Q10/Q11/Q15 economic profile answers
- `DWH_dbo.Dim_*` (Regulation, Country, PlayerStatus, PlayerLevel, AccountType, Customer, EvMatchStatus)

## SP Author

SP_AML_BI_Alerts_New_Master_SubAccount — Original author: Georgios Kyriakou (2025-02-10). Last modified: 2025-11-10 (Pavlina Masoura — removed employee accounts).
