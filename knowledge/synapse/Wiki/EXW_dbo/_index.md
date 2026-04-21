---
schema: EXW_dbo
pending: 0
documented: 62
queued: 0
failed: 0
skipped: 1
blacklisted: 5
last_batch: 12
quality_avg: 8.80
last_updated: 2026-04-20
notes: "Batch 12 complete — FINAL BATCH (wiki-only): EXW_Inventory_Snapshot_History (18-col daily crypto snapshot, all T2, SP_EXW_Inventory_Snapshot_History by Inessa Kontorovich 2020, aggregates EXW_WalletInventory by (crypto, WalletStatus) into 5 WalletStatus values, 31K rows 2020-2026, 12 cryptos), EXW_ReportingBalances (40-col, 0 rows — schema shell, planned successor to EXW_EOMReportingBalances, external ETL unknown, all T4), EXW_EOMReportingBalances (44-col, 25.4M rows 23 monthly snapshots 2021-11-30 to 2023-09-30, decommissioned, external ETL, all T4, KnownIssueWallet correction logic), EXW_V_RedeemReconciliation (51-col view of EXW_RedeemReconciliation, filter=BothSidesEntry+TransactionDone, 1.117M rows, 7 deprecated cols excluded, all column renames from etoro-/Wallet- prefix to camelCase), V_EXW_C2F_E2E_4Export (103-col full passthrough view of EXW_C2F_E2E, 2 type casts: C2FCorrelationID+SentWalletID uniqueidentifier→varchar(50), no filter, export compatibility view)."
---

# EXW_dbo Schema Index

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | EXW_dbo |
| **Domain** | Crypto Wallet (eToro Wallet Exchange) |
| **Total Objects** | 66 (57 tables + 3 views + 2 functions + 1 skipped + 5 blacklisted) |
| **Active (to document)** | 62 |
| **Documented** | 62 (100%) |
| **Failed** | 0 |
| **Pending** | 0 |
| **Skipped (no DDL)** | 1 |
| **Blacklisted (backups)** | 5 |
| **Last Updated** | 2026-04-20 |

---

## Completed Batches

### Batch 12 — 2026-04-20 — 5 objects (wiki-only) — FINAL BATCH

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_Inventory_Snapshot_History | PASS | 9.05/10 | 9.05/10 |
| 2 | EXW_dbo.EXW_ReportingBalances | PASS | 8.35/10 | 8.35/10 |
| 3 | EXW_dbo.EXW_EOMReportingBalances | PASS | 9.05/10 | 9.05/10 |
| 4 | EXW_dbo.EXW_V_RedeemReconciliation | PASS | 9.55/10 | 9.55/10 |
| 5 | EXW_dbo.V_EXW_C2F_E2E_4Export | PASS | 9.60/10 | 9.60/10 |

**Batch Average: 9.12/10** | All 5 PASS | 0 regenerations | Carry-forward: EXW_Inventory_Snapshot_History SP authored by Inessa Kontorovich (2020-05-21), aggregates WalletInventory into 5 WalletStatus values + 12 cryptos; EXW_ReportingBalances = 0 rows (schema shell, planned EOM successor, ETL unknown — escalate to data engineering); EXW_EOMReportingBalances decommissioned Sep-2023 (25.4M rows, 23 monthly snapshots, KnownIssueWallet correction rule: use DevReportBalance for KnownIssueWallet=1); EXW_V_RedeemReconciliation filter = BothSidesEntry+TransactionDone (1.117M completed rows), 7 deprecated cols excluded (all Wallet analytics), 51-col clean rename surface; V_EXW_C2F_E2E_4Export = full passthrough 103 cols, only 2 type casts (uniqueidentifier→varchar(50) for C2FCorrelationID + SentWalletID, export compat). **EXW_dbo schema: FULLY DOCUMENTED (62/62 active objects).**

---

