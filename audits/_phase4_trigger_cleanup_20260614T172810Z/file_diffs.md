# Phase 4 per-file trigger removals - DRY-RUN

### `knowledge/skills/domain-compliance-and-aml/SKILL.md`

Triggers: 49 -> 48  (removed 1)

Removed:
- `PlayerStatus`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-compliance-and-aml/aml-regtech-pipeline.md`

Triggers: 40 -> 37  (removed 3)

Removed:
- `CitizenshipCountryID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `PlayerLevelID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `RegulationID`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-compliance-and-aml/aml-risk-scoring.md`

Triggers: 61 -> 60  (removed 1)

Removed:
- `PlayerStatus`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-cross/provider-reconciliation.md`

Triggers: 25 -> 22  (removed 3)

Removed:
- `MID`  (broker_provider_identity, primary: `domain-payments`)
- `MIDName`  (broker_provider_identity, primary: `domain-payments`)
- `MIDValue`  (broker_provider_identity, primary: `domain-payments`)

### `knowledge/skills/domain-cross/recurring-deposit-to-trade.md`

Triggers: 21 -> 17  (removed 4)

Removed:
- `BI_DB_First5Actions`  (trading_concepts, primary: `domain-customer-and-identity`)
- `fact_customeraction_w_metrics`  (trading_concepts, primary: `domain-trading`)
- `IsGlobalFTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `w_metrics`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-cross/tribe-emoney-audit.md`

Triggers: 28 -> 27  (removed 1)

Removed:
- `Treezor`  (broker_provider_identity, primary: `domain-payments`)

### `knowledge/skills/domain-customer-and-identity/SKILL.md`

Triggers: 64 -> 59  (removed 5)

Removed:
- `Fact_CustomerAction`  (trading_concepts, primary: `domain-trading`)
- `moneyfarmUserId`  (customer_identity_columns, primary: `domain-moneyfarm`)
- `onboarding funnel`  (customer_lifecycle_populations, primary: `domain-ops-and-onboarding`)
- `Popular Investor`  (trading_concepts, primary: `domain-trading`)
- `regulation`  (compliance_aml, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-customer-and-identity/compliance-customer-snapshot-and-club.md`

Triggers: 76 -> 72  (removed 4)

