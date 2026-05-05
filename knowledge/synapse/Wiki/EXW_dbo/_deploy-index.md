---
schema: EXW_dbo
database: Synapse DWH
total_deployable: 61
generated: 0
deployed: 13
failed: 0
stub_only: 48
last_generate_batch: 0
last_deploy_batch: 2
last_updated: "2026-05-05"
---

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | EXW_dbo   |
| **Total deployable**               | 61  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 13         |
| **Stub-only (no UC)**              | 48   |
| **Failed**                         | 0         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 2          |
| **Last updated**                   | 2026-05-03       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## Tables (56)

| Object | Deploy status |
|--------|---------------|
| [EXW_dbo.EXW_30DayBalanceExtract](Tables/EXW_30DayBalanceExtract.md) | Stub only |
| [EXW_dbo.EXW_Aml_Limited_Accounts](Tables/EXW_Aml_Limited_Accounts.md) | Stub only |
| [EXW_dbo.EXW_AML_Users_Report](Tables/EXW_AML_Users_Report.md) | Stub only |
| [EXW_dbo.EXW_AMLProviderID](Tables/EXW_AMLProviderID.md) | Stub only |
| [EXW_dbo.EXW_C2F_E2E](Tables/EXW_C2F_E2E.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_dbo.EXW_C2P_E2E](Tables/EXW_C2P_E2E.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_Coin_Transfer_Allowed_Country](Tables/EXW_Coin_Transfer_Allowed_Country.md) | Stub only |
| [EXW_dbo.EXW_CompensationClosingCountries](Tables/EXW_CompensationClosingCountries.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_Conversion_Allowed_Country](Tables/EXW_Conversion_Allowed_Country.md) | Stub only |
| [EXW_dbo.EXW_DimUser](Tables/EXW_DimUser.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_DimUser_Enriched](Tables/EXW_DimUser_Enriched.md) | Stub only |
| [EXW_dbo.EXW_ECPBank](Tables/EXW_ECPBank.md) | Stub only |
| [EXW_dbo.EXW_EOMReportingBalances](Tables/EXW_EOMReportingBalances.md) | Stub only |
| [EXW_dbo.EXW_ETH_FeeData_Blockchain](Tables/EXW_ETH_FeeData_Blockchain.md) | Stub only |
| [EXW_dbo.EXW_EthFeeSent_Blockchain](Tables/EXW_EthFeeSent_Blockchain.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_FactBalance](Tables/EXW_FactBalance.md) | Stub only |
| [EXW_dbo.EXW_FactConversions](Tables/EXW_FactConversions.md) | Stub only |
| [EXW_dbo.EXW_FactPayments](Tables/EXW_FactPayments.md) | Stub only |
| [EXW_dbo.EXW_FactRedeemTransactions](Tables/EXW_FactRedeemTransactions.md) | Stub only |
| [EXW_dbo.EXW_FactTransactions](Tables/EXW_FactTransactions.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_FCA_UserLogin](Tables/EXW_FCA_UserLogin.md) | Stub only |
| [EXW_dbo.EXW_FinanceReportsBalancesNew](Tables/EXW_FinanceReportsBalancesNew.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_dbo.EXW_FirstTimeWalletsAndUsers](Tables/EXW_FirstTimeWalletsAndUsers.md) | Stub only |
| [EXW_dbo.EXW_InternalWallet](Tables/EXW_InternalWallet.md) | Stub only |
| [EXW_dbo.EXW_Inventory_Snapshot_History](Tables/EXW_Inventory_Snapshot_History.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_Payment_Allowed_Country](Tables/EXW_Payment_Allowed_Country.md) | Stub only |
| [EXW_dbo.EXW_PaymentReconciliation](Tables/EXW_PaymentReconciliation.md) | Stub only |
| [EXW_dbo.EXW_RedeemReconciliation](Tables/EXW_RedeemReconciliation.md) | Stub only |
| [EXW_dbo.EXW_ReimbursementFollowUp](Tables/EXW_ReimbursementFollowUp.md) | Stub only |
| [EXW_dbo.EXW_ReimbursementSumTable](Tables/EXW_ReimbursementSumTable.md) | Stub only |
| [EXW_dbo.EXW_ReportingBalances](Tables/EXW_ReportingBalances.md) | Stub only |
| [EXW_dbo.EXW_SimplexChargebacks](Tables/EXW_SimplexChargebacks.md) | Stub only |
| [EXW_dbo.EXW_SimplexMapping](Tables/EXW_SimplexMapping.md) | Stub only |
| [EXW_dbo.EXW_Staking_Allowed_Country](Tables/EXW_Staking_Allowed_Country.md) | Stub only |
| [EXW_dbo.EXW_TestUsers](Tables/EXW_TestUsers.md) | Stub only |
| [EXW_dbo.EXW_Transactions_Monthly](Tables/EXW_Transactions_Monthly.md) | Stub only |
| [EXW_dbo.EXW_UserCalculatedBalance](Tables/EXW_UserCalculatedBalance.md) | Stub only |
| [EXW_dbo.EXW_UserSettingsWalletAllowance](Tables/EXW_UserSettingsWalletAllowance.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_WalletClosedCountryProjects](Tables/EXW_WalletClosedCountryProjects.md) | Stub only |
| [EXW_dbo.EXW_WalletElligibleCountries](Tables/EXW_WalletElligibleCountries.md) | Stub only |
| [EXW_dbo.EXW_WalletEntity](Tables/EXW_WalletEntity.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_dbo.EXW_WalletInventory](Tables/EXW_WalletInventory.md) | Deployed (Batch 2) — 2026-05-05|
| [EXW_dbo.EXW_WalletLogins](Tables/EXW_WalletLogins.md) | Stub only |
| [EXW_dbo.EXW_WalletRegulation](Tables/EXW_WalletRegulation.md) | Stub only |
| [EXW_dbo.EXW_WalletUsers_30_Days](Tables/EXW_WalletUsers_30_Days.md) | Stub only |
| [EXW_dbo.Hourly_CustomerBalances](Tables/Hourly_CustomerBalances.md) | Stub only |
| [EXW_dbo.Hourly_OmnibusBalances](Tables/Hourly_OmnibusBalances.md) | Stub only |
| [EXW_dbo.Hourly_RedeemActivity](Tables/Hourly_RedeemActivity.md) | Stub only |
| [EXW_dbo.Hourly_Transactions](Tables/Hourly_Transactions.md) | Stub only |
| [EXW_dbo.Hourly_WalletAllocations](Tables/Hourly_WalletAllocations.md) | Stub only |
| [EXW_dbo.Hourly_WalletInventory](Tables/Hourly_WalletInventory.md) | Stub only |
| [EXW_dbo.New_UsersAndWallets_Inventory](Tables/New_UsersAndWallets_Inventory.md) | Stub only |
| [EXW_dbo.Staking_BI_Version_ETH_Transactions](Tables/Staking_BI_Version_ETH_Transactions.md) | Stub only |
| [EXW_dbo.Staking_BI_Version_WalletUserRewards](Tables/Staking_BI_Version_WalletUserRewards.md) | Stub only |
| [EXW_dbo.Staking_ETH_Rewards_Parameters](Tables/Staking_ETH_Rewards_Parameters.md) | Stub only |
| [EXW_dbo.Staking_WalletUserRewards](Tables/Staking_WalletUserRewards.md) | Stub only |

## Views (3)

| Object | Deploy status |
|--------|---------------|
| [EXW_dbo.EXW_V_RedeemReconciliation](Views/EXW_V_RedeemReconciliation.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_dbo.GetProviderUserIDNormalized](Views/GetProviderUserIDNormalized.md) | Deployed (Batch 1) — 2026-05-03|
| [EXW_dbo.V_EXW_C2F_E2E_4Export](Views/V_EXW_C2F_E2E_4Export.md) | Stub only |

## Functions (2)

| Object | Deploy status |
|--------|---------------|
| [EXW_dbo.RemovePrefix](Functions/RemovePrefix.md) | Stub only |
| [EXW_dbo.RemoveSuffix](Functions/RemoveSuffix.md) | Stub only |
