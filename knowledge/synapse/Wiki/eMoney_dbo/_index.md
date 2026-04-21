---
schema: eMoney_dbo
database: Synapse DWH
total_objects: 93
blacklisted: 42
pending: 31
documented: 17
failed: 0
skipped: 0
last_batch: 9
last_updated: "2026-04-21"
quality_avg: 9.05
revisions: 0
---

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | eMoney_dbo |
| **Total Objects** | 93 (91 tables + 2 views) |
| **Active (to document)** | 48 |
| **Blacklisted** | 42 (20 FiatDwhDB mirrors + 7 ETL staging + 15 temp/test/dup) |
| **Documented (files on disk)** | 17 |
| **Pending** | 31 |
| **Skipped** | 0 |
| **Last Updated** | 2026-04-21 |

> **Note**: Batch 9 completed 2 objects (eMoney_Customer_Risk_Assessment + History, each 120 cols / 3 slots = 6 total slots). Both are AML/compliance DDR tables. Total on-disk files now 17. Batch 8 completed 8 objects (6 dict fast-path + 2 large tables). Batches 1–7 historical notes: batches 2–6 analysis was in _batch_context.json only; batch 7 produced 3 on-disk files.

---

## Object Inventory

### Tables — Active (to document)

| Object | Type | Cols | Status | Notes |
|--------|------|------|--------|-------|
| eMoney_Dim_Account | Table | 89 | **Documented** | Core account dimension — 29 T1 / 60 T2; 8.8/10 |
| eMoney_Dim_Transaction | Table | 77 | **Documented** | Core transaction dimension (latest status per tx) — 8 T1 / 69 T2; 8.8/10 |
| eMoney_Fact_Transaction_Status | Table | 77 | **Documented** | Transaction fact (all status events) — 8 T1 / 69 T2; 8.8/10 |
| eMoney_Panel_Retention_Daily | Table | 86 | **Documented** | Daily MIMO retention panel — 0 T1 / 86 T2; 8.98/10 |
| eMoney_Panel_Retention_Monthly | Table | 86 | **Documented** | Monthly EOM retention panel (rebuilt from Daily) — 0 T1 / 86 T2; 8.93/10 |
| eMoney_Risk_Portfolio | Table | 79 | **Documented** | Daily AML/risk profile — 7 T1 / 66 T2 / 6 T4; 8.96/10 |
| eMoney_Dictionary_AccountProgram | Table | 3 | **Documented** | 0=Unknown, 1=card, 2=iban; Generic Pipeline SIMPLE-DICT fast-path; 2 T1 / 1 T2; 9.1/10 |
| eMoney_Dictionary_AccountStatus | Table | 3 | **Documented** | 0=Active, 1=Suspended, 2=Deleted; SIMPLE-DICT; 2 T1 / 1 T2; 9.1/10 |
| eMoney_Dictionary_Provider | Table | 3 | **Documented** | 1=Tribe only; SIMPLE-DICT single-row; 2 T1 / 1 T2; 9.1/10 |
| eMoney_Dictionary_TransactionStatus | Table | 3 | **Documented** | 6/8 rows (IDs 6-7 missing); FLAGGED HIGH; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Dictionary_TransactionType | Table | 3 | **Documented** | 15 vals (0=Unknown to 14=CryptoToFiat); FMI/FMO/CB groupings; 2 T1 / 1 T2; 9.3/10 |
| eMoney_Dictionary_AccountSubProgram | Table | 5 | **Documented** | 10/16 rows (IDs 11-16 AUS/DK missing); FLAGGED HIGH; 4 T1 / 1 T2; 9.1/10 |
| eMoneyClientBalance | Table | 72 | **Documented** | Daily account-level balance; HASH(AccountId); 72 cols live (SSDT stale at 45); 0 T1 / 72 T2; 9.0/10 |
| eMoney_Calculated_Balance | Table | 48 | **Documented** | Daily TxTypeID-aggregated cumulative balance; STALE MaxDate=2025-06-09; 0 T1 / 48 T2; 9.1/10 |
| eMoney_Dim_Country_Rollout | Table | 7 | Pending | |
| eMoney_Panel_FirstDates | Table | 65 | Pending | |
| eMoney_Reports_AcquisitionFunnel | Table | 15 | Pending | |
| eMoney_Reports_AcquisitionFunnelAggregated | Table | 5 | Pending | |
| eMoney_Reports_ClubUpgrade | Table | 13 | Pending | |
| eMoney_Dictionary_AuthorizationType | Table | 3 | Pending | |
| eMoney_Dictionary_CardStatus | Table | 3 | Pending | |
| eMoney_Dictionary_CurrencyBalanceStatus | Table | 3 | Pending | |
| eMoney_Dictionary_PaymentSchemaType | Table | 3 | Pending | |
| eMoney_Dictionary_PaymentSpecificationType | Table | 3 | Pending | |
| eMoney_Dictionary_TribeScriptStatus | Table | 3 | Pending | |
| eMoney_Account_Mappings | Table | 24 | Pending | |
| eMoney_Country_Codes_Mapping_ISO | Table | 6 | Pending | |
| eMoney_Currency_Instrument_Mapping_Static | Table | 10 | Pending | |
| eMoney_Currency_Mapping_ISO | Table | 4 | Pending | |
| eMoney_EntityByCurrencyISO_MappingStatic | Table | 7 | Pending | |
| eMoney_Card_Instance_Summary | Table | 18 | Pending | |
| eMoney_Card_Monthly_Snapshot | Table | 23 | Pending | |
| eMoney_Snapshot_Settled_Balance | Table | 27 | Pending | |
| eMoney_BankPaymentsUK | Table | 18 | Pending | |
| eMoney_Aggregated_Tribe_Balance | Table | 28 | Pending | |
| eMoney_Customer_Risk_Assessment | Table | 120 | **Documented** | Daily AML/risk snapshot — 32-param scoring; 5 T1 / 115 T2; 9.1/10 |
| eMoney_Customer_Risk_Assessment_History | Table | 120 | **Documented** | Class-change-only audit trail; append-only; 5 T1 / 115 T2; 9.2/10 |
| eMoney_Client_Balance_Check_Exceptions_Gap | Table | — | Pending | |
| eMoney_Client_Balance_Check_Opening_Balance | Table | — | Pending | |
| eMoney_Daily_MIMO_New_Reports_Action | Table | — | Pending | |
| eMoney_Daily_Shortfall_CID_Level | Table | — | Pending | |
| eMoney_Marketing_EmailTracking | Table | — | Pending | |
| eMoney_Reports_MIMO_Actions | Table | — | Pending | |
| eMoney_UserData_Marketing | Table | — | Pending | |
| eMoneyProcessStatusLog | Table | — | Pending | |
| eMoney_AM_Target | Table | — | Pending | |

