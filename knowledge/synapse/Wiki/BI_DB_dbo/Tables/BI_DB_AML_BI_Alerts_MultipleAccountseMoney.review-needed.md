# BI_DB_AML_BI_Alerts_MultipleAccountseMoney — Review Needed

**Schema**: BI_DB_dbo | **Reviewed**: 2026-04-22 | **Batch**: 43

## Items Requiring Reviewer Attention

### RQ-01 — ID Column Semantics Confirmation
`ID` comes from `BI_DB_OPS_MultipleAccounts` and represents a multi-account group key. The SP counter uses `n.ID = f.ID AND n.AlertType = f.AlertType` — so `Total_Alerts_of_TheCategory` tracks firings at group level. Reviewer should confirm:
- Is `ID` stable across time (same person always gets the same ID)?
- Or can the same person's group get a new ID if accounts are re-linked?

### RQ-02 — eMoney CRA vs Platform Risk
`RiskScoreName` stores the platform risk (`Dim_RiskClassification`), but `IBAN MA003` triggers on the eMoney CRA risk (`eMoney_Customer_Risk_Assessment.ClientRisk = 'High'`). These are two separate risk systems. Reviewer should confirm:
- Are consumers aware that RiskScoreName does NOT reflect the eMoney CRA used in the alert trigger?
- Should the eMoney CRA label also be stored in this table for AML reviewer context?

### RQ-03 — AllCIDs String Stability
`AllCIDs` is computed via `STRING_AGG` at SP run time from `#finalwithIBANS`. If accounts are added or removed from the group, future rows will show a different AllCIDs value for the same ID. Historical rows retain the snapshot from their insert date. Reviewer should confirm:
- Is this point-in-time behavior understood by AML consumers?

### RQ-04 — TotalDepositsLifetime/TotalCashoutsLifetime eMoney-Only Scope
These pre-aggregated columns reflect only eMoney transactions (`eMoney_Dim_Transaction`), not platform deposits (`Fact_BillingDeposit`). AML reviewers may assume "lifetime deposits" means all platform activity. Reviewer should confirm:
- Is the eMoney-only scope adequately communicated in AML review workflows?

### RQ-05 — Only 12 Distinct Master CIDs
Live data shows only 12 distinct MasterAccountCIDs, suggesting a small number of account groups are generating almost all alerts. Reviewer should confirm whether this reflects the true population size or whether the population filter (>1 IBAN across accounts) is more restrictive than intended.

### RQ-06 — BI_DB_OPS_MultipleAccounts Dependency
The entire population spine depends on `BI_DB_dbo.BI_DB_OPS_MultipleAccounts`, which is itself a pre-computed table. If that table has data quality issues or stale data, this alert table inherits those issues. Reviewer should confirm the refresh cadence and ownership of `BI_DB_OPS_MultipleAccounts`.

### RQ-07 — UC Migration Status
`UC Target: Not Migrated`. Reviewer should confirm whether this table is in scope for Unity Catalog migration.

## Tier 4 Items

None — all columns sourced with clear SP code evidence.

## Cross-Schema Dependencies

Changes to these tables may break `SP_AML_BI_Alerts_MultipleAccountseMoney`:
- `BI_DB_dbo.BI_DB_OPS_MultipleAccounts` — multi-account group spine
- `eMoney_dbo.eMoney_Dim_Account` — IBAN active status and count
- `eMoney_dbo.eMoneyClientBalance` — eMoney balance at @Date
- `eMoney_dbo.eMoney_Customer_Risk_Assessment` — eMoney CRA risk label
- `eMoney_dbo.eMoney_Dim_Transaction` — deposit and cashout aggregation
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot
- `DWH_dbo.Dim_*` (Regulation, Country, PlayerStatus, PlayerLevel, AccountType, Customer, RiskClassification, EvMatchStatus)

## SP Author

SP_AML_BI_Alerts_MultipleAccountseMoney — Author: Pavlina Masoura (2025-05-05). Last modified: 2025-07-07 (removed risk classification change condition from IBAN MA003).
