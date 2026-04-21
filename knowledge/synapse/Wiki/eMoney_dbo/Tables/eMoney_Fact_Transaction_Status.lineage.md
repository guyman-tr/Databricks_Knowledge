# eMoney_dbo.eMoney_Fact_Transaction_Status — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | FiatDwhDB (eToro Money fiat platform DWH) |
| **Production Tables** | dbo.FiatTransactions (core), dbo.FiatTransactionsStatuses (all status events — NO RNDesc filter), dbo.TransactionsProvidersMapping (provider IDs), dbo.FiatCards (card FK), dbo.FiatAccount (account FK), dbo.FiatCurrencyBalances (balance FK), dbo.FiatBankAccount (external bank account FK) |
| **DWH Enrichment Sources** | eMoney_dbo.eMoney_Dim_Account (account/customer snapshot at ETL run time), DWH_dbo.Fact_SnapshotCustomer (customer attributes at TxLocalDate), DWH_dbo.Fact_CurrencyPriceWithSplit (USD rate at TxLocalDate) |
| **Dictionary Sources** | eMoney_dbo.External_FiatDwhDB_Dictionary_TransactionTypes, External_FiatDwhDB_Dictionary_TransactionStatuses, External_FiatDwhDB_Dictionary_TransactionCategories, External_FiatDwhDB_Dictionary_PaymentSchemaType, External_FiatDwhDB_Dictionary_AuthorizationTypes, External_FiatDwhDB_Dictionary_Providers |
| **ETL SP** | SP_eMoney_DimFact_Transaction (11-step pipeline, Steps 1–9 shared with eMoney_Dim_Transaction, Step 11 = Fact INSERT without RNDesc filter) |
| **Filter** | NO RNDesc filter (ALL status events per transaction retained) |
| **Upstream Wiki** | BankingDBs/FiatDwhDB/Wiki/ (FiatAccount, FiatCards, FiatBankAccount, FiatCurrencyBalances have wikis; FiatTransactions and FiatTransactionsStatuses do NOT have wikis) |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status |

## ETL Pipeline Summary

