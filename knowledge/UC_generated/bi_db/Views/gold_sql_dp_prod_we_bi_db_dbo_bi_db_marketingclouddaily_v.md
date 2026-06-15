---
object_fqn: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v
object_type: VIEW
producer_kind: unknown
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v
schema: bi_db
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 100
row_count: null
generated_at: '2026-05-19T12:13:13Z'
upstreams: []
writer:
  kind: unknown
  path: null
  source_code_snapshot: null
concept_count: 0
formula_count: 0
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 100
---

# gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v

> Table (unknown writer) in `main.bi_db`. 0 business concept(s) in §2; 0 of 100 columns documented from anchored evidence; 100 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | katyfr@etoro.com |
| **Row count** | n/a |
| **Column count** | 100 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 29 11:46:37 UTC 2026 |

---

## 1. Business Meaning

`gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v` is a table (unknown writer) in `main.bi_db`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

No upstream UC objects tracked in lineage — this object's source code may not have been parsed yet, or it reads from external paths. See `.lineage.md`.

Of its 100 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountId | STRING | YES | Transform `runtime_lineage` for column `AccountId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | CID | INT | YES | Transform `runtime_lineage` for column `CID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | MobileAppLastLogin | TIMESTAMP | YES | Transform `runtime_lineage` for column `MobileAppLastLogin` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | WatchlistLastAddedETF | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedETF` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | WatchlistLastAddedCrypto | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedCrypto` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | WatchlistLastAddedStocks | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedStocks` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | WatchlistLastAddedCommodities | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedCommodities` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | WatchlistLastAddedIndecies | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedIndecies` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | WatchlistLastAddedPI | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedPI` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | WatchlistLastAddedCopyPortfolio | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedCopyPortfolio` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | WatchlistLastAddedNonPIUser | TIMESTAMP | YES | Transform `runtime_lineage` for column `WatchlistLastAddedNonPIUser` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | WatchlistLastDateID | INT | YES | Transform `runtime_lineage` for column `WatchlistLastDateID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | GainThisWeek | DECIMAL | YES | Transform `runtime_lineage` for column `GainThisWeek` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | GainOneMonthAgo | DECIMAL | YES | Transform `runtime_lineage` for column `GainOneMonthAgo` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | GainThreeMonthsAgo | DECIMAL | YES | Transform `runtime_lineage` for column `GainThreeMonthsAgo` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 15 | GainSixMonthsAgo | DECIMAL | YES | Transform `runtime_lineage` for column `GainSixMonthsAgo` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 16 | GainOneYearAgo | DECIMAL | YES | Transform `runtime_lineage` for column `GainOneYearAgo` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 17 | GainLastDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `GainLastDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 18 | GainExecutionID | INT | YES | Transform `runtime_lineage` for column `GainExecutionID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 19 | UpdateDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `UpdateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 20 | eMoneyIsInRollout | INT | YES | Transform `runtime_lineage` for column `eMoneyIsInRollout` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 21 | eMoneyIsInRolloutDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyIsInRolloutDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 22 | AirDropRemainder | INT | YES | Transform `runtime_lineage` for column `AirDropRemainder` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 23 | VerificationLevel3Date | TIMESTAMP | YES | Transform `runtime_lineage` for column `VerificationLevel3Date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 24 | AirdropServeyDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `AirdropServeyDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 25 | AirdropPotentialUpdateDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `AirdropPotentialUpdateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 26 | WalletLastLogin | TIMESTAMP | YES | Transform `runtime_lineage` for column `WalletLastLogin` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 27 | eMoneyExternalTransferToIBANLastDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyExternalTransferToIBANLastDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 28 | eMoneyDepositToPlatformLastDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyDepositToPlatformLastDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 29 | eMoneyWithrawalFromPlatformLastDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyWithrawalFromPlatformLastDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 30 | eMoneyEODBalanceAmount | DECIMAL | YES | Transform `runtime_lineage` for column `eMoneyEODBalanceAmount` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 31 | eMoneyEODBalanceDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyEODBalanceDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 32 | eMoneyCardTransactionLastDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `eMoneyCardTransactionLastDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 33 | KYCFlowName | STRING | YES | Transform `runtime_lineage` for column `KYCFlowName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 34 | KYCLeadScore | STRING | YES | Transform `runtime_lineage` for column `KYCLeadScore` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 35 | AirdropCustomerID | STRING | YES | Transform `runtime_lineage` for column `AirdropCustomerID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 36 | Credit | DECIMAL | YES | Transform `runtime_lineage` for column `Credit` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 37 | FirstTimeCopiedDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `FirstTimeCopiedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 38 | PrivacyPolicyID | INT | YES | Transform `runtime_lineage` for column `PrivacyPolicyID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 39 | LSD | STRING | YES | Transform `runtime_lineage` for column `LSD` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 40 | LSDDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `LSDDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 41 | TX_Tier_3M | STRING | YES | Transform `runtime_lineage` for column `TX_Tier_3M` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 42 | Amount_Tier_3M | STRING | YES | Transform `runtime_lineage` for column `Amount_Tier_3M` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 43 | TX_Tier_3M_Deposits | STRING | YES | Transform `runtime_lineage` for column `TX_Tier_3M_Deposits` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 44 | TX_Tier_3M_CO | STRING | YES | Transform `runtime_lineage` for column `TX_Tier_3M_CO` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 45 | Amount_Tier_3M_CO | STRING | YES | Transform `runtime_lineage` for column `Amount_Tier_3M_CO` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 46 | Amount_Tier_3M_Deposits | STRING | YES | Transform `runtime_lineage` for column `Amount_Tier_3M_Deposits` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 47 | AccountSubProgram | STRING | YES | Transform `runtime_lineage` for column `AccountSubProgram` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 48 | CardCreateDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `CardCreateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 49 | KYC_Experience_Level | STRING | YES | Transform `runtime_lineage` for column `KYC_Experience_Level` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 50 | KYC_Planned_Invested_Amount | STRING | YES | Transform `runtime_lineage` for column `KYC_Planned_Invested_Amount` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 51 | KYC_CFD_Level | STRING | YES | Transform `runtime_lineage` for column `KYC_CFD_Level` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 52 | IOB_Opt_In | INT | YES | Transform `runtime_lineage` for column `IOB_Opt_In` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 53 | IOB_Opt_In_ValidFrom | TIMESTAMP | YES | Transform `runtime_lineage` for column `IOB_Opt_In_ValidFrom` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 54 | AmountToClubUpgrade | DECIMAL | YES | Transform `runtime_lineage` for column `AmountToClubUpgrade` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 55 | UnRealizedEquity | DECIMAL | YES | Transform `runtime_lineage` for column `UnRealizedEquity` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 56 | MaxEquity_LastYear | DECIMAL | YES | Transform `runtime_lineage` for column `MaxEquity_LastYear` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 57 | MaxEquity_LastWeek | DECIMAL | YES | Transform `runtime_lineage` for column `MaxEquity_LastWeek` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 58 | CashoutAmount_LastWeek | DECIMAL | YES | Transform `runtime_lineage` for column `CashoutAmount_LastWeek` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 59 | CashoutAmount_InProcess | DECIMAL | YES | Transform `runtime_lineage` for column `CashoutAmount_InProcess` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 60 | TotalDepositsAmount_LastYear | DECIMAL | YES | Transform `runtime_lineage` for column `TotalDepositsAmount_LastYear` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 61 | KYC_PlannedInvestment_Stocks | INT | YES | Transform `runtime_lineage` for column `KYC_PlannedInvestment_Stocks` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 62 | KYC_PlannedInvestment_Crypto | INT | YES | Transform `runtime_lineage` for column `KYC_PlannedInvestment_Crypto` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 63 | KYC_PlannedInvestment_FX | INT | YES | Transform `runtime_lineage` for column `KYC_PlannedInvestment_FX` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 64 | Total_KYC_PlannedInvestment_Answers | INT | YES | Transform `runtime_lineage` for column `Total_KYC_PlannedInvestment_Answers` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 65 | StocksLendingStatusID | INT | YES | Transform `runtime_lineage` for column `StocksLendingStatusID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 66 | StocksLendingOptInDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `StocksLendingOptInDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 67 | eTM_IBAN_Type | STRING | YES | Transform `runtime_lineage` for column `eTM_IBAN_Type` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 68 | eTM_AccountName_LocalCurrency | STRING | YES | Transform `runtime_lineage` for column `eTM_AccountName_LocalCurrency` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 69 | Cluster | STRING | YES | Transform `runtime_lineage` for column `Cluster` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 70 | ClusterDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `ClusterDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 71 | PositionOpen_LastDate_ETF | TIMESTAMP | YES | Transform `runtime_lineage` for column `PositionOpen_LastDate_ETF` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 72 | Rewarded_LastMonth_eMoney | TIMESTAMP | YES | Transform `runtime_lineage` for column `Rewarded_LastMonth_eMoney` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 73 | Monthly_CardSpent_eMoney | DECIMAL | YES | Transform `runtime_lineage` for column `Monthly_CardSpent_eMoney` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 74 | Monthly_RewardedChashBack_eMoney | DECIMAL | YES | Transform `runtime_lineage` for column `Monthly_RewardedChashBack_eMoney` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 75 | Monthly_CardEligibleCashBack_eMoney | DECIMAL | YES | Transform `runtime_lineage` for column `Monthly_CardEligibleCashBack_eMoney` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 76 | FirstDepositDateGlobal | TIMESTAMP | YES | Transform `runtime_lineage` for column `FirstDepositDateGlobal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 77 | DepositsUSD_Global | DECIMAL | YES | Transform `runtime_lineage` for column `DepositsUSD_Global` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 78 | BalanceGlobal | DECIMAL | YES | Transform `runtime_lineage` for column `BalanceGlobal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 79 | EquityGlobal | DECIMAL | YES | Transform `runtime_lineage` for column `EquityGlobal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 80 | Total_Deposit_USD | DECIMAL | YES | Transform `runtime_lineage` for column `Total_Deposit_USD` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 81 | Total_Deposit_EUR | DECIMAL | YES | Transform `runtime_lineage` for column `Total_Deposit_EUR` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 82 | Total_Deposit_GBP | DECIMAL | YES | Transform `runtime_lineage` for column `Total_Deposit_GBP` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 83 | Current_Balance_USD | DECIMAL | YES | Transform `runtime_lineage` for column `Current_Balance_USD` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 84 | Current_Balance_EUR | DECIMAL | YES | Transform `runtime_lineage` for column `Current_Balance_EUR` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 85 | Current_Balance_GBP | DECIMAL | YES | Transform `runtime_lineage` for column `Current_Balance_GBP` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 86 | LastTransactionDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `LastTransactionDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 87 | AcceptedTnCs_Date | TIMESTAMP | YES | Transform `runtime_lineage` for column `AcceptedTnCs_Date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 88 | DIY_PortfolioCreatedDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `DIY_PortfolioCreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 89 | DIY_FirstDepositDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `DIY_FirstDepositDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 90 | Cash_PortfolioCreatedDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `Cash_PortfolioCreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 91 | Cash_FirstDepositDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `Cash_FirstDepositDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 92 | Managed_PortfolioCreatedDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `Managed_PortfolioCreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 93 | Managed_FirstDepositDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `Managed_FirstDepositDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 94 | IsDefunded_across_all_portfolios | BOOLEAN | YES | Transform `runtime_lineage` for column `IsDefunded_across_all_portfolios` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 95 | RAF_Inviter | DECIMAL | YES | Transform `runtime_lineage` for column `RAF_Inviter` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 96 | RAF_LastCashoutDate | TIMESTAMP | YES | Transform `runtime_lineage` for column `RAF_LastCashoutDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 97 | etr_y | STRING | YES | Transform `runtime_lineage` for column `etr_y` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 98 | etr_ym | STRING | YES | Transform `runtime_lineage` for column `etr_ym` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 99 | etr_ymd | STRING | YES | Transform `runtime_lineage` for column `etr_ymd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=100 runtime=100 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)


### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 0 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 100 U | Elements: 100/100 | Source: unknown*
