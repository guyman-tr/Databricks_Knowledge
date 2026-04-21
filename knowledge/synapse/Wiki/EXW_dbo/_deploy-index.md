---
schema: EXW_dbo
total_objects: 62
with_uc_target: 13
knowledge_only_stubs: 48
skipped_objects: 1
skipped: 1
last_updated: 2026-04-21
status: Generated (not yet deployed)
---

# EXW_dbo Deploy Index

## Summary

| Metric | Value |
|--------|-------|
| **Schema** | EXW_dbo |
| **Total Documented** | 62 |
| **With UC Target** | 13 |
| **Knowledge-only Stubs** | 48 |
| **Skipped (no DDL)** | 1 |
| **Last Updated** | 2026-04-21 |
| **Deploy Status** | Generated — not yet deployed to UC |

---

## Objects With UC Targets (13)

| # | Object | UC Target | Schema | Classification | Cols | Status |
|---|--------|-----------|--------|----------------|------|--------|
| 1 | EXW_C2F_E2E | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | bi_db | Non-standard | 103 | Generated |
| 2 | EXW_C2P_E2E | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` | bi_db | Non-standard | 90 | Generated |
| 3 | EXW_CompensationClosingCountries | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries` | bi_db | Non-standard | 22 | Generated |
| 4 | EXW_DimUser | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser` | bi_db | Non-standard | 21 | Generated |
| 5 | EXW_EthFeeSent_Blockchain | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain` | bi_db | Non-standard | 19 | Generated |
| 6 | EXW_FactTransactions | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` | bi_db | Non-standard | 45 | Generated |
| 7 | EXW_FinanceReportsBalancesNew | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` | bi_db | Non-standard | 37 | Generated |
| 8 | EXW_Inventory_Snapshot_History | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history` | bi_db | Non-standard | 18 | Generated |
| 9 | EXW_UserSettingsWalletAllowance | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance` | bi_db | Non-standard | 12 | Generated |
| 10 | EXW_V_RedeemReconciliation | `main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation` | wallet | Non-standard | 51 | Generated |
| 11 | EXW_WalletEntity | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity` | bi_db | Non-standard | 14 | Generated |
| 12 | EXW_WalletInventory | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory` | bi_db | Non-standard | 19 | Generated |
| 13 | GetProviderUserIDNormalized | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized` | bi_db | Non-standard | 7 | Generated |

---

## Knowledge-Only Stubs (48)

Objects without UC gold export. ALTER files contain business summary only — no executable statements.

| # | Object | Type |
|---|--------|------|
| 1 | EXW_30DayBalanceExtract | Table |
| 2 | EXW_AMLProviderID | Table |
| 3 | EXW_AML_Users_Report | Table |
| 4 | EXW_Aml_Limited_Accounts | Table |
| 5 | EXW_Coin_Transfer_Allowed_Country | Table |
| 6 | EXW_Conversion_Allowed_Country | Table |
| 7 | EXW_DimUser_Enriched | Table |
| 8 | EXW_ECPBank | Table |
| 9 | EXW_EOMReportingBalances | Table |
| 10 | EXW_ETH_FeeData_Blockchain | Table |
| 11 | EXW_FCA_UserLogin | Table |
| 12 | EXW_FactBalance | Table |
| 13 | EXW_FactConversions | Table |
| 14 | EXW_FactPayments | Table |
| 15 | EXW_FactRedeemTransactions | Table |
| 16 | EXW_FirstTimeWalletsAndUsers | Table |
| 17 | EXW_InternalWallet | Table |
| 18 | EXW_PaymentReconciliation | Table |
| 19 | EXW_Payment_Allowed_Country | Table |
| 20 | EXW_RedeemReconciliation | Table |
| 21 | EXW_ReimbursementFollowUp | Table |
| 22 | EXW_ReimbursementSumTable | Table |
| 23 | EXW_ReportingBalances | Table |
| 24 | EXW_SimplexChargebacks | Table |
| 25 | EXW_SimplexMapping | Table |
| 26 | EXW_Staking_Allowed_Country | Table |
| 27 | EXW_TestUsers | Table |
| 28 | EXW_Transactions_Monthly | Table |
| 29 | EXW_UserCalculatedBalance | Table |
| 30 | EXW_WalletClosedCountryProjects | Table |
| 31 | EXW_WalletElligibleCountries | Table |
| 32 | EXW_WalletLogins | Table |
| 33 | EXW_WalletRegulation | Table |
| 34 | EXW_WalletUsers_30_Days | Table |
| 35 | Hourly_CustomerBalances | Table |
| 36 | Hourly_OmnibusBalances | Table |
| 37 | Hourly_RedeemActivity | Table |
| 38 | Hourly_Transactions | Table |
| 39 | Hourly_WalletAllocations | Table |
| 40 | Hourly_WalletInventory | Table |
| 41 | New_UsersAndWallets_Inventory | Table |
| 42 | Staking_BI_Version_ETH_Transactions | Table |
| 43 | Staking_BI_Version_WalletUserRewards | Table |
| 44 | Staking_ETH_Rewards_Parameters | Table |
| 45 | Staking_WalletUserRewards | Table |
| 46 | External_WalletDB_Wallet_TransactionsView | External Table |
| 47 | RemovePrefix | Function |
| 48 | RemoveSuffix | Function |