### Batch 11 — 2026-04-20 — 5 objects (wiki-only)

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_SimplexMapping | PASS | 8.2/10 | 8.35/10 |
| 2 | EXW_dbo.EXW_SimplexChargebacks | PASS | 8.5/10 | 8.85/10 |
| 3 | EXW_dbo.EXW_ECPBank | PASS | 8.6/10 | 9.05/10 |
| 4 | EXW_dbo.EXW_FactPayments | PASS | 9.0/10 | 9.3/10 |
| 5 | EXW_dbo.EXW_PaymentReconciliation | PASS | 8.9/10 | 9.15/10 |

**Batch Average: 8.64/10** | All 5 PASS | 0 regenerations | Carry-forward: Simplex ecosystem = 3-table cross-reference chain via UTI/long_id/ARN; EXW_SimplexMapping.long_id = EXW_ECPBank.uti = EXW_ECPBank.merch_tran_ref_ (15-char prefix) = EXW_PaymentReconciliation.UTI; EXW_FactPayments accumulating snapshot (553K rows, 99K PaymentIDs, ~5.57 rows/payment); EXW_PaymentReconciliation final-state (99,243 rows = one per payment); ECPAmout DDL typo (missing 'n'); EXW_ECPBank.transaction_date NULL post-2020, posting_date reliable; merchant_no_ has 3 format variants (all same Gibraltar merchant); EXW_SimplexChargebacks only 5 rows (2020-03-15 one-time load, all 2019 Visa chargebacks); EXW_SimplexMapping.stage_drop has 35 distinct status values; both FactPayments and PaymentReconciliation have 167-payment gap (FactPayments=99,410 PaymentIDs vs Reconciliation=99,243).

---

### Batch 10 — 2026-04-20 — 8 objects (wiki-only)

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_WalletEntity | PASS | 9.3/10 | wiki-only |
| 2 | EXW_dbo.EXW_WalletUsers_30_Days | PASS | 8.8/10 | wiki-only |
| 3 | EXW_dbo.EXW_Staking_Allowed_Country | PASS | 8.5/10 | wiki-only |
| 4 | EXW_dbo.EXW_Payment_Allowed_Country | PASS | 8.4/10 | wiki-only |
| 5 | EXW_dbo.EXW_Conversion_Allowed_Country | PASS | 8.3/10 | wiki-only |
| 6 | EXW_dbo.EXW_FCA_UserLogin | PASS | 9.2/10 | wiki-only |
| 7 | EXW_dbo.RemovePrefix | PASS | 9.3/10 | wiki-only |
| 8 | EXW_dbo.RemoveSuffix | PASS | 9.3/10 | wiki-only |

**Batch Average: 8.89/10** | All 8 PASS | 0 regenerations | Carry-forward: EXW_WalletEntity entity name list driven by BI_DB_dbo.External_WalletDB_Dictionary_EtoroLegalEntities (not hardcoded in SP); WalletEntity JoinDate=MIN(CustomerWalletsView.Occurred), not eToro registration; TermsAndConditionTime stores full datetime despite name; 3 Allowed_Country tables all-zero flags (staking/Simplex payments/conversions discontinued); EXW_FCA_UserLogin name is misnomer (all wallet users, not FCA-only); RemovePrefix=after-last-delimiter, RemoveSuffix=before-first-delimiter.

---

### Batch 9 — 2026-04-20 — 3 objects (wiki-only)

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_C2F_E2E | — | —/10 | wiki-only |
| 2 | EXW_dbo.EXW_C2P_E2E | — | —/10 | wiki-only |
| 3 | EXW_dbo.EXW_RedeemReconciliation | — | —/10 | wiki-only |

**Batch Mode: wiki-only (no ALTER scripts generated)** | 3 objects | 0 regenerations | Carry-forward: SP_EXW_C2F_E2E dual-writes EXW_C2F_E2E + EXW_C2P_E2E in one run (changes affect both); EXW_C2P_E2E has 90 columns (not 92 — frontmatter corrected); EXW_C2P_E2E SentTransactionID=int (vs bigint in C2F), UpdateDate nullable (vs NOT NULL in C2F), ConversionCycle binary (Full Cycle/Other only, not 10-state); IsGermanBaFin in EXW_RedeemReconciliation always 0 (V_GermanBaFin query commented out); space-in-name columns throughout EXW_RedeemReconciliation require bracket quoting; two DDL typos: `[eToro - AmountOnCloseUSD]` (capital T) and `[Wallet - SentTTXBlockchainFees]` (double T); Billing.vWithdrawToFunding has no upstream wiki (5 cols T2).

