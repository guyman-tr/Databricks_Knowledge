---
schema: eMoney_dbo
database: Synapse DWH
total_objects: 94
blacklisted: 42
pending: 0
documented: 49
failed: 0
skipped: 0
last_batch: 18
last_updated: "2026-04-21"
quality_avg: 8.99
revisions: 0
---

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | eMoney_dbo |
| **Total Objects** | 94 (92 tables + 2 views) |
| **Active (to document)** | 49 |
| **Blacklisted** | 42 (20 FiatDwhDB mirrors + 7 ETL staging + 15 temp/test/dup) |
| **Documented (files on disk)** | 49 |
| **Pending** | 0 |
| **Skipped** | 0 |
| **Last Updated** | 2026-04-21 |

> **Note**: Batches 3-6 ran WITHOUT Synapse MCP — all non-dictionary objects from those batches were REVOKED and rebuilt with live MCP. CRA + CRA_History (originally batch 6, REVOKED) were rebuilt in batch 10 (2026-04-21). Batch 11 (2026-04-21) documented the 8 revoked batch 4 objects (6 dictionaries + 2 ISO mapping tables) using live MCP enum data — prior batch context had WRONG values and was discarded. v_Card_Instance_Summary (batch 5 REVOKED) remains Pending. Batch 13 (2026-04-21): eMoney_Reports_ClubUpgrade (8.8), eMoney_Account_Mappings (9.1), eMoney_Currency_Instrument_Mapping_Static (9.3), eMoney_EntityByCurrencyISO_MappingStatic (9.5) — 4 objects, quality avg 9.07. Batch 14 (2026-04-21): eMoney_Card_Instance_Summary (8.9), eMoney_Card_Monthly_Snapshot (9.0), eMoney_Snapshot_Settled_Balance (8.9), eMoney_BankPaymentsUK (8.8) — 4 objects, quality avg 9.05 (cumulative). Batch 15 (2026-04-21): eMoney_Aggregated_Tribe_Balance (8.9), eMoney_Daily_MIMO_New_Reports_Action (9.0), eMoney_Reports_MIMO_Actions (8.8), eMoney_Daily_Shortfall_CID_Level (8.8) — 4 objects, quality avg 9.03 (cumulative). Batch 16 (2026-04-21): eMoney_AM_Target (8.8), eMoney_Marketing_EmailTracking (8.5), eMoney_UserData_Marketing (8.9), v_eMoney_Card_Instance_Summary (8.9) — 4 objects, quality avg 9.01 (cumulative). Batch 17 (2026-04-21): eMoney_Client_Balance_Check_Exceptions_Gap (8.5), eMoney_Client_Balance_Check_Opening_Balance (8.5), eMoneyProcessStatusLog (9.0), v_eMoney_Dim_Account (8.9) — 4 objects, quality avg 8.99 (cumulative). Batch 18 (2026-04-21): eMoney_Dictionary_TransactionCategory (9.0) — 1 new object discovered in SSDT re-scan; quality avg 8.99 (cumulative). SCHEMA COMPLETE — all 49 active objects documented. MCP pre-flight is mandatory — see build-wiki-dwh-batch.md.

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
| eMoney_Dim_Country_Rollout | Table | 7 | **Documented** | 34-country eToro Money rollout dimension; hardcoded SP launch dates; REPLICATE HEAP; 3 T2 / 4 T4; 8.5/10 |
| eMoney_Panel_FirstDates | Table | 65 | **Documented** | Per-account FMI/FMO milestone panel; 2,031,884 rows; HASH(CID) HEAP; primary FMI/FMO signal source; 3 T1 / 62 T2; 9.0/10 |
| eMoney_Reports_AcquisitionFunnel | Table | 15 | **Documented** | Customer-grain eMoney acquisition funnel; 3.67M rows; HASH(CID) HEAP; IsValidForFunnel filter; 2 T1 / 13 T2; 8.9/10 |
| eMoney_Reports_AcquisitionFunnelAggregated | Table | 5 | **Documented** | (FunnelStage, Country, Club) funnel aggregation; 1,863 rows; REPLICATE HEAP; 9 stages; 0 T1 / 5 T2; 9.0/10 |
| eMoney_Reports_ClubUpgrade | Table | 13 | **Documented** | Club upgrade event log (eTM-eligible); 1,178,170 rows; 2 T1 / 11 T2; Is_eTM point-in-time; 8.8/10 |
| eMoney_Dictionary_AuthorizationType | Table | 3 | **Documented** | 15 vals (0=Unknown to 14=AccountFunding); pre-auth/reversal flows; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| [eMoney_Dictionary_TransactionCategory](Tables/eMoney_Dictionary_TransactionCategory.md) | Table | 3 | **Done (Batch 18)** | 5 vals (0=Unknown to 4=BalanceAdjustmentTransaction); manual load 2023-06-12; static (no writer SP); 2 T1 / 1 T2; 9.0/10 |
| eMoney_Dictionary_CardStatus | Table | 3 | **Documented** | 9 vals (0=NotActivated to 8=Fraud); terminal vs reversible; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Dictionary_CurrencyBalanceStatus | Table | 3 | **Documented** | 5 vals (0=Active to 4=Blocked); partial restriction states; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Dictionary_PaymentSchemaType | Table | 3 | **Documented** | 8 vals (0=Unknown to 7=SEPAdirectDebit); SEPAstandart typo preserved; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Dictionary_PaymentSpecificationType | Table | 3 | **Documented** | 2 vals (0=Unknown, 1=DirectDebit); minimal; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Dictionary_TribeScriptStatus | Table | 3 | **Documented** | 3 vals (0=Unapproved, 1=Approved, 2=Executed); approval workflow; SIMPLE-DICT; 2 T1 / 1 T2; 9.2/10 |
| eMoney_Account_Mappings | Table | 24 | **Documented** | CurrencyBalance→Account→Card→Provider cross-reference; 2,034,012 rows; DELETE+INSERT; PII cols; 20 T1 / 4 T2; 9.1/10 |
| eMoney_Country_Codes_Mapping_ISO | Table | 6 | **Documented** | 248 rows; ISO 3166-1 bridge → eToroDWHCountryID; HASH(eToroDWHCountryID); manual load 2024-06-24; 0 T1 / 6 T2; 8.8/10 |
| eMoney_Currency_Instrument_Mapping_Static | Table | 10 | **Documented** | 145-row FX instrument lookup; 21 currencies; manual load 2022-11-21; static; 0 T1 / 10 T2; 9.3/10 |
| eMoney_Currency_Mapping_ISO | Table | 4 | **Documented** | 168 rows; ISO 4217 bridge → CurrencyAlphaThreeCode; HASH(CurrencyNumericCode_ISO); manual load 2024-06-24; 0 T1 / 4 T2; 8.8/10 |
| eMoney_EntityByCurrencyISO_MappingStatic | Table | 7 | **Documented** | 4-row entity mapping (UK/Malta/AUS); DKK→EUR reporting; manual load 2025-09-29/11-26; 0 T1 / 7 T2; 9.5/10 |
| eMoney_Card_Instance_Summary | Table | 18 | **Documented** | Card instance timeline (1 row/instance); TRUNCATE+INSERT daily; 130K rows; 6 T1/12 T2; 8.9/10 |
| eMoney_Card_Monthly_Snapshot | Table | 23 | **Documented** | 566M-row monthly EOM eligible-customer panel (27 snapshots); card funnel signals; 2 T1/21 T2; 9.0/10 |
| eMoney_Snapshot_Settled_Balance | Table | 27 | **Documented** | Daily settled balance snapshot; 1.29M rows; 4 currencies; DELETE+full rebuild; 3 T1/24 T2; 8.9/10 |
| eMoney_BankPaymentsUK | Table | 18 | **Documented** | GBP bank payment log; 468K rows; HASH(TransactionId)+CCI; incremental append; 2 T1/16 T2; 8.8/10 |
| eMoney_Aggregated_Tribe_Balance | Table | 28 | **Documented** | CASS/NegativeBalances aggregate by Entity/Currency; DELETE+INSERT daily; 0 T1/28 T2; 8.9/10 |
| eMoney_Customer_Risk_Assessment | Table | 120 | **Documented** | Daily CID-grain AML/KYC risk snapshot; 32-param weighted score; HASH(CID) HEAP; 2,031,882 rows; 5 T1 / 115 T2; 9.0/10 |
| eMoney_Customer_Risk_Assessment_History | Table | 120 | **Documented** | Class-change audit log (append-only); 8,113,383 rows; avg 3.99/CID; same schema as CRA; 5 T1 / 115 T2; 9.2/10 |
| [eMoney_Client_Balance_Check_Exceptions_Gap](Tables/eMoney_Client_Balance_Check_Exceptions_Gap.md) | Table | 3 | **Done (Batch 17)** | Balance reconciliation check (exceptions only); 0 rows expected clean state; TRUNCATE+INSERT; 0 T1/3 T2; 8.5/10 |
| [eMoney_Client_Balance_Check_Opening_Balance](Tables/eMoney_Client_Balance_Check_Opening_Balance.md) | Table | 3 | **Done (Batch 17)** | Opening balance reconciliation check; 0 rows expected; "Openning" typo preserved; TRUNCATE+INSERT; 0 T1/3 T2; 8.5/10 |
| eMoney_Daily_MIMO_New_Reports_Action | Table | 21 | **Documented** | MIMO daily report (successor to eMoney_Reports_MIMO_Actions from 2024-10-12); FundingTypeID=33 split; 0 T1/21 T2; 9.0/10 |
| eMoney_Daily_Shortfall_CID_Level | Table | 18 | **Documented** | Daily overdrawn account snapshot; EtoroDeposits>0 filter; Shortfall<0 only; HASH(CID); 0 T1/18 T2; 8.8/10 |
| [eMoney_Marketing_EmailTracking](Tables/eMoney_Marketing_EmailTracking.md) | Table | 16 | **Done (Batch 16)** | 0 rows (SP suspended); SFMC email campaign tracking; 0 T1 / 16 T2; 8.5/10 |
| eMoney_Reports_MIMO_Actions | Table | 20 | **Documented** | MIMO daily report legacy table (FROZEN 2024-10-12); predecessor to eMoney_Daily_MIMO_New_Reports_Action; 0 T1/20 T2; 8.8/10 |
| [eMoney_UserData_Marketing](Tables/eMoney_UserData_Marketing.md) | Table | 13 | **Done (Batch 16)** | 2,010,838 rows; customer marketing snapshot; 3 T1 / 10 T2; 8.9/10 |
| [eMoneyProcessStatusLog](Tables/eMoneyProcessStatusLog.md) | Table | 5 | **Done (Batch 17)** | ETL process audit log; FROZEN 2023-10-30; 16,726 rows; append-only; 0 T1/5 T2; 9.0/10 |
| [eMoney_AM_Target](Tables/eMoney_AM_Target.md) | Table | 31 | **Done (Batch 16)** | 385M rows, 2023-07-01 to 2026-04-11; AM MIMO targets (SP suspended); 2 T1 / 29 T2; 8.8/10 |

### Views — Active (to document)

| Object | Type | Cols | Status | Notes |
|--------|------|------|--------|-------|
| [v_eMoney_Card_Instance_Summary](Views/v_eMoney_Card_Instance_Summary.md) | View | 17 | **Done (Batch 16)** | Column-projection view of eMoney_Card_Instance_Summary (excludes MaskedPAN); 4 T1 / 13 T2; 8.9/10 |
| [v_eMoney_Dim_Account](Views/v_eMoney_Dim_Account.md) | View | 78 | **Done (Batch 17)** | Live-state view of eMoney_Dim_Account (refresh-day only); TOP(1000) no ORDER BY; 27 T1/51 T2; 8.9/10 |

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
