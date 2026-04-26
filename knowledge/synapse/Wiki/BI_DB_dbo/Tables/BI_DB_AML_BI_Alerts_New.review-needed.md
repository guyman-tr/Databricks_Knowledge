# BI_DB_AML_BI_Alerts_New — Review Needed

**Schema**: BI_DB_dbo | **Reviewed**: 2026-04-22 | **Batch**: 43

## Items Requiring Reviewer Attention

### RQ-01 — AlertType Code Inventory Completeness
The SP contains 30+ alert type branches identified from code structure, but the full canonical list was derived from live data sampling (top 30 by volume). Reviewer should confirm:
- Are there additional AlertType codes active in production not captured in the top-30 sample?
- Deactivated codes (HIGHRISK001, YOUNG001, EP001, EP002) — confirm these are truly dormant and should only appear in pre-deactivation history rows.

### RQ-02 — AlertCategory Naming: "MIMO - Deposits" vs "MIMO - Deposit"
Live data shows both `MIMO - Deposit` (singular) and `MIMO - Deposits` (plural) as distinct AlertCategory values, with the plural form holding ~14.6% of rows. This appears intentional (two different rule families), but a reviewer should confirm:
- Is this a data quality artifact (inconsistent SP naming across branches) or deliberate distinction?
- If artifact: which form is canonical and should a normalization be applied?

### RQ-03 — RiskScoreName Source Authentication
RiskScoreName is sourced from `External_RiskClassification_dbo_V_RiskClassificationDataLake`, which is an external/federated table. The lineage documents this as T2 passthrough. Reviewer should confirm:
- Is the external table contract stable (schema won't change without BI_DB notification)?
- Are "Low/Medium/High/None" the only valid values, or is the classification expanding?

### RQ-04 — HasWallet Timing Question
HasWallet is read from `Dim_Customer` at SP run time (current snapshot). This means the value in a historical alert row reflects the customer's wallet status at the time the SP ran — not necessarily their wallet status today. Reviewer should confirm:
- Is this understood by AML consumers? A customer may have had no wallet when an alert fired but has one now — the stored row would show HasWallet=0.

### RQ-05 — Total_Alerts_of_TheCategory Off-By-One Awareness
The counter is computed as `COUNT(prior rows WHERE CID=x AND AlertType=y) + 1`. This means the first firing shows 1, the second shows 2, etc. — correct. However, because the SP uses DELETE+INSERT (not upsert), re-running for the same @Date deletes and rewrites the day's rows, which would re-count prior-date rows only (not same-day). Reviewer should confirm:
- If SP is re-run for the same date (e.g., data fix), does the counter remain correct or can it drift?

### RQ-06 — UC Migration Status
`UC Target: Not Migrated`. Reviewer should confirm whether this table is in scope for Unity Catalog migration and whether a target Delta table or notebook has been planned.

## Tier 4 Items (Best-Guess / Needs Confirmation)

None identified — all columns have T1 or T2 sourcing with clear SP evidence.

## Cross-Schema Dependencies (Informational)

The following cross-schema sources feed this table. Changes to their schemas may break `SP_AML_BI_Alerts_New`:
- `DWH_dbo.Fact_SnapshotCustomer` — customer dimension spine
- `DWH_dbo.Fact_BillingDeposit`, `Fact_BillingWithdraw` — deposit/withdrawal history
- `eMoney_dbo.eMoney_Fact_Transaction_Status` — eTM net flows
- `DWH_dbo.Dim_*` (Regulation, Country, PlayerStatus, PlayerLevel, AccountType, Customer, EvMatchStatus, FundingType)
- `BI_DB_dbo.BI_DB_KYC_Panel` — Q10/Q11 economic profile answers
- `External_RiskClassification_dbo_V_RiskClassificationDataLake` — risk scoring

## SP Author

SP_AML_BI_Alerts_New — Author: Pavlina Masoura. Last modified: 2026-03-30.