---

### Batch 8 — 2026-04-20 — 6 objects

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.Staking_ETH_Rewards_Parameters | PASS | 7.5/10 | 8.90 |
| 2 | EXW_dbo.Staking_WalletUserRewards | PASS | 8.0/10 | 9.05 |
| 3 | EXW_dbo.Staking_BI_Version_WalletUserRewards | PASS | 8.2/10 | 9.00 |
| 4 | EXW_dbo.Staking_BI_Version_ETH_Transactions | PASS | 8.0/10 | 8.68 |
| 5 | EXW_dbo.EXW_WalletLogins | PASS | 8.5/10 | 8.93 |
| 6 | EXW_dbo.EXW_InternalWallet | PASS | 8.8/10 | 9.13 |

**Batch Average: 8.17/10** | All 6 PASS | 0 regenerations required | Carry-forward: No SP for any Staking_* table (external ETL — Databricks/ADF not in SSDT); 8 T1 cols in Staking_BI_Version_ETH_Transactions from WalletDB.Staking.Staking + StakingTransactions upstream wikis; 6 T1 cols in EXW_InternalWallet from CustomerWalletsView upstream wiki; UpdateDate in EXW_InternalWallet maps to WalletAssets.Occurred (wallet creation timestamp, NOT ETL time); BI version of ETH Transactions row count unknown (no MCP query); ETH staking program frozen May 2023 — all Staking_* tables historical archive.

---

### Batch 7 — 2026-04-20 — 4 objects

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.Hourly_OmnibusBalances | PASS | 8.7/10 | 9.375 |
| 2 | EXW_dbo.Hourly_RedeemActivity | PASS | 8.5/10 | 9.075 |
| 3 | EXW_dbo.Hourly_WalletInventory | PASS | 8.8/10 | 9.050 |
| 4 | EXW_dbo.Hourly_WalletAllocations | PASS | 9.0/10 | 9.375 |

**Batch Average: 8.75/10** | All 4 PASS | 0 regenerations required | Carry-forward: AllocationDate always=ReportDate bug in WalletAllocations (RN-001 HIGH); TodayAllocationPace formula inverted in WalletInventory; ERC-20 excluded from WalletInventory but included in WalletAllocations (by design); 12 T1 columns in WalletAllocations from CustomerWalletsView upstream wiki; CrytpoType column name typo (baked into DDL).

---

### Batch 6 — 2026-04-20 — 6 objects

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.New_UsersAndWallets_Inventory | PASS | 8.6/10 | 9.45 |
| 2 | EXW_dbo.EXW_ETH_FeeData_Blockchain | PASS | 8.5/10 | 8.90 |
| 3 | EXW_dbo.EXW_WalletElligibleCountries | PASS | 8.8/10 | 9.20 |
| 4 | EXW_dbo.EXW_ReimbursementFollowUp | PASS | 8.5/10 | 9.05 |
| 5 | EXW_dbo.Hourly_CustomerBalances | PASS | 8.7/10 | 9.25 |
| 6 | EXW_dbo.Hourly_Transactions | PASS | 8.6/10 | 9.25 |

**Batch Average: 8.63/10** | All 6 PASS | 0 regenerations required | Carry-forward: EXW_ReimbursementFollowUp has 13 space-in-name columns + double-space gotcha; today-2 zero-balance inconsistency in Hourly_CustomerBalances; ReciverAddress typo in Hourly_Transactions; SP_EXW_CompensationClosingCountries writes EXW_ReimbursementFollowUp + EXW_ReimbursementSumTable in same run.

---