```
Step 01: #eMoney_Dim_Account snapshot — read current eMoney_Dim_Account; compute RN_CurrencyBalance_Desc, RN_Account_Desc, RN_Card_Desc
Step 02: #TransactionsProvidersMapping — deduplicate TransactionsProvidersMapping (RN_Desc=1), join Providers dictionary
Step 03: #fiat_tx — compile all transactions from FiatTransactions;
         compute TxTypeCategory (CASE on TxTypeID), TxClientBalanceCategory (CASE on TxTypeID),
         TxCreatedDate/ID, TxLocalDate/ID; join ISO mapping, Dim_Country, dictionaries
Step 04: #tx_status — compile ALL status events from FiatTransactionsStatuses;
         compute IsTxStatusCBRelevant, MoneyMoveDirection; RNDesc=ROW_NUMBER() PARTITION BY TransactionId ORDER BY TransactionOccured DESC
         FiatTransactionStatusRunningID = FiatTransactionsStatuses.Id (surrogate PK of status event)
Step 05a/b: #currency_to_instrument_mapping — map currency ISO to eToro Instrument for USD approx calculation
Step 06: #usdapprox — calculate USDAmountApprox, USDRateApprox, AccumulatedUSDAmountApprox via Fact_CurrencyPriceWithSplit mid-rate at TxLocalDate
         Join key: FiatTransactionStatusRunningID (unique per status event)
Step 07: #cnt_status_changes — MAX(RNDesc) per TransactionID = CountStatusChanges
Step 08: #customersnapshot — DWH customer attributes at TxLocalDate (Fact_SnapshotCustomer at TxLocalDateID range)
Step 09: #leveled_txs — join all temp tables; ALL status events retained here
Step 10: DELETE + INSERT eMoney_Dim_Transaction FROM #leveled_txs WHERE RNDesc=1 (latest status only)
Step 11: DELETE + INSERT eMoney_Fact_Transaction_Status FROM #leveled_txs (NO filter — all statuses)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|---------------|-----------|
| 1 | TransactionID | dbo.FiatTransactions | Id | Passthrough |
| 2 | AccountID | dbo.FiatTransactions | AccountId | Passthrough (FK to FiatAccount.Id) |
| 3 | GCID | eMoney_Dim_Account | GCID | Passthrough via Step 08 → eMoney_Dim_Account |
| 4 | CID | eMoney_Dim_Account | CID | Passthrough via Step 08 → eMoney_Dim_Account → Dim_Customer.RealCID |
| 5 | CardID | dbo.FiatTransactions | CardId | Passthrough (FK to FiatCards.Id) |
| 6 | ProviderCardID | eMoney_Dim_Account | ProviderCardID | Passthrough via RN_Card_Desc=1 join |
| 7 | CurrencyBalanceID | dbo.FiatTransactions | CurrencyBalanceId | Passthrough (FK to FiatCurrencyBalances.Id) |
| 8 | ProviderCurrencyBalanceID | eMoney_Dim_Account | ProviderCurrencyBalanceID | Passthrough via RN_CurrencyBalance_Desc=1 join |
| 9 | ExternalBankAccountID | dbo.FiatTransactions | ExternalBankAccountId | Passthrough (FK to FiatBankAccount.Id) |
| 10 | TxTypeID | dbo.FiatTransactions | TransactionTypeId | Passthrough |
| 11 | TxType | External_FiatDwhDB_Dictionary_TransactionTypes | Name | JOIN lookup on TxTypeID |
| 12 | TxTypeCategory | Computed | — | CASE: 1-4,13=Card; 5-8=IBAN; else Other |
| 13 | TxClientBalanceCategory | Computed | — | CASE: 14 values mapped to 9 category labels |
| 14 | MerchantID | dbo.FiatTransactions | MerchantId | Passthrough |
| 15 | TxCreatedDate | Computed | dbo.FiatTransactions.Created | CAST(Created AS DATE) |
| 16 | TxCreatedDateID | Computed | dbo.FiatTransactions.Created | CONVERT(VARCHAR(8), Created, 112)::INT |
| 17 | TxLabel | dbo.FiatTransactions | Label | Passthrough |
| 18 | TxLocalTime | dbo.FiatTransactions | TransactionLocalTime | Passthrough |
| 19 | TxLocalDate | Computed | dbo.FiatTransactions.TransactionLocalTime | CAST(TransactionLocalTime AS DATE) |
| 20 | TxLocalDateID | Computed | dbo.FiatTransactions.TransactionLocalTime | CONVERT(VARCHAR(8), TransactionLocalTime, 112)::INT |
| 21 | TxLocalCountryNumericISO | dbo.FiatTransactions | TransactionCountryIso | Passthrough |
| 22 | TxLocalCountryNameISO | DWH_dbo.Dim_Country | Name | JOIN via eMoney_Country_Codes_Mapping_ISO ISO bridge |
| 23 | ReferenceNumber | dbo.FiatTransactions | ReferenceNumber | Passthrough |
| 24 | TxCategoryID | dbo.FiatTransactions | TransactionCategory | Passthrough |
| 25 | TxCategory | External_FiatDwhDB_Dictionary_TransactionCategories | Name | JOIN lookup |
| 26 | PaymentSchemaTypeID | dbo.FiatTransactions | PaymentSchemeId | Passthrough |
| 27 | PaymentSchemaType | External_FiatDwhDB_Dictionary_PaymentSchemaType | Name | JOIN lookup |
| 28 | PaymentReference | dbo.FiatTransactions | PaymentReference | Passthrough |
| 29 | MoneyCorrelationID | dbo.FiatTransactions | MoneyCorrelationId | CAST(MoneyCorrelationId AS VARCHAR(2000)) |
| 30 | ProviderID | dbo.TransactionsProvidersMapping | ProviderId | Latest provider mapping (RN_Desc=1) |
| 31 | ProviderDesc | External_FiatDwhDB_Dictionary_Providers | Name | JOIN lookup on ProviderID |
| 32 | ProviderTransactionID | dbo.TransactionsProvidersMapping | TransactionProviderId | Latest provider mapping (RN_Desc=1) |
| 33 | AccountProgramID | eMoney_Dim_Account | AccountProgramID | Passthrough (current program at ETL run time) |
| 34 | AccountProgram | eMoney_Dim_Account | AccountProgram | Passthrough (label, current at ETL run time) |
| 35 | AccountSubProgramID | eMoney_Dim_Account | AccountSubProgramID | Passthrough (current sub-program at ETL run time) |
| 36 | AccountSubProgram | eMoney_Dim_Account | AccountSubProgram | Passthrough (label, current at ETL run time) |
| 37 | IsValidETM | eMoney_Dim_Account | IsValidETM | Passthrough (current at ETL run time) |
| 38 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Snapshot at TxLocalDate range |
| 39 | ClubIDTxDate | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Snapshot at TxLocalDate range |
| 40 | ClubTxDate | DWH_dbo.Dim_PlayerLevel | Name | JOIN on ClubIDTxDate |
| 41 | RegulationIDTxDate | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Snapshot at TxLocalDate range |
| 42 | RegulationTxDate | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationIDTxDate |
| 43 | CountryIDTxDate | DWH_dbo.Fact_SnapshotCustomer | CountryID | Snapshot at TxLocalDate range |
| 44 | CountryTxDate | DWH_dbo.Dim_Country | Name | JOIN on CountryIDTxDate |
| 45 | PlayerStatusIDTxDate | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Snapshot at TxLocalDate range |
| 46 | PlayerStatusTxDate | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusIDTxDate |
| 47 | FiatTransactionStatusRunningID | dbo.FiatTransactionsStatuses | Id | Surrogate PK of the individual status event row. Also used as join key to #usdapprox. [KEY DIFFERENCE from eMoney_Dim_Transaction: IsTxSettled at this position] |
| 48 | TxStatusID | dbo.FiatTransactionsStatuses | TransactionStatusId | Each status event (ALL RNDesc values — not filtered to latest only) |
| 49 | TxStatus | External_FiatDwhDB_Dictionary_TransactionStatuses | Name | JOIN lookup |
| 50 | CountStatusChanges | Computed | — | MAX(RNDesc) per TransactionID from #tx_status |
| 51 | AuthorizationTypeID | dbo.FiatTransactionsStatuses | AuthorizationType | Each status event (ALL RNDesc values) |
| 52 | AuthorizationType | External_FiatDwhDB_Dictionary_AuthorizationTypes | Name | JOIN lookup |
| 53 | IsTxStatusCBRelevant | Computed | — | CASE: TxStatusID IN (2,3,4) AND AuthorizationTypeID NOT IN (12,13) → 1 else 0 |
| 54 | MoneyMoveDirection | Computed | — | CASE: HolderAmount < 0 = MoneyOut; > 0 = MoneyIn; else Error |
| 55 | HolderCurrencyISO | dbo.FiatTransactionsStatuses | HolderCurrency | Each status event (ALL RNDesc values) |
| 56 | HolderCurrencyDesc | eMoney_Currency_Mapping_ISO | CurrencyAlphaThreeCode | Via USD approx instrument mapping (COALESCE buy/sell) |
| 57 | HolderAmount | dbo.FiatTransactionsStatuses | HolderAmount | Each status event (ALL RNDesc values) |
| 58 | LocalCurrencyISO | dbo.FiatTransactionsStatuses | TransactionCurrency | Each status event (ALL RNDesc values) |
| 59 | LocalCurrencyDesc | eMoney_Currency_Mapping_ISO | CurrencyName | JOIN on LocalCurrencyISO |
| 60 | LocalAmount | dbo.FiatTransactionsStatuses | TransactionAmount | Each status event (ALL RNDesc values) |
| 61 | USDAmountApprox | Computed | dbo.FiatTransactionsStatuses.HolderAmount × Fact_CurrencyPriceWithSplit mid-rate | ROUND(HolderAmount × (Ask+Bid)/2, 2) or inverse; join via FiatTransactionStatusRunningID |
| 62 | USDRateApprox | Computed | DWH_dbo.Fact_CurrencyPriceWithSplit | ROUND((Ask+Bid)/2, 2) at TxLocalDate |
| 63 | AccumulatedAmount | dbo.FiatTransactionsStatuses | AccumulatedAmount | Each status event (ALL RNDesc values) |
| 64 | AccumulatedUSDAmountApprox | Computed | AccumulatedAmount × mid-rate | Same logic as USDAmountApprox |
| 65 | TxStatusModificationTime | dbo.FiatTransactionsStatuses | TransactionOccured | Each status event (ALL RNDesc values) |
| 66 | TxStatusModificationDate | Computed | dbo.FiatTransactionsStatuses.TransactionOccured | CAST(TransactionOccured AS DATE) |
| 67 | TxStatusModificationDateID | Computed | dbo.FiatTransactionsStatuses.TransactionOccured | CONVERT(VARCHAR(8), TransactionOccured, 112)::INT |
| 68 | TxStatusCreatedDate | Computed | dbo.FiatTransactionsStatuses.Created | CAST(Created AS DATE) |
| 69 | TxStatusCreatedDateID | Computed | dbo.FiatTransactionsStatuses.Created | CONVERT(VARCHAR(8), Created, 112)::INT |
| 70 | TXStatusCorrelationID | dbo.FiatTransactionsStatuses | CorrelationId | CAST(CorrelationId AS VARCHAR(2000)) |
| 71 | RiskRuleCodes | dbo.FiatTransactionsStatuses | RiskRuleCodes | CAST(RiskRuleCodes AS VARCHAR(2000)) |
| 72 | MarkTransactionAsSuspiciousRiskAction | dbo.FiatTransactionsStatuses | MarkTransactionAsSuspiciousRiskAction | Passthrough |
| 73 | ChangeCardStatusToRiskRiskAction | dbo.FiatTransactionsStatuses | ChangeCardStatusToRiskRiskAction | Passthrough |
| 74 | ChangeAccountStatusToSuspendedRiskAction | dbo.FiatTransactionsStatuses | ChangeAccountStatusToSuspendedRiskAction | Passthrough |
| 75 | RejectTransactionRiskAction | dbo.FiatTransactionsStatuses | RejectTransactionRiskAction | Passthrough |
| 76 | UpdateDate | Computed | — | GETDATE() at INSERT time |
| 77 | SourceCugTransactionID | dbo.FiatTransactions | SourceCugTransactionId | Passthrough (added 2025-09-08) |

## Tier 1 Coverage Check

| Metric | Value |
|--------|-------|
| Total columns | 77 |
| Tier 1 (verbatim / T1+DWH note) | 8 |
| Tier 2 (computed/lookup/no-wiki) | 69 |
| Tier 1 % | 10.4% |
| Upstream matchable columns | 8 (from FiatAccount, FiatCards, FiatBankAccount, FiatCurrencyBalances wikis) |
| Covered | 8/8 = 100% of matchable columns |
| Note | FiatTransactions and FiatTransactionsStatuses have no FiatDwhDB wikis — all their direct columns are Tier 2; identical Tier 1 assignments as eMoney_Dim_Transaction |
| HARD FAIL check | PASS — 8 Tier 1 from available upstream wikis |

PHASE 10B CHECKPOINT: PASS