### Views — Active (to document)

| Object | Type | Cols | Status | Notes |
|--------|------|------|--------|-------|
| v_eMoney_Card_Instance_Summary | View | 17 | **Documented** | SELECT wrapper for Card_Instance_Summary; excludes MaskedPAN |
| v_eMoney_Dim_Account | View | — | Pending | |

### Tables — Blacklisted

#### FiatDwhDB mirrors (documented in BankingDBs/FiatDwhDB/Wiki/)

| Object | Reason |
|--------|--------|
| AccountsProviderHoldersMapping | FiatDwhDB mirror — documented upstream |
| CardsProvidersMapping | FiatDwhDB mirror — documented upstream |
| CurrencyBalancesProvidersMapping | FiatDwhDB mirror — documented upstream |
| FiatAccount | FiatDwhDB mirror — documented upstream |
| FiatAccountStatuses | FiatDwhDB mirror — documented upstream |
| FiatAccountsProperties | FiatDwhDB mirror — documented upstream |
| FiatBankAccount | FiatDwhDB mirror — documented upstream |
| FiatCardStatuses | FiatDwhDB mirror — documented upstream |
| FiatCards | FiatDwhDB mirror — documented upstream |
| FiatCurrencyBalances | FiatDwhDB mirror — documented upstream |
| FiatCurrencyBalancesStatuses | FiatDwhDB mirror — documented upstream |
| FiatTransactions | FiatDwhDB mirror — documented upstream |
| FiatTransactionsStatuses | FiatDwhDB mirror — documented upstream |
| PaymentSpecificationDetails | FiatDwhDB mirror — documented upstream |
| PaymentSpecificationDues | FiatDwhDB mirror — documented upstream |
| PaymentSpecificationStatuses | FiatDwhDB mirror — documented upstream |
| PaymentSpecifications | FiatDwhDB mirror — documented upstream |
| PaymentSpecificationsProvidersMapping | FiatDwhDB mirror — documented upstream |
| SubPrograms | FiatDwhDB mirror — documented upstream |
| TransactionsProvidersMapping | FiatDwhDB mirror — documented upstream |

#### ETL staging / internal process tables

| Object | Reason |
|--------|--------|
| ETL_AccountSnapshot | ETL staging table — transient |
| ETL_AccountsActivities | ETL staging table — transient |
| ETL_Authorize | ETL staging table — transient |
| ETL_CardSnapshot | ETL staging table — transient |
| ETL_SettlementsTransactions | ETL staging table — transient |
| DataSolutionsProcesses | Internal ETL process tracking |
| DataSolutionsProcessesStatus | Internal ETL process status |

#### Temp / backup / test / duplicate

| Object | Reason |
|--------|--------|
| CustomerEODBalance_tmp | Temp table (suffix _tmp) |
| FiatAccount_copy | Backup copy |
| FiatTransactionsStatuses_OLD | Old version |
| FiatTransactionsStatuses_tmp | Temp table |
| FiatTransactionsStatuses_tmp1 | Temp table |
| Ofir5_tmp | Developer temp table |
| Ofir5_tmp2 | Developer temp table |
| OfirETL_CardSnapshot | Developer ETL temp |
| Ofir_ETL_AccountSnapshot | Developer ETL temp |
| eMoney_Dictionary_CurrencyBalanceStatus_test_ofir | Test table |
| eMoney_Calculated_Balance_20240102 | Point-in-time snapshot (stale) |
| eMoney_Yearly_Volume_Target_2023 | Stale 2023 target data |
| ofir_FiatTransactions | Developer temp table |
| ofir_test | Developer test table |
| PaymentSpecifications_tmp1 | Temp table |