### Batch 4 — 2026-04-20 — 6 objects

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_FinanceReportsBalancesNew | PASS | 8.8/10 | 8.35 |
| 2 | EXW_dbo.EXW_FactRedeemTransactions | PASS | 8.7/10 | 9.55 |
| 3 | EXW_dbo.EXW_CompensationClosingCountries | PASS | 8.5/10 | 9.15 |
| 4 | EXW_dbo.EXW_Aml_Limited_Accounts | PASS | 9.2/10 | 9.15 |
| 5 | EXW_dbo.EXW_ReimbursementSumTable | PASS | 9.35/10 | 9.25 |
| 6 | EXW_dbo.EXW_Coin_Transfer_Allowed_Country | PASS | 9.65/10 | 9.75 |

**Batch Average: 9.20/10** | All 6 PASS | 0 regenerations required | Carry-forward: no snapshot stats in element descriptions (enforced from Obj #1 D3 deduction); T1 must include full verbatim upstream text (enforced from Obj #1 D2 deduction)

---

### Batch 5 — 2026-04-20 — 6 objects (1 recovery + 5 new)

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.GetProviderUserIDNormalized | PASS | 8.8/10 | 8.80 (recovery) |
| 2 | EXW_dbo.EXW_EthFeeSent_Blockchain | PASS | 8.7/10 | 8.90 |
| 3 | EXW_dbo.EXW_FirstTimeWalletsAndUsers | PASS | 8.6/10 | 8.90 |
| 4 | EXW_dbo.EXW_Transactions_Monthly | PASS | 8.3/10 | 8.30 (DEPRECATED) |
| 5 | EXW_dbo.EXW_UserCalculatedBalance | PASS | 8.3/10 | 8.30 (DEPRECATED) |
| 6 | EXW_dbo.EXW_30DayBalanceExtract | PASS | 8.7/10 | 8.90 |

**Batch Average: 8.57/10** | All 6 PASS | 0 regenerations required | Carry-forward: both deprecated table SPs have commented-out bodies (NO-OP); EXW_Transactions_Monthly and EXW_UserCalculatedBalance frozen 2023-12-31.

---

### Batch 3 — 2026-04-20 — 4 objects

| # | Object | Quality | Score | P16 |
|---|--------|---------|-------|-----|
| 1 | EXW_dbo.EXW_FactConversions | PASS | 8.4/10 | 8.35 |
| 2 | EXW_dbo.EXW_WalletInventory | PASS | 9.4/10 | 9.35 |
| 3 | EXW_dbo.External_WalletDB_Wallet_TransactionsView | PASS | 8.1/10 | 8.05 |
| 4 | EXW_dbo.EXW_FactTransactions | PASS | 9.4/10 | 9.45 |

**Batch Average: 8.83/10** | All 4 PASS | 0 regenerations required | T1 fidelity issues noted on Object #3 (15/22 non-verbatim — fixed in next batch context)

---

### Batch 2 — 2026-04-20 — 3 objects

| # | Object | Quality | Score |
|---|--------|---------|-------|
| 1 | EXW_dbo.EXW_DimUser_Enriched | PASS | 8.6/10 |
| 2 | EXW_dbo.EXW_UserSettingsWalletAllowance | PASS | 9.3/10 |
| 3 | EXW_dbo.EXW_AML_Users_Report | PASS | 9.7/10 |

**Batch Average: 9.2/10** | All 3 PASS | 0 regenerations required

---

### Batch 1 — 2026-04-20 — 6 objects

| # | Object | Quality | Score |
|---|--------|---------|-------|
| 1 | EXW_dbo.EXW_WalletClosedCountryProjects | PASS | 8.45/10 |
| 2 | EXW_dbo.EXW_TestUsers | PASS | 9.65/10 |
| 3 | EXW_dbo.EXW_DimUser | PASS | 8.83/10 |
| 4 | EXW_dbo.EXW_AMLProviderID | PASS | 8.93/10 |
| 5 | EXW_dbo.EXW_FactBalance | PASS | 8.93/10 |
| 6 | EXW_dbo.EXW_WalletRegulation | PASS | 8.93/10 |

**Batch Average: 8.95/10** | All 6 PASS | 0 regenerations required

---

## Tables (55)

| Object | Quality | Status |
|--------|---------|--------|
| EXW_dbo.EXW_TestUsers | 9.65/10 | Done (Batch 1, #2) |
| EXW_dbo.EXW_WalletClosedCountryProjects | 8.45/10 | Done (Batch 1, #1) |
| EXW_dbo.EXW_DimUser | 8.83/10 | Done (Batch 1, #3) |
| EXW_dbo.EXW_AMLProviderID | 8.93/10 | Done (Batch 1, #4) |
| EXW_dbo.EXW_Aml_Limited_Accounts | 9.15/10 | Done (Batch 4, #4) |
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | 8.1/10 | Done (Batch 3, #3) |
| EXW_dbo.EXW_FactTransactions | 9.4/10 | Done (Batch 3, #4) |
| EXW_dbo.EXW_AML_Users_Report | 9.7/10 | Done (Batch 2, #3) |
| EXW_dbo.EXW_UserSettingsWalletAllowance | 9.3/10 | Done (Batch 2, #2) |
| EXW_dbo.EXW_DimUser_Enriched | 8.6/10 | Done (Batch 2, #1) |
| EXW_dbo.EXW_ReimbursementFollowUp | 8.5/10 | Done (Batch 6, #4) |
| EXW_dbo.EXW_C2F_E2E | —/10 | Done (Batch 9, #1) — wiki-only |
| EXW_dbo.EXW_FactBalance | 8.93/10 | Done (Batch 1, #5) |
| EXW_dbo.EXW_FactConversions | 8.4/10 | Done (Batch 3, #1) |
| EXW_dbo.EXW_ReimbursementSumTable | 9.25/10 | Done (Batch 4, #5) |
| EXW_dbo.Hourly_CustomerBalances | 8.7/10 | Done (Batch 6, #5) |
| EXW_dbo.Hourly_OmnibusBalances | 8.7/10 | Done (Batch 7, #1) |
| EXW_dbo.Hourly_RedeemActivity | 8.5/10 | Done (Batch 7, #2) |
| EXW_dbo.Hourly_WalletInventory | 8.8/10 | Done (Batch 7, #3) |
| EXW_dbo.Hourly_WalletAllocations | 9.0/10 | Done (Batch 7, #4) |
| EXW_dbo.Hourly_Transactions | 8.6/10 | Done (Batch 6, #6) |
| EXW_dbo.EXW_C2P_E2E | —/10 | Done (Batch 9, #2) — wiki-only |
| EXW_dbo.EXW_CompensationClosingCountries | 9.15/10 | Done (Batch 4, #3) |
| EXW_dbo.EXW_FactRedeemTransactions | 9.55/10 | Done (Batch 4, #2) |
| EXW_dbo.EXW_FinanceReportsBalancesNew | 8.35/10 | Done (Batch 4, #1) |
| EXW_dbo.EXW_FirstTimeWalletsAndUsers | 8.6/10 | Done (Batch 5, #3) |
| EXW_dbo.EXW_InternalWallet | 8.8/10 | Done (Batch 8, #6) |
| EXW_dbo.EXW_WalletEntity | 9.3/10 | Done (Batch 10, #1) |
| EXW_dbo.EXW_WalletInventory | 9.4/10 | Done (Batch 3, #2) |
| EXW_dbo.EXW_WalletLogins | 8.5/10 | Done (Batch 8, #5) |
| EXW_dbo.New_UsersAndWallets_Inventory | 8.6/10 | Done (Batch 6, #1) |
| EXW_dbo.EXW_30DayBalanceExtract | 8.7/10 | Done (Batch 5, #6) |
| EXW_dbo.EXW_Coin_Transfer_Allowed_Country | 9.75/10 | Done (Batch 4, #6) |
| EXW_dbo.EXW_Conversion_Allowed_Country | 8.3/10 | Done (Batch 10, #5) |
| EXW_dbo.EXW_ETH_FeeData_Blockchain | 8.5/10 | Done (Batch 6, #2) |
| EXW_dbo.EXW_EthFeeSent_Blockchain | 8.7/10 | Done (Batch 5, #2) |
| EXW_dbo.EXW_FCA_UserLogin | 9.2/10 | Done (Batch 10, #6) |
| EXW_dbo.EXW_Inventory_Snapshot_History | 9.05/10 | Done (Batch 12, #1) |
| EXW_dbo.EXW_Payment_Allowed_Country | 8.4/10 | Done (Batch 10, #4) |
| EXW_dbo.EXW_RedeemReconciliation | —/10 | Done (Batch 9, #3) — wiki-only |
| EXW_dbo.EXW_Staking_Allowed_Country | 8.5/10 | Done (Batch 10, #3) |
| EXW_dbo.EXW_Transactions_Monthly | 8.3/10 | Done (Batch 5, #4) — DEPRECATED |
| EXW_dbo.EXW_UserCalculatedBalance | 8.3/10 | Done (Batch 5, #5) — DEPRECATED |
| EXW_dbo.EXW_WalletElligibleCountries | 8.8/10 | Done (Batch 6, #3) |
| EXW_dbo.EXW_WalletRegulation | 8.93/10 | Done (Batch 1, #6) |
| EXW_dbo.EXW_WalletUsers_30_Days | 8.8/10 | Done (Batch 10, #2) |
| EXW_dbo.EXW_ECPBank | 8.6/10 | Done (Batch 11, #3) |
| EXW_dbo.EXW_EOMReportingBalances | 9.05/10 | Done (Batch 12, #3) |
| EXW_dbo.EXW_FactPayments | 9.0/10 | Done (Batch 11, #4) |
| EXW_dbo.EXW_PaymentReconciliation | 8.9/10 | Done (Batch 11, #5) |
| EXW_dbo.EXW_ReportingBalances | 8.35/10 | Done (Batch 12, #2) |
| EXW_dbo.EXW_SimplexChargebacks | 8.5/10 | Done (Batch 11, #2) |
| EXW_dbo.EXW_SimplexMapping | 8.2/10 | Done (Batch 11, #1) |
| EXW_dbo.Staking_BI_Version_ETH_Transactions | 8.0/10 | Done (Batch 8, #4) |
| EXW_dbo.Staking_BI_Version_WalletUserRewards | 8.2/10 | Done (Batch 8, #3) |
| EXW_dbo.Staking_ETH_Rewards_Parameters | 7.5/10 | Done (Batch 8, #1) |
| EXW_dbo.Staking_WalletUserRewards | 8.0/10 | Done (Batch 8, #2) |

## Views (3)

| Object | Quality | Status |
|--------|---------|--------|
| EXW_dbo.GetProviderUserIDNormalized | 8.8/10 | Done (Batch 5, #1) |
| EXW_dbo.EXW_V_RedeemReconciliation | 9.55/10 | Done (Batch 12, #4) |
| EXW_dbo.V_EXW_C2F_E2E_4Export | 9.60/10 | Done (Batch 12, #5) |

## Functions (2)

| Object | Quality | Status |
|--------|---------|--------|
| EXW_dbo.RemovePrefix | 9.3/10 | Done (Batch 10, #7) |
| EXW_dbo.RemoveSuffix | 9.3/10 | Done (Batch 10, #8) |

---

## Skipped Objects

| Object | Reason |
|--------|--------|
| EXW_dbo.EXW_C2F_LastStatus | No DDL found in SSDT (depth=4 in dep graph) |

## Blacklisted Objects (Backup Tables — Do Not Document)

| Object | Reason |
|--------|--------|
| EXW_dbo.EXW_FactTransactions_Backup_20241114 | Backup table |
| EXW_dbo.EXW_Transactions_Monthly_Backup_20241114 | Backup table |
| EXW_dbo.New_UsersAndWallets_Inventory_Backup_20241114 | Backup table |
| EXW_dbo.EXW_WalletInventory_Backup_20241114 | Backup table |
| EXW_dbo.EXW_WalletLogins_Backup_20241216 | Backup table |