Removed:
- `Interest On Balance`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `IOB`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `IsActiveTrade`  (trading_concepts, primary: `domain-trading`)
- `ScreeningStatus`  (customer_identity_columns, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-customer-and-identity/customer-action-audit-trail.md`

Triggers: 60 -> 47  (removed 13)

Removed:
- `ActionTypeID`  (trading_concepts, primary: `domain-trading`)
- `CopyPositionOpen`  (trading_concepts, primary: `domain-trading`)
- `Fact_CustomerAction`  (trading_concepts, primary: `domain-trading`)
- `fact_customeraction`  (trading_concepts, primary: `domain-trading`)
- `IsFeeDividend`  (trading_concepts, primary: `domain-revenue-and-fees`)
- `IsPartialCloseChild`  (trading_concepts, primary: `domain-trading`)
- `IsPartialCloseParent`  (trading_concepts, primary: `domain-trading`)
- `ManualPositionOpen`  (trading_concepts, primary: `domain-trading`)
- `overnight fee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `SDRT`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `ticket fee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `VolumeOnClose`  (trading_concepts, primary: `domain-trading`)
- `VolumeOnOpen`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-customer-and-identity/customer-master-record.md`

Triggers: 42 -> 39  (removed 3)

Removed:
- `IsCreditReportValidCB`  (cross_cutting_utilities, primary: `cross-cutting`)
- `IsValidCustomer`  (cross_cutting_utilities, primary: `cross-cutting`)
- `VerificationLevelID`  (customer_identity_columns, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-customer-and-identity/customer-populations-and-lifecycle.md`

Triggers: 51 -> 49  (removed 2)

Removed:
- `IsSettled`  (trading_concepts, primary: `domain-trading`)
- `popular investor`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-customer-and-identity/identity-jurisdiction-and-regulation.md`

Triggers: 37 -> 36  (removed 1)

Removed:
- `regulation`  (compliance_aml, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-customer-and-identity/oltp-customer-static-and-breaches.md`

Triggers: 38 -> 36  (removed 2)

Removed:
- `EXW_DimUser`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW_DimUser_Enriched`  (wallet_infrastructure, primary: `domain-exw-wallet`)

### `knowledge/skills/domain-exw-wallet/SKILL.md`

Triggers: 80 -> 72  (removed 8)

Removed:
- `C2F`  (money_flow_crypto, primary: `domain-cross`)
- `C2P`  (money_flow_crypto, primary: `domain-payments`)
- `crypto to fiat`  (money_flow_crypto, primary: `domain-cross`)
- `crypto-to-fiat`  (money_flow_crypto, primary: `domain-cross`)
- `EXW_C2F_E2E`  (money_flow_crypto, primary: `domain-cross`)
- `EXW_C2P_E2E`  (money_flow_crypto, primary: `domain-payments`)
- `off-ramp`  (money_flow_crypto, primary: `domain-cross`)
- `Simplex`  (broker_provider_identity, primary: `domain-payments`)

### `knowledge/skills/domain-marketing-and-acquisition/affiliate-and-paid-media.md`

Triggers: 89 -> 88  (removed 1)

Removed:
- `Commission`  (fees_revenue, primary: `domain-revenue-and-fees`)

### `knowledge/skills/domain-moneyfarm/SKILL.md`

Triggers: 56 -> 55  (removed 1)

Removed:
- `externalUserId`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-moneyfarm/moneyfarm-data-patterns.md`

Triggers: 21 -> 20  (removed 1)

Removed:
- `fact_currencypricewithsplit`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-ops-and-onboarding/SKILL.md`

Triggers: 103 -> 101  (removed 2)

Removed:
- `SessionID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `VerificationLevelID`  (customer_identity_columns, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-ops-and-onboarding/electronic-verification-and-registration-funnel.md`

Triggers: 97 -> 94  (removed 3)

Removed:
- `IsDepositor`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `ScreeningStatus`  (customer_identity_columns, primary: `domain-compliance-and-aml`)
- `VerificationLevelID`  (customer_identity_columns, primary: `domain-compliance-and-aml`)

### `knowledge/skills/domain-ops-and-onboarding/kyc-document-pipeline.md`

Triggers: 71 -> 70  (removed 1)

Removed:
- `SessionID`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-ops-and-onboarding/ops-portal-and-alerts.md`

Triggers: 70 -> 67  (removed 3)

Removed:
- `AlertID`  (compliance_aml, primary: `domain-compliance-and-aml`)
- `MultipleAccounts`  (compliance_aml, primary: `domain-compliance-and-aml`)
- `PlayerStatus`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-options/SKILL.md`

Triggers: 53 -> 48  (removed 5)

Removed:
- `apex`  (broker_provider_identity, primary: `domain-cross`)
- `apex sod`  (broker_provider_identity, primary: `domain-cross`)
- `appropriateness test`  (compliance_aml, primary: `domain-customer-and-identity`)
- `gatsby`  (broker_provider_identity, primary: `domain-cross`)
- `USABroker`  (broker_provider_identity, primary: `domain-cross`)

### `knowledge/skills/domain-options/options-views-architecture.md`

Triggers: 36 -> 32  (removed 4)

Removed:
- `IsCreditReportValidCB`  (cross_cutting_utilities, primary: `cross-cutting`)
- `IsFTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `IsGlobalFTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `IsValidCustomer`  (cross_cutting_utilities, primary: `cross-cutting`)

### `knowledge/skills/domain-payments/SKILL.md`

Triggers: 72 -> 46  (removed 26)

Removed:
- `Apex`  (broker_provider_identity, primary: `domain-cross`)
- `Apex BuyingPower`  (broker_provider_identity, primary: `domain-cross`)
- `Apex SOD`  (broker_provider_identity, primary: `domain-cross`)
- `BI_DB_DepositWithdrawFee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `BlockchainTransactionId`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `C2F`  (money_flow_crypto, primary: `domain-cross`)
- `chargeback`  (money_flow_fiat, primary: `domain-cross`)
- `CorrelationId`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `crypto`  (trading_concepts, primary: `domain-trading`)
- `crypto-to-fiat`  (money_flow_crypto, primary: `domain-cross`)
- `Customer_Daily_Status`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `Customer_Periodic_Status`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `EXW`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `Fact_Trading_Volumes_And_Amounts`  (trading_concepts, primary: `domain-trading`)
- `FTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `IsCryptoToFiat`  (money_flow_crypto, primary: `domain-cross`)
- `IsGlobalFTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `IsInternalTransfer`  (niche_platform_spaceship, primary: `domain-options`)
- `on-chain`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `Redemption`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `refund`  (money_flow_fiat, primary: `domain-cross`)
- `reversal`  (money_flow_fiat, primary: `domain-cross`)
- `share lending`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `USABroker`  (broker_provider_identity, primary: `domain-cross`)
- `v_options_aum`  (aum_aua, primary: `domain-options`)
- `v_population_active_traders`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-payments/crypto-wallet.md`

Triggers: 39 -> 12  (removed 27)

Removed:
- `AML wallet`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `AmlValidations`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `BlockchainCryptoId`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `BlockchainTransactionId`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `bronze_walletdb_wallet`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `C2F`  (money_flow_crypto, primary: `domain-cross`)
- `CorrelationId`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `crypto wallet`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `crypto-to-fiat`  (money_flow_crypto, primary: `domain-cross`)
- `CustomerWalletsView`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `eToro Wallet`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW_C2F_E2E`  (money_flow_crypto, primary: `domain-cross`)
- `EXW_DimUser`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW_EthFeeSent_Blockchain`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW_FactTransactions`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `EXW_WalletInventory`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `gas fee`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `off-ramp`  (money_flow_crypto, primary: `domain-cross`)
- `on-chain`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `public address`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `Redemption`  (money_flow_crypto, primary: `domain-exw-wallet`)
- `SendRequestCorrelationId`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `Tangany`  (broker_provider_identity, primary: `domain-exw-wallet`)
- `WalletBalances`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `WalletId`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `WalletPool`  (wallet_infrastructure, primary: `domain-exw-wallet`)

### `knowledge/skills/domain-payments/deposits-and-withdrawals.md`

Triggers: 35 -> 25  (removed 10)

Removed:
- `bi_db_depositwithdrawfee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `chargeback`  (money_flow_fiat, primary: `domain-cross`)
- `conversion fee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `DepositWithdrawFee`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `DepositWithdrawFee_Reversals`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `depot`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `FTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `PIPsCalculation`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `refund`  (money_flow_fiat, primary: `domain-cross`)
- `reversal`  (money_flow_fiat, primary: `domain-cross`)

### `knowledge/skills/domain-payments/emoney-accounts-and-cards.md`

Triggers: 37 -> 34  (removed 3)

Removed:
- `card lifecycle`  (money_flow_fiat, primary: `domain-cross`)
- `IsCryptoToFiat`  (money_flow_crypto, primary: `domain-cross`)
- `MoveMoneyReasonID`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-payments/finance-recon-and-balances.md`

Triggers: 36 -> 25  (removed 11)

Removed:
- `active traders`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `Apex`  (broker_provider_identity, primary: `domain-cross`)
- `Apex BuyingPower`  (broker_provider_identity, primary: `domain-cross`)
- `Apex SOD`  (broker_provider_identity, primary: `domain-cross`)
- `EXW_FinanceReportsBalancesNew`  (wallet_infrastructure, primary: `domain-exw-wallet`)
- `FTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `share lending`  (fees_revenue, primary: `domain-revenue-and-fees`)
- `USABroker`  (broker_provider_identity, primary: `domain-cross`)
- `v_options_aum`  (aum_aua, primary: `domain-options`)
- `v_population_active_traders`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `v_population_first_time_funded`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-payments/mimo-panel-and-ddr.md`

Triggers: 41 -> 31  (removed 10)

Removed:
- `AUM`  (aum_aua, primary: `domain-aum-and-aua`)
- `FTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `Gatsby`  (broker_provider_identity, primary: `domain-cross`)
- `IsCryptoToFiat`  (money_flow_crypto, primary: `domain-cross`)
- `IsGlobalFTD`  (money_flow_fiat, primary: `domain-customer-and-identity`)
- `IsInternalTransfer`  (niche_platform_spaceship, primary: `domain-options`)
- `IsRecurring`  (money_flow_fiat, primary: `domain-cross`)
- `MoneyFarm FTD`  (money_flow_fiat, primary: `domain-moneyfarm`)
- `Options FTD`  (money_flow_fiat, primary: `domain-options`)
- `v_mimo_options_platform`  (fees_revenue, primary: `domain-options`)

### `knowledge/skills/domain-revenue-and-fees/SKILL.md`

Triggers: 67 -> 60  (removed 7)

Removed:
- `C2F`  (money_flow_crypto, primary: `domain-cross`)
- `crypto to fiat`  (money_flow_crypto, primary: `domain-cross`)
- `fact_customeraction_w_metrics`  (trading_concepts, primary: `domain-trading`)
- `gatsby`  (broker_provider_identity, primary: `domain-cross`)
- `moneyfarm fees`  (fees_revenue, primary: `domain-moneyfarm`)
- `options revenue`  (fees_revenue, primary: `domain-options`)
- `PFOF`  (fees_revenue, primary: `domain-options`)

### `knowledge/skills/domain-revenue-and-fees/revenue-moneyfarm.md`

Triggers: 20 -> 0  (removed 20)

Removed:
- `ben thompson`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `benth`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `bi_output_moneyfarm_customers`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `bi_output_moneyfarm_fact_portfolio_snapshot`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `bi_output_moneyfarm_fact_transactions`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `bronze_moneyfarm_users`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `isa`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `money farm`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `moneyfarm`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `MoneyFarm`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `Moneyfarm`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `moneyfarm aum`  (aum_aua, primary: `domain-moneyfarm`)
- `moneyfarm cohort`  (fees_revenue, primary: `domain-moneyfarm`)
- `moneyfarm fees`  (fees_revenue, primary: `domain-moneyfarm`)
- `moneyfarm mimo`  (fees_revenue, primary: `domain-moneyfarm`)
- `silver_moneyfarm_etoro_mf_aum`  (fees_revenue, primary: `domain-moneyfarm`)
- `uk isa`  (niche_platform_moneyfarm, primary: `domain-moneyfarm`)
- `v_moneyfarm_aum`  (aum_aua, primary: `domain-moneyfarm`)
- `v_moneyfarm_fees`  (fees_revenue, primary: `domain-moneyfarm`)
- `v_moneyfarm_mimo`  (fees_revenue, primary: `domain-moneyfarm`)

### `knowledge/skills/domain-spaceship/spaceship-dashboard-queries.md`

Triggers: 34 -> 32  (removed 2)

Removed:
- `Funded Accounts`  (customer_lifecycle_populations, primary: `domain-customer-and-identity`)
- `Net Deposits`  (money_flow_fiat, primary: `domain-payments`)

### `knowledge/skills/domain-spaceship/spaceship-data-patterns.md`

Triggers: 34 -> 33  (removed 1)

Removed:
- `fact_currencypricewithsplit`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-staking/SKILL.md`

Triggers: 131 -> 128  (removed 3)

Removed:
- `airdrop`  (marketing, primary: `domain-marketing-and-acquisition`)
- `PlayerLevelID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `Tangany`  (broker_provider_identity, primary: `domain-exw-wallet`)

### `knowledge/skills/domain-staking/currency-catalog-and-parameters.md`

Triggers: 44 -> 42  (removed 2)

Removed:
- `ETH`  (trading_concepts, primary: `domain-trading`)
- `InstrumentID`  (trading_concepts, primary: `domain-trading`)

### `knowledge/skills/domain-staking/distribution-pipeline.md`

Triggers: 61 -> 58  (removed 3)

Removed:
- `Airdrop`  (marketing, primary: `domain-marketing-and-acquisition`)
- `Dim_Position`  (trading_concepts, primary: `domain-trading`)
- `reconciliation`  (cross_cutting_utilities, primary: `domain-cross`)

### `knowledge/skills/domain-staking/eligibility-and-gates.md`

Triggers: 52 -> 43  (removed 9)

Removed:
- `AccountTypeID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `CountryID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `IsCreditReportValidCB`  (cross_cutting_utilities, primary: `cross-cutting`)
- `PlayerLevelID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `PlayerStatus`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `PlayerStatusID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `RegulationID`  (customer_identity_columns, primary: `domain-customer-and-identity`)
- `Smart Portfolio`  (trading_concepts, primary: `domain-trading`)
- `Tangany`  (broker_provider_identity, primary: `domain-exw-wallet`)

### `knowledge/skills/domain-staking/rewards-formula-and-calculation.md`

Triggers: 44 -> 43  (removed 1)

Removed:
- `PlayerLevelID`  (customer_identity_columns, primary: `domain-customer-and-identity`)

### `knowledge/skills/domain-trading/SKILL.md`

Triggers: 106 -> 104  (removed 2)

Removed:
- `AUM`  (aum_aua, primary: `domain-aum-and-aua`)
- `latency`  (cross_cutting_utilities, primary: `cross-cutting`)

### `knowledge/skills/domain-trading/broker-and-lp-reconciliation.md`

Triggers: 43 -> 42  (removed 1)

Removed:
- `reconciliation`  (cross_cutting_utilities, primary: `domain-cross`)

### `knowledge/skills/domain-trading/copy-trading-and-mirror.md`

Triggers: 20 -> 19  (removed 1)

Removed:
- `C2P`  (money_flow_crypto, primary: `domain-payments`)

### `knowledge/skills/domain-trading/dealing-investigation-and-execution.md`

Triggers: 75 -> 74  (removed 1)

Removed:
- `DMA`  (marketing, primary: `domain-marketing-and-acquisition`)

### `knowledge/skills/domain-trading/portfolio-value-aum-pnl.md`

Triggers: 37 -> 31  (removed 6)

Removed:
- `assets under management`  (aum_aua, primary: `domain-aum-and-aua`)
- `AUM`  (aum_aua, primary: `domain-aum-and-aua`)
- `EquityGlobal`  (aum_aua, primary: `domain-aum-and-aua`)
- `IBANBalance`  (aum_aua, primary: `domain-aum-and-aua`)
- `OptionsTotalEquity`  (aum_aua, primary: `domain-aum-and-aua`)
- `TotalEquityTP`  (aum_aua, primary: `domain-aum-and-aua`)

### `knowledge/skills/domain-trading/trading-volumes.md`

Triggers: 51 -> 48  (removed 3)

Removed:
- `airdrop`  (marketing, primary: `domain-marketing-and-acquisition`)
- `C2P`  (money_flow_crypto, primary: `domain-payments`)
- `recurring investment`  (money_flow_fiat, primary: `domain-cross`)

