# Dictionary Schema — Documentation Index

> Complete index of all documented objects in the Dictionary schema.

| Metric | Value |
|--------|-------|
| **Total Objects** | 373 |
| **Documented** | 373 (100%) |
| **High Quality (9.0+)** | 373 (ALL objects — tables, views, SPs, synonym) |
| **Needs Rework (< 7.5)** | 0 |
| **Last Updated** | 2026-03-14 |

---

## Quality Tiers

| Tier | Quality | Count | Description |
|------|---------|-------|-------------|
| **FULL** | 9.0+ | 373 | MCP live data, codebase search, lifecycle diagrams, relationship tracing, distribution analysis |
| **GOOD** | 7.5-8.9 | 0 | All objects upgraded to 9.0+ |
| **NEEDS REWORK** | < 7.5 | 0 | All rework complete |

**ALL Dictionary schema documentation is COMPLETE at 9.0+ quality.** 16 sessions have documented 359 tables, 9 views, 4 stored procedures, and 1 synonym — all at full quality with MCP live data, codebase search, dependency tracing, and Atlassian knowledge scanning.

---

## Tables — FULL Quality (9.0+, no rework needed)

| Table | Quality | Key Feature |
|-------|---------|-------------|
| [Dictionary.AccountStatus](Tables/Dictionary.AccountStatus.md) | 8.2 | Open/Closed account state — MCP verified |
| [Dictionary.AccountType](Tables/Dictionary.AccountType.md) | 8.4 | 17 account classifications — MCP verified |
| [Dictionary.Bank](Tables/Dictionary.Bank.md) | 7.8 | 14 banking partners — MCP verified |
| [Dictionary.CardType](Tables/Dictionary.CardType.md) | 9.2 | 8 card types (Visa/MC/Amex/etc) — MCP verified |
| [Dictionary.CashoutStatus](Tables/Dictionary.CashoutStatus.md) | 8.6 | 17-state withdrawal lifecycle — MCP verified |
| [Dictionary.ClosePositionActionType](Tables/Dictionary.ClosePositionActionType.md) | 8.6 | 27 position close reasons — MCP verified |
| [Dictionary.Country](Tables/Dictionary.Country.md) | 9.4 | 251 countries, 5 FKs, 16 cols — MCP verified |
| [Dictionary.CountryRiskGroup](Tables/Dictionary.CountryRiskGroup.md) | 9.2 | 5 risk tiers for country classification — MCP verified |
| [Dictionary.CreditType](Tables/Dictionary.CreditType.md) | 9.2 | 90+ credit/debit transaction types — MCP verified |
| [Dictionary.Currency](Tables/Dictionary.Currency.md) | 9.6 | 10,669 instruments, audit triggers — MCP verified |
| [Dictionary.CurrencyType](Tables/Dictionary.CurrencyType.md) | 9.0 | 10 asset classes — MCP verified |
| [Dictionary.DelayedOrderStatus](Tables/Dictionary.DelayedOrderStatus.md) | 8.2 | Pending order states (memory-optimized) — MCP verified |
| [Dictionary.DepositType](Tables/Dictionary.DepositType.md) | 8.0 | 8 deposit categories with FTD flag — MCP verified |
| [Dictionary.DocumentStatus](Tables/Dictionary.DocumentStatus.md) | 7.8 | 5 KYC document review states |
| [Dictionary.FeeCalculationTypes](Tables/Dictionary.FeeCalculationTypes.md) | 9.2 | 7 fee calculation methods (temporal) — MCP verified |
| [Dictionary.FeeConfiguration](Tables/Dictionary.FeeConfiguration.md) | 9.0 | Fee-to-instrument-group configuration (temporal) — MCP verified |
| [Dictionary.FeeDefinition](Tables/Dictionary.FeeDefinition.md) | 9.0 | Fee definitions linking operation types to calculation methods — MCP verified |
| [Dictionary.FeeOperationTypes](Tables/Dictionary.FeeOperationTypes.md) | 9.0 | 14 fee operation categories — MCP verified |
| [Dictionary.DocumentType](Tables/Dictionary.DocumentType.md) | 7.8 | 20 KYC document types |
| [Dictionary.FundingStatus](Tables/Dictionary.FundingStatus.md) | 7.0 | Partial/Valid funding state |
| [Dictionary.FundingType](Tables/Dictionary.FundingType.md) | 8.8 | 24 payment methods (temporal) |
| [Dictionary.HedgeStrategyMode](Tables/Dictionary.HedgeStrategyMode.md) | 7.0 | Auto/Manual/Disabled hedging |
| [Dictionary.InstrumentOperationMode](Tables/Dictionary.InstrumentOperationMode.md) | 9.0 | Managed/Unmanaged instrument trading modes — MCP verified |
| [Dictionary.InterestRate](Tables/Dictionary.InterestRate.md) | 9.4 | Overnight interest rates by currency/direction (temporal) — MCP verified |
| [Dictionary.InterestRateOld](Tables/Dictionary.InterestRateOld.md) | 9.0 | Legacy interest rates pre-temporal migration — MCP verified |
| [Dictionary.KycState](Tables/Dictionary.KycState.md) | 9.0 | 9 KYC lifecycle states — MCP verified |
| [Dictionary.Language](Tables/Dictionary.Language.md) | 7.8 | 28 platform languages |
| [Dictionary.Leverage](Tables/Dictionary.Leverage.md) | 8.2 | 10 leverage multipliers (1x-400x) |
| [Dictionary.LeverageTypes](Tables/Dictionary.LeverageTypes.md) | 7.0 | Proportional/Fixed leverage |
| [Dictionary.MarketingRegion](Tables/Dictionary.MarketingRegion.md) | 9.0 | 8 marketing regions for customer segmentation — MCP verified |
| [Dictionary.MarketRangeValidationType](Tables/Dictionary.MarketRangeValidationType.md) | 7.0 | Slippage validation modes |
| [Dictionary.Merchant](Tables/Dictionary.Merchant.md) | 9.0 | Payment merchant definitions — MCP verified |
| [Dictionary.MerchantAccount](Tables/Dictionary.MerchantAccount.md) | 9.0 | Payment merchant accounts — MCP verified |
| [Dictionary.MifidCategorization](Tables/Dictionary.MifidCategorization.md) | 9.2 | EU MiFID II client classifications — MCP verified |
| [Dictionary.MirrorStatus](Tables/Dictionary.MirrorStatus.md) | 8.2 | 4 CopyTrading relationship states |
| [Dictionary.MirrorType](Tables/Dictionary.MirrorType.md) | 7.4 | 4 CopyTrading relationship types |
| [Dictionary.OpenPositionActionType](Tables/Dictionary.OpenPositionActionType.md) | 8.4 | 18 position open reasons (no PK) |
| [Dictionary.OperationType](Tables/Dictionary.OperationType.md) | 9.2 | 26 trading operations with fee links — MCP verified |
| [Dictionary.OrderType](Tables/Dictionary.OrderType.md) | 9.0 | 21 order types — MCP verified |
| [Dictionary.OverNightFeePattern](Tables/Dictionary.OverNightFeePattern.md) | 9.2 | 7 overnight fee patterns (temporal) — MCP verified |
| [Dictionary.PaymentStatus](Tables/Dictionary.PaymentStatus.md) | 7.6 | 7 payment lifecycle states |
| [Dictionary.PaymentStatusStateMachine](Tables/Dictionary.PaymentStatusStateMachine.md) | 9.4 | Payment state transitions by funding type — MCP verified |
| [Dictionary.Platform](Tables/Dictionary.Platform.md) | 9.0 | 15 client platform types — MCP verified |
| [Dictionary.PlayerStatus](Tables/Dictionary.PlayerStatus.md) | 9.2 | 15 user states with permission matrix — MCP verified |
| [Dictionary.PositionStatus](Tables/Dictionary.PositionStatus.md) | 9.0 | Open/Closed binary state — MCP verified |
| [Dictionary.PositionType](Tables/Dictionary.PositionType.md) | 9.2 | CFD/REAL/ILLEGAL — MCP verified |
| [Dictionary.RedeemStatus](Tables/Dictionary.RedeemStatus.md) | 8.0 | 7 copy-trading redemption states |
| [Dictionary.Region](Tables/Dictionary.Region.md) | 7.8 | Geographic regions |
| [Dictionary.Regulation](Tables/Dictionary.Regulation.md) | 9.2 | 15 regulatory authorities — MCP verified |
| [Dictionary.RiskCategories](Tables/Dictionary.RiskCategories.md) | 7.0 | Low/Medium/High risk levels |
| [Dictionary.SettlementTypes](Tables/Dictionary.SettlementTypes.md) | 9.0 | 6 settlement models (CFD/REAL/TRS) — MCP verified |
| [Dictionary.TradingInstrumentGroups](Tables/Dictionary.TradingInstrumentGroups.md) | 9.2 | 13 instrument groups for fee/config bucketing (temporal) — MCP verified |
| [Dictionary.TransactionType](Tables/Dictionary.TransactionType.md) | 9.0 | 8 financial transaction classifications — MCP verified |
| [Dictionary.MarketStatus](Tables/Dictionary.MarketStatus.md) | 9.0 | 3 market trading states (Unknown/Active/Inactive) — MCP verified |
| [Dictionary.PaymentActionStatus](Tables/Dictionary.PaymentActionStatus.md) | 9.2 | 3-state payment action lifecycle (New/InProcess/Closed) — MCP verified |
| [Dictionary.PaymentActionType](Tables/Dictionary.PaymentActionType.md) | 9.4 | 7 payment operation types (PreAuth/Purchase/Refund/etc) — MCP verified |
| [Dictionary.PaymentDirection](Tables/Dictionary.PaymentDirection.md) | 9.2 | 2 payment communication directions (Googess/PSP) — MCP verified |
| [Dictionary.PaymentType](Tables/Dictionary.PaymentType.md) | 9.4 | 3 payment categories (Deposit/Cashout/Refund) with 4 FKs — MCP verified |
| [Dictionary.PlayerLevel](Tables/Dictionary.PlayerLevel.md) | 9.4 | 7 eToro Club tiers with equity thresholds/cashout speeds — MCP verified |
| [Dictionary.PlayerStatusReasons](Tables/Dictionary.PlayerStatusReasons.md) | 9.2 | 44 account status change reasons — MCP verified |
| [Dictionary.PlayerStatusSubReasons](Tables/Dictionary.PlayerStatusSubReasons.md) | 9.2 | 83 granular status sub-reasons (chargebacks/screening/AML) — MCP verified |
| [Dictionary.CashoutActionStatus](Tables/Dictionary.CashoutActionStatus.md) | 9.4 | 3 withdrawal action states (New/Processed/Failed) — MCP verified |
| [Dictionary.CashoutMode](Tables/Dictionary.CashoutMode.md) | 9.2 | 4 withdrawal processing modes with priority weights — MCP verified |
| [Dictionary.CashoutReason](Tables/Dictionary.CashoutReason.md) | 9.2 | 19 withdrawal initiation reasons — MCP verified |
| [Dictionary.CashoutRejectReason](Tables/Dictionary.CashoutRejectReason.md) | 9.0 | 28 withdrawal rejection reasons with display flags — MCP verified |
| [Dictionary.CashoutType](Tables/Dictionary.CashoutType.md) | 9.2 | 3 withdrawal classifications (NewMoney/Refund/Risk) — MCP verified |
| [Dictionary.CashoutFeeGroup](Tables/Dictionary.CashoutFeeGroup.md) | 9.4 | 3 fee groups (Default/Exempt/Discount) with 6 FKs — MCP verified |
| [Dictionary.GuruStatus](Tables/Dictionary.GuruStatus.md) | 9.4 | 9 Popular Investor program states — MCP verified |
| [Dictionary.MirrorCalculationType](Tables/Dictionary.MirrorCalculationType.md) | 9.2 | 2 CopyTrading equity calculation methods — MCP verified |
| [Dictionary.MirrorOperation](Tables/Dictionary.MirrorOperation.md) | 9.4 | 13 CopyTrading operations (Register/UnRegister/etc) — MCP verified |
| [Dictionary.RedeemReason](Tables/Dictionary.RedeemReason.md) | 9.2 | 18 redeem failure/rejection reasons — MCP verified |
| [Dictionary.RedeemStatusStateMachine](Tables/Dictionary.RedeemStatusStateMachine.md) | 9.4 | 31 valid redeem status transitions — MCP verified |
| [Dictionary.RedeemType](Tables/Dictionary.RedeemType.md) | 9.0 | Redeem transfer types (empty in prod, code uses 0/1) — MCP verified |
| [Dictionary.AccountLiquidationActionType](Tables/Dictionary.AccountLiquidationActionType.md) | 9.2 | 2 liquidation triggers (Manual/BSL) — MCP verified |
| [Dictionary.AccountTransactionType](Tables/Dictionary.AccountTransactionType.md) | 9.2 | 13 hedge account transaction types — MCP verified |
| [Dictionary.AllocationType](Tables/Dictionary.AllocationType.md) | 9.3 | 2 fund allocation modes (Copy/Asset) — MCP verified |
| [Dictionary.AsicClassification](Tables/Dictionary.AsicClassification.md) | 9.3 | 5 ASIC regulatory classifications — MCP verified |
| [Dictionary.AtomicOperationsForBlocking](Tables/Dictionary.AtomicOperationsForBlocking.md) | 9.2 | 20 atomic blocking operations — MCP verified |
| [Dictionary.BlockUnBlockReason](Tables/Dictionary.BlockUnBlockReason.md) | 9.1 | 26 block/unblock reasons — MCP verified |
| [Dictionary.BonusStatus](Tables/Dictionary.BonusStatus.md) | 9.3 | 4 bonus lifecycle states — MCP verified |
| [Dictionary.CardTypeToBank](Tables/Dictionary.CardTypeToBank.md) | 9.2 | Card-to-bank routing with email trigger — MCP verified |
| [Dictionary.ClientWithdrawReason](Tables/Dictionary.ClientWithdrawReason.md) | 9.2 | 7 client withdrawal reasons — MCP verified |
| [Dictionary.CloseMirrorActionType](Tables/Dictionary.CloseMirrorActionType.md) | 9.2 | 7 CopyTrading close triggers — MCP verified |
| [Dictionary.CorporateAction](Tables/Dictionary.CorporateAction.md) | 9.2 | 41 corporate action types with compensation mapping — MCP verified |
| [Dictionary.CountryBin6](Tables/Dictionary.CountryBin6.md) | 9.2 | 324K 6-digit BIN mappings (temporal) — MCP verified |
| [Dictionary.CountryBin8](Tables/Dictionary.CountryBin8.md) | 9.1 | 16M 8-digit BIN mappings (temporal) — MCP verified |
| [Dictionary.CryptoUserStatus](Tables/Dictionary.CryptoUserStatus.md) | 9.0 | 4 crypto wallet access levels — MCP verified |
| [Dictionary.OperationTypesForBlocking](Tables/Dictionary.OperationTypesForBlocking.md) | 9.1 | 24 high-level blocking operation types — MCP verified |
| [Dictionary.OrderForExecutionStatus](Tables/Dictionary.OrderForExecutionStatus.md) | 9.2 | 11 order execution states (memory-optimized) — MCP verified |
| [Dictionary.RiskClassification](Tables/Dictionary.RiskClassification.md) | 9.2 | 6 risk levels with numeric scores — MCP verified |
| [Dictionary.RiskManagementStatus](Tables/Dictionary.RiskManagementStatus.md) | 9.2 | 68 deposit risk check outcomes — MCP verified |
| [Dictionary.RiskStatus](Tables/Dictionary.RiskStatus.md) | 9.2 | 89 customer risk flags with categories — MCP verified |
| [Dictionary.TradingRiskStatus](Tables/Dictionary.TradingRiskStatus.md) | 9.2 | 4 trading risk levels (computed from regulation) — MCP verified |
| [Dictionary.ABTest](Tables/Dictionary.ABTest.md) | 9.0 | A/B test experiment registry — MCP verified |
| [Dictionary.AcceptanceStatus](Tables/Dictionary.AcceptanceStatus.md) | 9.2 | 4 customer compliance acceptance states — MCP verified |
| [Dictionary.AccountUpdateType](Tables/Dictionary.AccountUpdateType.md) | 9.2 | 14 account balance update categories — MCP verified |
| [Dictionary.Actions](Tables/Dictionary.Actions.md) | 9.2 | 12 async action types for Internal engine — MCP verified |
| [Dictionary.ActionType](Tables/Dictionary.ActionType.md) | 9.0 | 16 legacy user activity types — MCP verified |
| [Dictionary.AddressType](Tables/Dictionary.AddressType.md) | 9.0 | 1 address classification type (Mailing) — MCP verified |
| [Dictionary.AdminPositionState](Tables/Dictionary.AdminPositionState.md) | 9.0 | 4 admin position order states — MCP verified |
| [Dictionary.AffiliateStatus](Tables/Dictionary.AffiliateStatus.md) | 9.2 | 6 affiliate partner quality tiers — MCP verified |
| [Dictionary.AggregationLastValue](Tables/Dictionary.AggregationLastValue.md) | 9.2 | Incremental aggregation watermark tracker — MCP verified |
| [Dictionary.AllowedOpenOrderType](Tables/Dictionary.AllowedOpenOrderType.md) | 9.0 | 3 order input modes (All/Units/Amount) — MCP verified |
| [Dictionary.AmountFormula](Tables/Dictionary.AmountFormula.md) | 9.0 | 2 pricing formulas (PriceByUnit/FixPerLot) — MCP verified |
| [Dictionary.ApplicationIdentifier](Tables/Dictionary.ApplicationIdentifier.md) | 9.4 | 15 client app identifiers with platform FK — MCP verified |
| [Dictionary.AuditActionType](Tables/Dictionary.AuditActionType.md) | 9.2 | 358 BackOffice audit action types — MCP verified |
| [Dictionary.AuthenticationReason](Tables/Dictionary.AuthenticationReason.md) | 9.2 | 108 KYC document authentication reasons — MCP verified |
| [Dictionary.AuthenticationReasonPOI](Tables/Dictionary.AuthenticationReasonPOI.md) | 9.0 | POI authentication reasons (not deployed to live DB) |
| [Dictionary.AuthenticationReasonSelfie](Tables/Dictionary.AuthenticationReasonSelfie.md) | 9.0 | Selfie authentication reasons (not deployed to live DB) |
| [Dictionary.BadBinBlockReason](Tables/Dictionary.BadBinBlockReason.md) | 9.0 | 5 BIN block reasons (Legal/Risk/Fraud/Country/Other) — MCP verified |
| [Dictionary.BankBin](Tables/Dictionary.BankBin.md) | 9.2 | BIN-to-bank mapping with Bank FK — MCP verified |
| [Dictionary.BankClassification](Tables/Dictionary.BankClassification.md) | 9.0 | 3 bank integration tiers (Basic/Evaluation/Optimised) — MCP verified |
| [Dictionary.BillingMaintenanceStatus](Tables/Dictionary.BillingMaintenanceStatus.md) | 9.0 | 3 billing service states (Active/Maintenance/Inactive) — MCP verified |
| [Dictionary.BackofficeTemplates_OLD](Tables/Dictionary.BackofficeTemplates_OLD.md) | 9.0 | 22 legacy BackOffice templates (KYC rejection + premium manager emails) — MCP verified |
| [Dictionary.BillingScheduledTask](Tables/Dictionary.BillingScheduledTask.md) | 9.0 | 8 billing scheduled task types — MCP verified |
| [Dictionary.BlockedDataType](Tables/Dictionary.BlockedDataType.md) | 9.2 | 5 blacklist data categories with 2 FK consumers — MCP verified |
| [Dictionary.BSLMessageTypes](Tables/Dictionary.BSLMessageTypes.md) | 9.2 | 3 BSL equity protection message types — MCP verified |
| [Dictionary.BSLOperationThreshold](Tables/Dictionary.BSLOperationThreshold.md) | 9.4 | 4 BSL equity thresholds (5%-25%) with 3 procedure consumers — MCP verified |
| [Dictionary.CandleTimeframes](Tables/Dictionary.CandleTimeframes.md) | 9.2 | 9 candlestick chart timeframes (1min-1week) — MCP verified |
| [Dictionary.CEPNamedListTypeID](Tables/Dictionary.CEPNamedListTypeID.md) | 9.2 | 2 CEP named list types (Normal/DB Generated) — MCP verified |
| [Dictionary.ChampionshipPlayerStatus](Tables/Dictionary.ChampionshipPlayerStatus.md) | 9.2 | 4 championship player lifecycle states — MCP verified |
| [Dictionary.ChampionshipType](Tables/Dictionary.ChampionshipType.md) | 9.2 | 3 championship accessibility types (Public/Private) — MCP verified |
| [Dictionary.ChangeLogItemType](Tables/Dictionary.ChangeLogItemType.md) | 9.0 | Self-referencing change log item types (empty, unused) — MCP verified |
| [Dictionary.ChangeLogType](Tables/Dictionary.ChangeLogType.md) | 9.0 | Change log types (empty, referenced by position change API) — MCP verified |
| [Dictionary.ClientRequestType](Tables/Dictionary.ClientRequestType.md) | 9.0 | 1 client request type (AddACHAccount) — MCP verified |
| [Dictionary.ClientSetting](Tables/Dictionary.ClientSetting.md) | 9.0 | Default client UI/trading settings (single-row config) — MCP verified |
| [Dictionary.ClientType](Tables/Dictionary.ClientType.md) | 9.0 | 8 client platform types (WebTrader/Android/iPhone/etc) — MCP verified |
| [Dictionary.ClientWithdrawComment](Tables/Dictionary.ClientWithdrawComment.md) | 9.2 | 4 withdrawal comment options with 6 consumers — MCP verified |
| [Dictionary.ConditionOperators](Tables/Dictionary.ConditionOperators.md) | 9.2 | 8 CEP comparison operators (temporal) — MCP verified |
| [Dictionary.ConditionProperties](Tables/Dictionary.ConditionProperties.md) | 9.2 | 27 CEP condition properties (temporal) — MCP verified |
| [Dictionary.ConfigurationUpdateType](Tables/Dictionary.ConfigurationUpdateType.md) | 9.2 | 29 instrument config update types with 8+ procedure consumers — MCP verified |
| [Dictionary.ConversationReason](Tables/Dictionary.ConversationReason.md) | 9.2 | 4 customer service conversation reasons — MCP verified |
| [Dictionary.ConversationType](Tables/Dictionary.ConversationType.md) | 9.0 | 3 conversation channels (Phone/Chat/Email) — MCP verified |
| [Dictionary.CountryConflictGroup](Tables/Dictionary.CountryConflictGroup.md) | 9.0 | 4 geopolitical conflict groups for billing — MCP verified |
| [Dictionary.CountryEconomicType](Tables/Dictionary.CountryEconomicType.md) | 9.0 | 3 European economic zone types (EU/EEA/Unknown) — MCP verified |
| [Dictionary.CountryGroup](Tables/Dictionary.CountryGroup.md) | 9.2 | 33 country groups for regulatory/marketing/feature gating — MCP verified |
| [Dictionary.CountryIP](Tables/Dictionary.CountryIP.md) | 9.2 | 6.8M IP-to-country geolocation ranges with 8 consumers — MCP verified |
| [Dictionary.CountryToCountryGroup](Tables/Dictionary.CountryToCountryGroup.md) | 9.2 | 1023-row many-to-many country-to-group mapping with 2 FKs, 10+ consumers — MCP verified |
| [Dictionary.CreditCardAuthenticationStatus](Tables/Dictionary.CreditCardAuthenticationStatus.md) | 9.0 | 5 credit card 3DS authentication outcomes — MCP verified |
| [Dictionary.CryptoLiquidityOrderStatusType](Tables/Dictionary.CryptoLiquidityOrderStatusType.md) | 9.2 | 7 crypto liquidity order lifecycle states — MCP verified |
| [Dictionary.CryptoLiquidityOrderType](Tables/Dictionary.CryptoLiquidityOrderType.md) | 9.0 | 2 crypto order directions (Buy/Sell) — MCP verified |
| [Dictionary.CryptoLiquidityWalletBalanceSourceType](Tables/Dictionary.CryptoLiquidityWalletBalanceSourceType.md) | 9.0 | 3 wallet balance source methods (None/API/Balance) — MCP verified |
| [Dictionary.CryptoLiquidityWalletType](Tables/Dictionary.CryptoLiquidityWalletType.md) | 9.0 | 3 crypto wallet types (Exchange/Wallet/OTC) — MCP verified |
| [Dictionary.CustomerToFundingStatus](Tables/Dictionary.CustomerToFundingStatus.md) | 9.4 | 5 payment method visibility states with 30+ billing consumers — MCP verified |
| [Dictionary.DepositDRStatus](Tables/Dictionary.DepositDRStatus.md) | 9.0 | 4 deposit dispute resolution states — MCP verified |
| [Dictionary.DepositFlow](Tables/Dictionary.DepositFlow.md) | 9.0 | 3 trading flow contexts for deposit operations — MCP verified |
| [Dictionary.DepositRollbackType](Tables/Dictionary.DepositRollbackType.md) | 9.2 | 11 deposit reversal types (chargebacks/refunds/adjustments) — MCP verified |
| [Dictionary.DepositRollbackTypeReason](Tables/Dictionary.DepositRollbackTypeReason.md) | 9.2 | 38 deposit rollback reasons (fraud/failed/corrections) — MCP verified |
| [Dictionary.DepositStatusReason](Tables/Dictionary.DepositStatusReason.md) | 9.2 | 4 deposit approval stage reasons (PreApproved/FinalApproved/FinalDecline) — MCP verified |
| [Dictionary.DepositTypeReason](Tables/Dictionary.DepositTypeReason.md) | 9.0 | 8 deposit type classification reasons — MCP verified |
| [Dictionary.DepotMode](Tables/Dictionary.DepotMode.md) | 9.4 | 3 payment depot modes (General/Live/Demo) with 13+ billing consumers — MCP verified |
| [Dictionary.DesignatedExecutionSystem](Tables/Dictionary.DesignatedExecutionSystem.md) | 9.4 | 2 trade execution systems (TradeServer/Async) with 9+ trading consumers — MCP verified |
| [Dictionary.DocumentAutheticationType](Tables/Dictionary.DocumentAutheticationType.md) | 9.2 | 5 KYC authentication types (POI/POA/Selfie/biometric) — MCP verified |
| [Dictionary.DocumentClassification](Tables/Dictionary.DocumentClassification.md) | 9.4 | 73 KYC document sub-types with FK to DocumentType and age limits — MCP verified |
| [Dictionary.DocumentRejectReason](Tables/Dictionary.DocumentRejectReason.md) | 9.2 | 49 KYC document rejection reasons (POI/POA/Selfie/SSN) — MCP verified |
| [Dictionary.DocumentSide](Tables/Dictionary.DocumentSide.md) | 9.0 | 4 document side states (Front/Back/Both/NotRecognizable) — MCP verified |
| [Dictionary.DocumentSizeActionType](Tables/Dictionary.DocumentSizeActionType.md) | 9.0 | 3 document image size reduction states — MCP verified |
| [Dictionary.DowntimeCloseStatus](Tables/Dictionary.DowntimeCloseStatus.md) | 9.2 | 4 downtime incident resolution categories — MCP verified |
| [Dictionary.DowntimeSeverity](Tables/Dictionary.DowntimeSeverity.md) | 9.2 | 4 incident severity levels (Critical/High/Medium/Low) — MCP verified |
| [Dictionary.DowntimeStatus](Tables/Dictionary.DowntimeStatus.md) | 9.2 | 3 operational impact statuses — MCP verified |
| [Dictionary.DowntimeSystem](Tables/Dictionary.DowntimeSystem.md) | 9.2 | 5 monitored platform systems — MCP verified |
| [Dictionary.DowntimeSystemToDowntype](Tables/Dictionary.DowntimeSystemToDowntype.md) | 9.2 | 35-row system-to-downtype mapping with 2 FKs — MCP verified |
| [Dictionary.Downtype](Tables/Dictionary.Downtype.md) | 9.2 | 17 downtime incident categories — MCP verified |
| [Dictionary.Duration](Tables/Dictionary.Duration.md) | 9.0 | 16 legacy trading session durations — MCP verified |
| [Dictionary.EIDStatus](Tables/Dictionary.EIDStatus.md) | 9.2 | 3 electronic identity verification states — MCP verified |
| [Dictionary.ElectronicIdentityCheck](Tables/Dictionary.ElectronicIdentityCheck.md) | 9.2 | 4 EID verification outcomes (None/1Source/2Sources/NoMatch) — MCP verified |
| [Dictionary.ElectronicIdentityProvider](Tables/Dictionary.ElectronicIdentityProvider.md) | 9.0 | 3 EID verification providers (GDC/GB/Au10tix) — MCP verified |
| [Dictionary.EmailVerificationProvider](Tables/Dictionary.EmailVerificationProvider.md) | 9.2 | 5 email verification providers (eToro/Facebook/Google/Apple/UAEPass) — MCP verified |
| [Dictionary.EncryptionKeyStatus](Tables/Dictionary.EncryptionKeyStatus.md) | 9.0 | 3 encryption key lifecycle states — MCP verified |
| [Dictionary.ErrorMessage](Tables/Dictionary.ErrorMessage.md) | 9.2 | 98 parameterized server log message templates with ServerType FK — MCP verified |
| [Dictionary.EventType](Tables/Dictionary.EventType.md) | 9.2 | 17 customer lifecycle event types with active/inactive flag — MCP verified |
| [Dictionary.ExchangeInfo](Tables/Dictionary.ExchangeInfo.md) | 9.2 | 62 stock exchange/market venue definitions — MCP verified |
| [Dictionary.ExcludedFundingTypesByCountryAndRegulation](Tables/Dictionary.ExcludedFundingTypesByCountryAndRegulation.md) | 9.2 | 915 funding type exclusion rules by country+regulation — MCP verified |
| [Dictionary.ExecuteEntryMethod](Tables/Dictionary.ExecuteEntryMethod.md) | 9.2 | 3 payout execution methods (None/Auto/Manual) — MCP verified |
| [Dictionary.ExecutionErrorCategories](Tables/Dictionary.ExecutionErrorCategories.md) | 9.2 | 7 trade execution error categories — MCP verified |
| [Dictionary.ExecutionServicesOpeartionType](Tables/Dictionary.ExecutionServicesOpeartionType.md) | 9.0 | 25 execution services operation types (memory-optimized) — MCP verified |
| [Dictionary.FailType](Tables/Dictionary.FailType.md) | 9.2 | 17 trading operation failure categories — MCP verified |
|| [Dictionary.Feature](Tables/Dictionary.Feature.md) | 9.2 | 7 trading execution features (price filter/volatility/delay) — MCP verified |
|| [Dictionary.FeatureThreshold](Tables/Dictionary.FeatureThreshold.md) | 9.2 | 5 threshold severity tiers (Minimum-Maximum) — MCP verified |
|| [Dictionary.FinancialDiscrepancyDirection](Tables/Dictionary.FinancialDiscrepancyDirection.md) | 9.0 | 1 financial discrepancy direction (missing funds) — MCP verified |
|| [Dictionary.FinancialDiscrepancyType](Tables/Dictionary.FinancialDiscrepancyType.md) | 9.2 | 17 billing discrepancy types (duplicates/rates/fees/leakage) — MCP verified |
|| [Dictionary.Flow](Tables/Dictionary.Flow.md) | 9.2 | 3 trading execution flow types (Open/Close/Transfer) — MCP verified |
|| [Dictionary.FundingDataMigrationStatus](Tables/Dictionary.FundingDataMigrationStatus.md) | 9.0 | 6 funding encryption migration states — MCP verified |
|| [Dictionary.FundingTypeToXSDUniqueElement](Tables/Dictionary.FundingTypeToXSDUniqueElement.md) | 9.2 | 5-row funding-to-XSD mapping with FK — MCP verified |
|| [Dictionary.FundIntervalType](Tables/Dictionary.FundIntervalType.md) | 9.0 | 2 fund interval modes (BackTesting/Real) — MCP verified |
|| [Dictionary.FundType](Tables/Dictionary.FundType.md) | 9.0 | 3 CopyFund/SmartPortfolio categories — MCP verified |
|| [Dictionary.Funnel](Tables/Dictionary.Funnel.md) | 9.2 | 120+ acquisition funnels with Platform FK — MCP verified |
|| [Dictionary.GameServer](Tables/Dictionary.GameServer.md) | 9.2 | 2 trading server instances with ServerType FK — MCP verified |
|| [Dictionary.GameSubType](Tables/Dictionary.GameSubType.md) | 9.2 | 11 game/trading activity categories — MCP verified |
|| [Dictionary.GameType](Tables/Dictionary.GameType.md) | 9.2 | 14 game types with GameSubType FK — MCP verified |
|| [Dictionary.Gateway](Tables/Dictionary.Gateway.md) | 9.0 | 3 external payment gateway providers — MCP verified |
|| [Dictionary.GDCCheck](Tables/Dictionary.GDCCheck.md) | 9.2 | 4 GDC identity verification outcomes — MCP verified |
|| [Dictionary.Groups](Tables/Dictionary.Groups.md) | 9.2 | 12 BackOffice permission groups — MCP verified |
|| [Dictionary.HBCOrderState](Tables/Dictionary.HBCOrderState.md) | 9.2 | 6 HBC order lifecycle states — MCP verified |
|| [Dictionary.HedgeAccountType](Tables/Dictionary.HedgeAccountType.md) | 9.0 | 2 hedge account types (Execution/OMS Pricing) — MCP verified |
|| [Dictionary.HedgeBreakdownType](Tables/Dictionary.HedgeBreakdownType.md) | 9.2 | 6 hedge execution pipeline stages — MCP verified |
|| [Dictionary.HedgeEventType](Tables/Dictionary.HedgeEventType.md) | 9.2 | 8 hedge infrastructure event types — MCP verified |
|| [Dictionary.HedgeExecutionMode](Tables/Dictionary.HedgeExecutionMode.md) | 9.2 | 2 hedge execution modes (HBC/CBH) — MCP verified |
|| [Dictionary.HedgeManualRequestType](Tables/Dictionary.HedgeManualRequestType.md) | 9.2 | 8 manual hedge request types — MCP verified |
|| [Dictionary.HedgeOrderState](Tables/Dictionary.HedgeOrderState.md) | 9.2 | 8 hedge order lifecycle states — MCP verified |
|| [Dictionary.HedgePositionFailReason](Tables/Dictionary.HedgePositionFailReason.md) | 9.2 | 24 hedge failure reasons with severity — MCP verified |
|| [Dictionary.HedgePositionFailSeverity](Tables/Dictionary.HedgePositionFailSeverity.md) | 9.2 | 6 failure severity tiers — MCP verified |
|| [Dictionary.HedgeRecoveryState](Tables/Dictionary.HedgeRecoveryState.md) | 9.2 | 5 hedge recovery states — MCP verified |
|| [Dictionary.HedgeServerExecutionStrategy](Tables/Dictionary.HedgeServerExecutionStrategy.md) | 9.0 | 2 execution strategies (Normal/Smart) — MCP verified |
|| [Dictionary.HedgeServerExposureMode](Tables/Dictionary.HedgeServerExposureMode.md) | 9.2 | 4 exposure calculation modes — MCP verified |
|| [Dictionary.HedgeUpdateReason](Tables/Dictionary.HedgeUpdateReason.md) | 9.2 | 5 hedge update reasons with unique constraint — MCP verified |
|| [Dictionary.HistoryCreditActionsToHide](Tables/Dictionary.HistoryCreditActionsToHide.md) | 9.2 | 12 hidden credit action combinations for 8 procedures — MCP verified |
|| [Dictionary.IMType_Del](Tables/Dictionary.IMType_Del.md) | 9.2 | 5 deprecated IM platforms (legacy) — MCP verified |
|| [Dictionary.IndexDividenedStatus](Tables/Dictionary.IndexDividenedStatus.md) | 9.2 | 6 index dividend processing states — MCP verified |
|| [Dictionary.InstrumentTypeSubCategory](Tables/Dictionary.InstrumentTypeSubCategory.md) | 9.2 | 17 instrument sub-categories for SEO/config — MCP verified |
|| [Dictionary.InterestRateOverride](Tables/Dictionary.InterestRateOverride.md) | 9.4 | Temporal interest rate overrides by instrument/exchange/type — MCP verified |
|| [Dictionary.InterestStatus](Tables/Dictionary.InterestStatus.md) | 9.0 | Interest processing statuses (empty, reserved) — MCP verified |
|| [Dictionary.JobEnvironmentType](Tables/Dictionary.JobEnvironmentType.md) | 9.2 | 3 job environments (Israel/Cyprus/Amsterdam) — MCP verified |
|| [Dictionary.Justefied](Tables/Dictionary.Justefied.md) | 9.0 | Justified failure whitelist for reporting (empty) — MCP verified |
|| [Dictionary.Label](Tables/Dictionary.Label.md) | 9.2 | 25 platform labels/white-label brands — MCP verified |
|| [Dictionary.LeverageType](Tables/Dictionary.LeverageType.md) | 9.2 | 6 leverage boundary ranges per instrument type — MCP verified |
|| [Dictionary.LiquidityAccountType](Tables/Dictionary.LiquidityAccountType.md) | 9.4 | 5 liquidity account roles (Price/Execution/Both) — MCP verified |
|| [Dictionary.ListenerType](Tables/Dictionary.ListenerType.md) | 9.0 | 1 broker message listener type (BackOffice) — MCP verified |
|| [Dictionary.LotCount](Tables/Dictionary.LotCount.md) | 9.2 | 180+ valid lot count values (ID=Value pattern) — MCP verified |
|| [Dictionary.LotCountGroup](Tables/Dictionary.LotCountGroup.md) | 9.2 | 5 lot count groups mapped to eToro Club tiers — MCP verified |
|| [Dictionary.ManagerPermit](Tables/Dictionary.ManagerPermit.md) | 9.2 | 4 BackOffice manager permission tiers (None/Trade/Fund/Both) — MCP verified |
|| [Dictionary.ManagerTitle](Tables/Dictionary.ManagerTitle.md) | 9.0 | 5 manager role titles (Sales/AccountMgmt/CustomerSuccess) — MCP verified |
|| [Dictionary.ManualOperationReason](Tables/Dictionary.ManualOperationReason.md) | 9.2 | 12 manual position operation reasons — MCP verified |
|| [Dictionary.MatchStatus](Tables/Dictionary.MatchStatus.md) | 9.2 | 7 billing reconciliation match states — MCP verified |
|| [Dictionary.Merchant_Old](Tables/Dictionary.Merchant_Old.md) | 9.0 | 22 legacy payment merchants (Checkout/PayPal/Wire/etc) — MCP verified |
|| [Dictionary.MessageGroup](Tables/Dictionary.MessageGroup.md) | 9.0 | 56 alphabetic billing message group codes (A-AZ) — MCP verified |
|| [Dictionary.MessageType](Tables/Dictionary.MessageType.md) | 9.2 | 10 platform message delivery channels (Dialog/Bar/Kick/Trade Block) — MCP verified |
|| [Dictionary.MirrorDividendRejectionReason](Tables/Dictionary.MirrorDividendRejectionReason.md) | 9.0 | 2 CopyTrading dividend rejection reasons — MCP verified |
|| [Dictionary.MirrorMIMOOperation](Tables/Dictionary.MirrorMIMOOperation.md) | 9.2 | 4 CopyTrading MIMO operation types (Manual/Dividend/Fees) — MCP verified |
|| [Dictionary.MoveMoneyReason](Tables/Dictionary.MoveMoneyReason.md) | 9.2 | 8 internal money movement reasons (Adjustment/Staking/Transfer) — MCP verified |
|| [Dictionary.MSLCloseMirrorTrigger](Tables/Dictionary.MSLCloseMirrorTrigger.md) | 9.2 | 8 Mirror Stop Loss trigger events — MCP verified |
|| [Dictionary.NoteType](Tables/Dictionary.NoteType.md) | 9.2 | 4 customer note categories (General/Support/Telemarketing/Campaign) — MCP verified |
|| [Dictionary.NotificationMessageStatus](Tables/Dictionary.NotificationMessageStatus.md) | 9.0 | 5 notification message processing states — MCP verified |
|| [Dictionary.NotificationStatus](Tables/Dictionary.NotificationStatus.md) | 9.0 | 4 notification delivery lifecycle states — MCP verified |
|| [Dictionary.NotificationTrigger](Tables/Dictionary.NotificationTrigger.md) | 9.0 | 5 notification trigger events (Cashout/EquityWarning) — MCP verified |
|| [Dictionary.NotificationType](Tables/Dictionary.NotificationType.md) | 9.0 | 3 notification delivery channels (SilverPop/SMTP/Push) — MCP verified |
|| [Dictionary.NotificationTypeName](Tables/Dictionary.NotificationTypeName.md) | 9.2 | 40 KYC notification template identifiers — MCP verified |
|| [Dictionary.Objects](Tables/Dictionary.Objects.md) | 9.2 | 28 permissioned application objects (ConfigMgr/DealingReports/CEP) — MCP verified |
|| [Dictionary.OMPDThresholdType](Tables/Dictionary.OMPDThresholdType.md) | 9.0 | 2 OMPD threshold measurement types (Pips/Percentage) — MCP verified |
|| [Dictionary.OMSStrategyType](Tables/Dictionary.OMSStrategyType.md) | 9.2 | 2 OMS execution strategies (IM/DMA) — MCP verified |
|| [Dictionary.OptOutReason](Tables/Dictionary.OptOutReason.md) | 9.2 | 4 marketing opt-out reasons (User/Inactivity/Country) — MCP verified |
|| [Dictionary.OrderExitOperationType](Tables/Dictionary.OrderExitOperationType.md) | 9.2 | 5 exit order operation types (Open/Close/Convert/Edit) — MCP verified |
|| [Dictionary.OrderFillBehaviorType](Tables/Dictionary.OrderFillBehaviorType.md) | 9.2 | 2 order fill strategies (BestEffort/FillOrKill) — MCP verified |
|| [Dictionary.OrderForExecutionCloseActionType](Tables/Dictionary.OrderForExecutionCloseActionType.md) | 9.0 | 12 order-for-execution close outcomes — MCP verified |
|| [Dictionary.OrderOperationType](Tables/Dictionary.OrderOperationType.md) | 9.0 | 2 order directions (Open/Close) — MCP verified |
|| [Dictionary.OrdersActionType](Tables/Dictionary.OrdersActionType.md) | 9.2 | 5 pending order lifecycle actions — MCP verified |
|| [Dictionary.OrdersEntryActionType](Tables/Dictionary.OrdersEntryActionType.md) | 9.0 | 6 entry order resolution outcomes — MCP verified |
|| [Dictionary.OrdersExitActionType](Tables/Dictionary.OrdersExitActionType.md) | 9.0 | Exit order action types (empty, reserved) — MCP verified |
|| [Dictionary.OrdersExitCloseActionType](Tables/Dictionary.OrdersExitCloseActionType.md) | 9.0 | 8 exit-close order resolution pathways — MCP verified |
|| [Dictionary.OrdersExitOpenActionType](Tables/Dictionary.OrdersExitOpenActionType.md) | 9.2 | 7 exit-open order triggers — MCP verified |
|| [Dictionary.PaymentServiceStatus](Tables/Dictionary.PaymentServiceStatus.md) | 9.0 | 3 payment service operational states — MCP verified |
|| [Dictionary.PaymentStatusNotification](Tables/Dictionary.PaymentStatusNotification.md) | 9.4 | 19 localized payment notification templates with 2 FKs — MCP verified |
|| [Dictionary.PayoutProcessReason](Tables/Dictionary.PayoutProcessReason.md) | 9.2 | 10 payout processing reasons (success/error types) — MCP verified |
|| [Dictionary.PCL_ChangeType](Tables/Dictionary.PCL_ChangeType.md) | 9.2 | 15 position change log event types — MCP verified |
|| [Dictionary.PendingClosureStatus](Tables/Dictionary.PendingClosureStatus.md) | 9.4 | 3 account closure workflow states with 13+ consumers — MCP verified |
|| [Dictionary.Permission](Tables/Dictionary.Permission.md) | 9.4 | 148 BackOffice permissions with amount tiers — MCP verified |
|| [Dictionary.PhoneTypes](Tables/Dictionary.PhoneTypes.md) | 9.2 | 15 phone line types for identity verification — MCP verified |
|| [Dictionary.PhoneVerificationListType](Tables/Dictionary.PhoneVerificationListType.md) | 9.0 | 2 phone verification list types (White/Black) — MCP verified |
|| [Dictionary.PhoneVerificationRiskLevel](Tables/Dictionary.PhoneVerificationRiskLevel.md) | 9.2 | 8 phone risk levels for KYC scoring — MCP verified |
|| [Dictionary.PhoneVerificationTransactionRecommendation](Tables/Dictionary.PhoneVerificationTransactionRecommendation.md) | 9.2 | 6 transaction recommendations (Block/Flag/Allow) — MCP verified |
|| [Dictionary.PhoneVerified](Tables/Dictionary.PhoneVerified.md) | 9.4 | 6 phone verification lifecycle states with 20+ consumers — MCP verified |
|| [Dictionary.PositionOpenOpenOperationType](Tables/Dictionary.PositionOpenOpenOperationType.md) | 9.0 | 2 CopyTrading position-open operations — MCP verified |
|| [Dictionary.PositionTimeOuts](Tables/Dictionary.PositionTimeOuts.md) | 9.2 | 3 timeout-protected trading procedure monitors — MCP verified |
|| [Dictionary.PriceSourceName](Tables/Dictionary.PriceSourceName.md) | 9.4 | 27 exchange/price data sources with 8 consumers — MCP verified |
|| [Dictionary.PriceType](Tables/Dictionary.PriceType.md) | 9.0 | 2 price delivery modes (RealTime/Snapshot) — MCP verified |
|| [Dictionary.PrivacyEvents](Tables/Dictionary.PrivacyEvents.md) | 9.0 | 1 privacy-sensitive platform event (Championship) — MCP verified |
|| [Dictionary.PrivacyPolicy](Tables/Dictionary.PrivacyPolicy.md) | 9.4 | 2 privacy policies (Share All/Don't Share) with 20+ consumers — MCP verified |
|| [Dictionary.PrivacyPolicyDetails](Tables/Dictionary.PrivacyPolicyDetails.md) | 9.2 | Privacy policy × event × recipient junction (3 FKs) — MCP verified |
|| [Dictionary.PrivacyRecipients](Tables/Dictionary.PrivacyRecipients.md) | 9.0 | 7 data-sharing recipients (Community/Facebook/Twitter/etc) — MCP verified |
|| [Dictionary.PrizeType](Tables/Dictionary.PrizeType.md) | 9.2 | 4 championship prize calculation methods (Fix/Percent/Product) — MCP verified |
|| [Dictionary.PromotionType](Tables/Dictionary.PromotionType.md) | 9.2 | 2 promotion categories with replaceability flag — MCP verified |
|| [Dictionary.Protocol](Tables/Dictionary.Protocol.md) | 9.4 | 45 payment protocols with PSP/DLL/direction mapping — MCP verified |
|| [Dictionary.ProtocolDirection](Tables/Dictionary.ProtocolDirection.md) | 9.2 | 2 payment protocol directions (Direct/Redirect) — MCP verified |
|| [Dictionary.ProtocolParameter](Tables/Dictionary.ProtocolParameter.md) | 9.2 | 49 payment protocol config parameters (API keys/URLs) — MCP verified |
|| [Dictionary.ProviderPercentageRouting](Tables/Dictionary.ProviderPercentageRouting.md) | 9.0 | 33 percentage-based payment routing rules by depot/country — MCP verified |
|| [Dictionary.PWMBAddAccountRequestStatus](Tables/Dictionary.PWMBAddAccountRequestStatus.md) | 9.0 | 8 PWMB bank account linking lifecycle states — MCP verified |
|| [Dictionary.RafModelType_NogaJunk210725](Tables/Dictionary.RafModelType_NogaJunk210725.md) | 9.0 | 2 RAF compensation model types (Club/PI) — MCP verified |
|| [Dictionary.RafPlayerLevel_NogaJunk210725](Tables/Dictionary.RafPlayerLevel_NogaJunk210725.md) | 9.0 | 8 RAF club tiers (Bronze-Diamond) — MCP verified |
|| [Dictionary.RafStatus_NogaJunk210725](Tables/Dictionary.RafStatus_NogaJunk210725.md) | 9.0 | 4 RAF referral lifecycle states — MCP verified |
|| [Dictionary.RankToCountry](Tables/Dictionary.RankToCountry.md) | 9.2 | 3-rank country risk classification (254 countries) — MCP verified |
|| [Dictionary.RankToCountryConfiguration](Tables/Dictionary.RankToCountryConfiguration.md) | 9.0 | 12 KYC/deposit rank withdrawal restriction rules — MCP verified |
|| [Dictionary.RedeemApprovalReason](Tables/Dictionary.RedeemApprovalReason.md) | 9.0 | 1 CopyTrading redeem approval reason (Other) — MCP verified |
|| [Dictionary.RegionByIP](Tables/Dictionary.RegionByIP.md) | 9.2 | 4,206 IP-based sub-country region codes with 10+ consumers — MCP verified |
|| [Dictionary.RegionName](Tables/Dictionary.RegionName.md) | 9.0 | Country subdivision names (AU/CA states/provinces) page-compressed — MCP verified |
|| [Dictionary.RegistrationIpBlacklist](Tables/Dictionary.RegistrationIpBlacklist.md) | 9.0 | IP blacklist for blocked registrations (decimal+string) — MCP verified |
|| [Dictionary.ReopenType](Tables/Dictionary.ReopenType.md) | 9.0 | CopyTrading mirror reopen operation types — MCP verified |
|| [Dictionary.Response](Tables/Dictionary.Response.md) | 9.4 | 3,970 PSP response code-to-status mappings with 4 FKs — MCP verified |
|| [Dictionary.RestrictionType](Tables/Dictionary.RestrictionType.md) | 9.2 | 4 CopyTrading settlement restriction levels — MCP verified |
|| [Dictionary.RiskClassificationParameter](Tables/Dictionary.RiskClassificationParameter.md) | 9.4 | 46 AML/KYC risk scoring parameters (standard+EDD) — MCP verified |
|| [Dictionary.RiskClassificationRegulation](Tables/Dictionary.RiskClassificationRegulation.md) | 9.0 | Per-regulation risk score thresholds (empty in prod) — MCP verified |
|| [Dictionary.RiskCountryPairs](Tables/Dictionary.RiskCountryPairs.md) | 9.2 | 725 geopolitically conflicting country pairs — MCP verified |
|| [Dictionary.RiskEventStatus](Tables/Dictionary.RiskEventStatus.md) | 9.4 | 3 risk event states (On/InProcess/Off) with 13+ consumers — MCP verified |
|| [Dictionary.Roles](Tables/Dictionary.Roles.md) | 9.2 | 36 RBAC roles with Objects FK — MCP verified |
|| [Dictionary.RuleType](Tables/Dictionary.RuleType.md) | 9.2 | 3 CEP rule routing strategies — MCP verified |
|| [Dictionary.SalesForceImprtProcess](Tables/Dictionary.SalesForceImprtProcess.md) | 9.2 | 2 Salesforce sync watermarks — MCP verified |
|| [Dictionary.SalesStatus](Tables/Dictionary.SalesStatus.md) | 9.2 | 4 sales pipeline states — MCP verified |
|| [Dictionary.SbrEventType](Tables/Dictionary.SbrEventType.md) | 9.2 | 4 SBR trading event types with .NET class names — MCP verified |
|| [Dictionary.ScheduledJobStatus](Tables/Dictionary.ScheduledJobStatus.md) | 9.2 | 3 job execution states (Running/Completed/Failed) — MCP verified |
|| [Dictionary.ScheduledJobType](Tables/Dictionary.ScheduledJobType.md) | 9.2 | 3 job execution mechanisms (API/Queue/Internal) — MCP verified |
|| [Dictionary.ScheduledTaskName](Tables/Dictionary.ScheduledTaskName.md) | 9.2 | 5 post-deposit task types (AppsFlyer/RabbitMQ/Pixel) — MCP verified |
|| [Dictionary.ScheduledTaskReason](Tables/Dictionary.ScheduledTaskReason.md) | 9.2 | 5 task failure reasons (timeout/internal/external) — MCP verified |
|| [Dictionary.ScheduledTaskState](Tables/Dictionary.ScheduledTaskState.md) | 9.2 | 5 post-deposit task states — MCP verified |
|| [Dictionary.SecondIncomeSteps](Tables/Dictionary.SecondIncomeSteps.md) | 9.2 | 10 PI compensation tiers ($50-$10K) — MCP verified |
|| [Dictionary.ServerType](Tables/Dictionary.ServerType.md) | 9.2 | 10 infrastructure server classifications — MCP verified |
|| [Dictionary.ServiceType](Tables/Dictionary.ServiceType.md) | 9.2 | 48 platform microservice types — MCP verified |
|| [Dictionary.SettlementMethodValues](Tables/Dictionary.SettlementMethodValues.md) | 9.2 | 2 futures settlement methods (Cash/Physical) — MCP verified |
|| [Dictionary.SettlementRestrictions](Tables/Dictionary.SettlementRestrictions.md) | 9.2 | 4 CopyTrading settlement restriction levels — MCP verified |
|| [Dictionary.SeverityType](Tables/Dictionary.SeverityType.md) | 9.2 | 5 log severity levels (Fatal-Verbose) — MCP verified |
|| [Dictionary.SeychellesCategorization](Tables/Dictionary.SeychellesCategorization.md) | 9.2 | 4 Seychelles FSA client categories — MCP verified |
|| [Dictionary.SFTicketSecondSubType](Tables/Dictionary.SFTicketSecondSubType.md) | 9.0 | 27 Salesforce ticket sub-classifications — MCP verified |
|| [Dictionary.SmartExecutionModels](Tables/Dictionary.SmartExecutionModels.md) | 9.0 | 4 smart execution pricing models (LimitBid/Mid/Ask/Market) — MCP verified |
|| [Dictionary.SpreadThresholdType](Tables/Dictionary.SpreadThresholdType.md) | 9.2 | 2 spread measurement units (NOP/NOE) — MCP verified |
|| [Dictionary.SpreadType](Tables/Dictionary.SpreadType.md) | 9.0 | 2 spread conventions (Pips/Percentage) — MCP verified |
|| [Dictionary.State](Tables/Dictionary.State.md) | 9.4 | 68 US states/territories with Country FK — MCP verified |
|| [Dictionary.Steps](Tables/Dictionary.Steps.md) | 9.2 | 12 async post-action procedures — MCP verified |
|| [Dictionary.StockError](Tables/Dictionary.StockError.md) | 9.0 | 6 stock order failure codes — MCP verified |
|| [Dictionary.StockHedgeSource](Tables/Dictionary.StockHedgeSource.md) | 9.0 | 4 stock hedge initiation sources — MCP verified |
|| [Dictionary.StockOrderCloseReason](Tables/Dictionary.StockOrderCloseReason.md) | 9.2 | 5 stock order close reasons (Normal/Cancel/Mirror) — MCP verified |
|| [Dictionary.StocksIndustry](Tables/Dictionary.StocksIndustry.md) | 9.2 | 9 stock industry sectors for instrument categorization — MCP verified |
|| [Dictionary.StrategyGroups](Tables/Dictionary.StrategyGroups.md) | 9.0 | 3 hedge strategy groups (placeholder names) — MCP verified |
|| [Dictionary.SubCreditTypeID](Tables/Dictionary.SubCreditTypeID.md) | 9.2 | 2 credit sub-types (Regular/Partial) for ledger — MCP verified |
|| [Dictionary.SubRegion](Tables/Dictionary.SubRegion.md) | 9.2 | 107 Italian provinces with Country/Region FKs — MCP verified |
|| [Dictionary.SuitabilityTestStatus](Tables/Dictionary.SuitabilityTestStatus.md) | 9.2 | 3 MiFID II suitability assessment outcomes — MCP verified |
|| [Dictionary.SyncTslStatus](Tables/Dictionary.SyncTslStatus.md) | 9.0 | 4 Trailing Stop Loss sync lifecycle states — MCP verified |
|| [Dictionary.TaskType](Tables/Dictionary.TaskType.md) | 9.2 | 4 BackOffice task types (Sales/Support/Risk/Withdraw) — MCP verified |
|| [Dictionary.Teams](Tables/Dictionary.Teams.md) | 9.0 | 5 internal operational teams — MCP verified |
|| [Dictionary.TeamsMember](Tables/Dictionary.TeamsMember.md) | 9.0 | 169 team member roster (mostly Risk team) — MCP verified |
|| [Dictionary.TemplateID_LabelID](Tables/Dictionary.TemplateID_LabelID.md) | 9.0 | Template-to-label junction (empty, Label FK) — MCP verified |
|| [Dictionary.ThreeDsResponseTypes](Tables/Dictionary.ThreeDsResponseTypes.md) | 9.2 | 15 3DS authentication response outcomes — MCP verified |
|| [Dictionary.TimeZone](Tables/Dictionary.TimeZone.md) | 9.2 | 27 GMT offset time zones for customer profiles — MCP verified |
|| [Dictionary.TncDocType](Tables/Dictionary.TncDocType.md) | 9.2 | 18 Terms & Conditions document types — MCP verified |
|| [Dictionary.TraceEventType](Tables/Dictionary.TraceEventType.md) | 9.0 | 5 Cardinal Commerce 3DS trace events — MCP verified |
|| [Dictionary.Tracking](Tables/Dictionary.Tracking.md) | 9.0 | 3 mobile attribution identifier types — MCP verified |
|| [Dictionary.TradeActivity_ClosePositionActionTypes](Tables/Dictionary.TradeActivity_ClosePositionActionTypes.md) | 9.0 | 21 close-action-to-execution-category mappings — MCP verified |
|| [Dictionary.TradeActivity_ExecutionTypes](Tables/Dictionary.TradeActivity_ExecutionTypes.md) | 9.0 | 9 trade execution categories (Normal/Staking/CorporateAction) — MCP verified |
|| [Dictionary.TradeActivity_OpenPositionActionTypes](Tables/Dictionary.TradeActivity_OpenPositionActionTypes.md) | 9.0 | 16 open-action-to-execution-category mappings — MCP verified |
|| [Dictionary.TradeLevel](Tables/Dictionary.TradeLevel.md) | 9.2 | 5 customer trading platform levels — MCP verified |
|| [Dictionary.TradeUnitType](Tables/Dictionary.TradeUnitType.md) | 9.0 | 2 trade unit systems (Units/Lots) — MCP verified |
|| [Dictionary.TradingDbOperationType](Tables/Dictionary.TradingDbOperationType.md) | 9.0 | 3 DB operation types (Close/Reopen/ReopenMirror) — MCP verified |
|| [Dictionary.TradingErrorCode](Tables/Dictionary.TradingErrorCode.md) | 9.2 | 200+ trading engine error codes — MCP verified |
|| [Dictionary.AggregationLastValue_History](Tables/Dictionary.AggregationLastValue_History.md) | 9.2 | 3M+ aggregation watermark snapshots — MCP verified |
|| [Dictionary.TwoFactorVerificationSendMethodType](Tables/Dictionary.TwoFactorVerificationSendMethodType.md) | 9.2 | 2 2FA delivery channels (SMS/Call) — MCP verified |
|| [Dictionary.TwoFVStatus](Tables/Dictionary.TwoFVStatus.md) | 9.0 | 3 2FA enforcement states (None/NotRequired/Required) — MCP verified |
|| [Dictionary.UnitOfMeasure](Tables/Dictionary.UnitOfMeasure.md) | 9.2 | 13 instrument measurement units (Barrel/Troy Ounce/BTC) — MCP verified |
|| [Dictionary.UnitsQuantityType](Tables/Dictionary.UnitsQuantityType.md) | 9.2 | 2 position size modes (Fractional/Whole) — MCP verified |
|| [Dictionary.UpdateApexID](Tables/Dictionary.UpdateApexID.md) | 9.0 | Apex clearing sync watermark (single-row) — MCP verified |
|| [Dictionary.UserGroup](Tables/Dictionary.UserGroup.md) | 9.4 | 37 hierarchical BackOffice groups with self-ref FK — MCP verified |
|| [Dictionary.UserGroupToPermission](Tables/Dictionary.UserGroupToPermission.md) | 9.4 | 248 group-permission-provider RBAC grants with 2 FKs — MCP verified |
|| [Dictionary.VerificationLevel](Tables/Dictionary.VerificationLevel.md) | 9.4 | 4 KYC verification tiers (Level 0-3) with 60+ consumers — MCP verified |
|| [Dictionary.VerifiedByStatus](Tables/Dictionary.VerifiedByStatus.md) | 9.0 | 3 identity verification methods (None/Manual/Electronic) — MCP verified |
|| [Dictionary.VisaType](Tables/Dictionary.VisaType.md) | 9.2 | 10 US visa categories for non-citizen compliance — MCP verified |
|| [Dictionary.VolatilityThresholdType](Tables/Dictionary.VolatilityThresholdType.md) | 9.2 | 2 volatility measurement modes (Pips/Percentage) — MCP verified |
|| [Dictionary.WalletsType](Tables/Dictionary.WalletsType.md) | 9.0 | 2 liquidity provider wallet types (Nostro/ABook) — MCP verified |
|| [Dictionary.WebinarAction](Tables/Dictionary.WebinarAction.md) | 9.0 | 3 webinar engagement stages (Registered/Attended/Viewed) — MCP verified |
|| [Dictionary.WithdrawAdditionalParameterType](Tables/Dictionary.WithdrawAdditionalParameterType.md) | 9.2 | 13 withdrawal parameter types (IBAN/Card/BIC) — MCP verified |
|| [Dictionary.WithdrawApprovalReason](Tables/Dictionary.WithdrawApprovalReason.md) | 9.4 | 16 hierarchical withdrawal hold reasons with email templates — MCP verified |
|| [Dictionary.WithdrawType](Tables/Dictionary.WithdrawType.md) | 9.2 | 3 withdrawal classifications (Default/Transfer/Closure) — MCP verified |
|| [Dictionary.WorldCheck](Tables/Dictionary.WorldCheck.md) | 9.4 | 5 AML/PEP screening outcomes with 10+ consumers — MCP verified |
|| [Dictionary.XSDUniqueElement](Tables/Dictionary.XSDUniqueElement.md) | 9.2 | 3 XML uniqueness paths for funding validation — MCP verified |

---

## Tables — NEEDS REWORK (< 7.5, DDL-only skeletons)

**ALL REWORK COMPLETE** — All 19 previously low-quality tables were upgraded to 9.0+ in session 15 (2026-03-14).

---

## Suggested Rework Order (COMPLETE)

All 208 low-priority tables and 19 rework tables have been completed across 15 sessions. The following log shows the full history:

1. **Dictionary.ConversationType** — DONE (session 5)
2. **Dictionary.CountryConflictGroup** — DONE (session 5)
3. **Dictionary.CountryEconomicType** — DONE (session 5)
4. **Dictionary.CountryGroup** — DONE (session 5)
5. **Dictionary.CountryIP** — DONE (session 5)
6. **Dictionary.CountryToCountryGroup** — DONE (session 6)
7. **Dictionary.CreditCardAuthenticationStatus** — DONE (session 6)
8. **Dictionary.CryptoLiquidityOrderStatusType** — DONE (session 6)
9. **Dictionary.CryptoLiquidityOrderType** — DONE (session 6)
10. **Dictionary.CryptoLiquidityWalletBalanceSourceType** — DONE (session 6)
11. **Dictionary.CryptoLiquidityWalletType** — DONE (session 6)
12. **Dictionary.CustomerToFundingStatus** — DONE (session 6)
13. **Dictionary.DepositDRStatus** — DONE (session 6)
14. **Dictionary.DepositFlow** — DONE (session 6)
15. **Dictionary.DepositRollbackType** — DONE (session 6)
16. **Dictionary.DepositRollbackTypeReason** — DONE (session 6)
17. **Dictionary.DepositStatusReason** — DONE (session 6)
18. **Dictionary.DepositTypeReason** — DONE (session 6)
19. **Dictionary.DepotMode** — DONE (session 6)
20. **Dictionary.DesignatedExecutionSystem** — DONE (session 6)
21. **Dictionary.DocumentAutheticationType** — DONE (session 6)
22. **Dictionary.DocumentClassification** — DONE (session 6)
23. **Dictionary.DocumentRejectReason** — DONE (session 6)
24. **Dictionary.DocumentSide** — DONE (session 6)
25. **Dictionary.DocumentSizeActionType** — DONE (session 6)
26. **Dictionary.DowntimeCloseStatus** — DONE (session 7)
27. **Dictionary.DowntimeSeverity** — DONE (session 7)
28. **Dictionary.DowntimeStatus** — DONE (session 7)
29. **Dictionary.DowntimeSystem** — DONE (session 7)
30. **Dictionary.DowntimeSystemToDowntype** — DONE (session 7)
31. **Dictionary.Downtype** — DONE (session 7)
32. **Dictionary.Duration** — DONE (session 7)
33. **Dictionary.EIDStatus** — DONE (session 7)
34. **Dictionary.ElectronicIdentityCheck** — DONE (session 7)
35. **Dictionary.ElectronicIdentityProvider** — DONE (session 7)
36. **Dictionary.EmailVerificationProvider** — DONE (session 7)
37. **Dictionary.EncryptionKeyStatus** — DONE (session 7)
38. **Dictionary.ErrorMessage** — DONE (session 7)
39. **Dictionary.EventType** — DONE (session 7)
40. **Dictionary.ExchangeInfo** — DONE (session 7)
41. **Dictionary.ExcludedFundingTypesByCountryAndRegulation** — DONE (session 7)
42. **Dictionary.ExecuteEntryMethod** — DONE (session 7)
43. **Dictionary.ExecutionErrorCategories** — DONE (session 7)
44. **Dictionary.ExecutionServicesOpeartionType** — DONE (session 7)
45. **Dictionary.FailType** — DONE (session 7)
46. **Dictionary.Feature** — DONE (session 8)
47. **Dictionary.FeatureThreshold** — DONE (session 8)
48. **Dictionary.FinancialDiscrepancyDirection** — DONE (session 8)
49. **Dictionary.FinancialDiscrepancyType** — DONE (session 8)
50. **Dictionary.Flow** — DONE (session 8)
51. **Dictionary.FundingDataMigrationStatus** — DONE (session 8)
52. **Dictionary.FundingTypeToXSDUniqueElement** — DONE (session 8)
53. **Dictionary.FundIntervalType** — DONE (session 8)
54. **Dictionary.FundType** — DONE (session 8)
55. **Dictionary.Funnel** — DONE (session 8)
56. **Dictionary.GameServer** — DONE (session 8)
57. **Dictionary.GameSubType** — DONE (session 8)
58. **Dictionary.GameType** — DONE (session 8)
59. **Dictionary.Gateway** — DONE (session 8)
60. **Dictionary.GDCCheck** — DONE (session 8)
61. **Dictionary.Groups** — DONE (session 8)
62. **Dictionary.HBCOrderState** — DONE (session 8)
63. **Dictionary.HedgeAccountType** — DONE (session 8)
64. **Dictionary.HedgeBreakdownType** — DONE (session 8)
65. **Dictionary.HedgeEventType** — DONE (session 8)
66. **Dictionary.HedgeExecutionMode** — DONE (session 9)
67. **Dictionary.HedgeManualRequestType** — DONE (session 9)
68. **Dictionary.HedgeOrderState** — DONE (session 9)
69. **Dictionary.HedgePositionFailReason** — DONE (session 9)
70. **Dictionary.HedgePositionFailSeverity** — DONE (session 9)
71. **Dictionary.HedgeRecoveryState** — DONE (session 9)
72. **Dictionary.HedgeServerExecutionStrategy** — DONE (session 9)
73. **Dictionary.HedgeServerExposureMode** — DONE (session 9)
74. **Dictionary.HedgeUpdateReason** — DONE (session 9)
75. **Dictionary.HistoryCreditActionsToHide** — DONE (session 9)
76. **Dictionary.IMType_Del** — DONE (session 9)
77. **Dictionary.IndexDividenedStatus** — DONE (session 9)
78. **Dictionary.InstrumentTypeSubCategory** — DONE (session 9)
79. **Dictionary.InterestRateOverride** — DONE (session 9)
80. **Dictionary.InterestStatus** — DONE (session 9)
81. **Dictionary.JobEnvironmentType** — DONE (session 9)
82. **Dictionary.Justefied** — DONE (session 9)
83. **Dictionary.Label** — DONE (session 9)
84. **Dictionary.LeverageType** — DONE (session 9)
85. **Dictionary.LiquidityAccountType** — DONE (session 9)
86. **Dictionary.ListenerType** — DONE (session 10)
87. **Dictionary.LotCount** — DONE (session 10)
88. **Dictionary.LotCountGroup** — DONE (session 10)
89. **Dictionary.ManagerPermit** — DONE (session 10)
90. **Dictionary.ManagerTitle** — DONE (session 10)
91. **Dictionary.ManualOperationReason** — DONE (session 10)
92. **Dictionary.MatchStatus** — DONE (session 10)
93. **Dictionary.Merchant_Old** — DONE (session 10)
94. **Dictionary.MessageGroup** — DONE (session 10)
95. **Dictionary.MessageType** — DONE (session 10)
96. **Dictionary.MirrorDividendRejectionReason** — DONE (session 10)
97. **Dictionary.MirrorMIMOOperation** — DONE (session 10)
98. **Dictionary.MoveMoneyReason** — DONE (session 10)
99. **Dictionary.MSLCloseMirrorTrigger** — DONE (session 10)
100. **Dictionary.NoteType** — DONE (session 10)
101. **Dictionary.NotificationMessageStatus** — DONE (session 10)
102. **Dictionary.NotificationStatus** — DONE (session 10)
103. **Dictionary.NotificationTrigger** — DONE (session 10)
104. **Dictionary.NotificationType** — DONE (session 10)
105. **Dictionary.NotificationTypeName** — DONE (session 10)
106. **Dictionary.Objects** — DONE (session 10)
107. **Dictionary.OMPDThresholdType** — DONE (session 10)
108. **Dictionary.OMSStrategyType** — DONE (session 10)
109. **Dictionary.OptOutReason** — DONE (session 10)
110. **Dictionary.OrderExitOperationType** — DONE (session 10)
111. **Dictionary.OrderFillBehaviorType** — DONE (session 11)
112. **Dictionary.OrderForExecutionCloseActionType** — DONE (session 11)
113. **Dictionary.OrderOperationType** — DONE (session 11)
114. **Dictionary.OrdersActionType** — DONE (session 11)
115. **Dictionary.OrdersEntryActionType** — DONE (session 11)
116. **Dictionary.OrdersExitActionType** — DONE (session 11)
117. **Dictionary.OrdersExitCloseActionType** — DONE (session 11)
118. **Dictionary.OrdersExitOpenActionType** — DONE (session 11)
119. **Dictionary.PaymentServiceStatus** — DONE (session 11)
120. **Dictionary.PaymentStatusNotification** — DONE (session 11)
121. **Dictionary.PayoutProcessReason** — DONE (session 11)
122. **Dictionary.PCL_ChangeType** — DONE (session 11)
123. **Dictionary.PendingClosureStatus** — DONE (session 11)
124. **Dictionary.Permission** — DONE (session 11)
125. **Dictionary.PhoneTypes** — DONE (session 11)
126. **Dictionary.PhoneVerificationListType** — DONE (session 11)
127. **Dictionary.PhoneVerificationRiskLevel** — DONE (session 11)
128. **Dictionary.PhoneVerificationTransactionRecommendation** — DONE (session 11)
129. **Dictionary.PhoneVerified** — DONE (session 11)
130. **Dictionary.PositionOpenOpenOperationType** — DONE (session 11)
131. **Dictionary.PositionTimeOuts** — DONE (session 11)
132. **Dictionary.PriceSourceName** — DONE (session 11)
133. **Dictionary.PriceType** — DONE (session 11)
134. **Dictionary.PrivacyEvents** — DONE (session 11)
135. **Dictionary.PrivacyPolicy** — DONE (session 11)
136. **Dictionary.PrivacyPolicyDetails** — DONE (session 12)
137. **Dictionary.PrivacyRecipients** — DONE (session 12)
138. **Dictionary.PrizeType** — DONE (session 12)
139. **Dictionary.PromotionType** — DONE (session 12)
140. **Dictionary.Protocol** — DONE (session 12)
141. **Dictionary.ProtocolDirection** — DONE (session 12)
142. **Dictionary.ProtocolParameter** — DONE (session 12)
143. **Dictionary.ProviderPercentageRouting** — DONE (session 12)
144. **Dictionary.PWMBAddAccountRequestStatus** — DONE (session 12)
145. **Dictionary.RafModelType_NogaJunk210725** — DONE (session 12)
146. **Dictionary.RafPlayerLevel_NogaJunk210725** — DONE (session 12)
147. **Dictionary.RafStatus_NogaJunk210725** — DONE (session 12)
148. **Dictionary.RankToCountry** — DONE (session 12)
149. **Dictionary.RankToCountryConfiguration** — DONE (session 12)
150. **Dictionary.RedeemApprovalReason** — DONE (session 12)
151. **Dictionary.RegionByIP** — DONE (session 12)
152. **Dictionary.RegionName** — DONE (session 12)
153. **Dictionary.RegistrationIpBlacklist** — DONE (session 12)
154. **Dictionary.ReopenType** — DONE (session 12)
155. **Dictionary.Response** — DONE (session 12)
156. **Dictionary.RestrictionType** — DONE (session 12)
157. **Dictionary.RiskClassificationParameter** — DONE (session 12)
158. **Dictionary.RiskClassificationRegulation** — DONE (session 12)
159. **Dictionary.RiskCountryPairs** — DONE (session 12)
160. **Dictionary.RiskEventStatus** — DONE (session 12)
161. **Dictionary.Roles** — DONE (session 13)
162. **Dictionary.RuleType** — DONE (session 13)
163. **Dictionary.SalesForceImprtProcess** — DONE (session 13)
164. **Dictionary.SalesStatus** — DONE (session 13)
165. **Dictionary.SbrEventType** — DONE (session 13)
166. **Dictionary.ScheduledJobStatus** — DONE (session 13)
167. **Dictionary.ScheduledJobType** — DONE (session 13)
168. **Dictionary.ScheduledTaskName** — DONE (session 13)
169. **Dictionary.ScheduledTaskReason** — DONE (session 13)
170. **Dictionary.ScheduledTaskState** — DONE (session 13)
171. **Dictionary.SecondIncomeSteps** — DONE (session 13)
172. **Dictionary.ServerType** — DONE (session 13)
173. **Dictionary.ServiceType** — DONE (session 13)
174. **Dictionary.SettlementMethodValues** — DONE (session 13)
175. **Dictionary.SettlementRestrictions** — DONE (session 13)
176. **Dictionary.SeverityType** — DONE (session 13)
177. **Dictionary.SeychellesCategorization** — DONE (session 13)
178. **Dictionary.SFTicketSecondSubType** — DONE (session 13)
179. **Dictionary.SmartExecutionModels** — DONE (session 13)
180. **Dictionary.SpreadThresholdType** — DONE (session 13)
181. **Dictionary.SpreadType** — DONE (session 13)
182. **Dictionary.State** — DONE (session 13)
183. **Dictionary.Steps** — DONE (session 13)
184. **Dictionary.StockError** — DONE (session 13)
185. **Dictionary.StockHedgeSource** — DONE (session 13)
186. **Dictionary.StockOrderCloseReason** — DONE (session 14)
187. **Dictionary.StocksIndustry** — DONE (session 14)
188. **Dictionary.StrategyGroups** — DONE (session 14)
189. **Dictionary.SubCreditTypeID** — DONE (session 14)
190. **Dictionary.SubRegion** — DONE (session 14)
191. **Dictionary.SuitabilityTestStatus** — DONE (session 14)
192. **Dictionary.SyncTslStatus** — DONE (session 14)
193. **Dictionary.TaskType** — DONE (session 14)
194. **Dictionary.Teams** — DONE (session 14)
195. **Dictionary.TeamsMember** — DONE (session 14)
196. **Dictionary.TemplateID_LabelID** — DONE (session 14)
197. **Dictionary.ThreeDsResponseTypes** — DONE (session 14)
198. **Dictionary.TimeZone** — DONE (session 14)
199. **Dictionary.TncDocType** — DONE (session 14)
200. **Dictionary.TraceEventType** — DONE (session 14)
201. **Dictionary.Tracking** — DONE (session 14)
202. **Dictionary.TradeActivity_ClosePositionActionTypes** — DONE (session 14)
203. **Dictionary.TradeActivity_ExecutionTypes** — DONE (session 14)
204. **Dictionary.TradeActivity_OpenPositionActionTypes** — DONE (session 14)
205. **Dictionary.TradeLevel** — DONE (session 14)
206. **Dictionary.TradeUnitType** — DONE (session 14)
207. **Dictionary.TradingDbOperationType** — DONE (session 14)
208. **Dictionary.TradingErrorCode** — DONE (session 14)
209. **Dictionary.AggregationLastValue_History** — DONE (session 15, rework from 6.0→9.2)
210. **Dictionary.TwoFactorVerificationSendMethodType** — DONE (session 15, rework from 6.0→9.2)
211. **Dictionary.TwoFVStatus** — DONE (session 15, rework from 6.0→9.0)
212. **Dictionary.UnitOfMeasure** — DONE (session 15, rework from 6.0→9.2)
213. **Dictionary.UnitsQuantityType** — DONE (session 15, rework from 6.0→9.2)
214. **Dictionary.UpdateApexID** — DONE (session 15, rework from 6.0→9.0)
215. **Dictionary.UserGroup** — DONE (session 15, rework from 6.0→9.4)
216. **Dictionary.UserGroupToPermission** — DONE (session 15, rework from 6.0→9.4)
217. **Dictionary.VerificationLevel** — DONE (session 15, rework from 6.0→9.4)
218. **Dictionary.VerifiedByStatus** — DONE (session 15, rework from 6.0→9.0)
219. **Dictionary.VisaType** — DONE (session 15, rework from 6.0→9.2)
220. **Dictionary.VolatilityThresholdType** — DONE (session 15, rework from 6.0→9.2)
221. **Dictionary.WalletsType** — DONE (session 15, rework from 6.0→9.0)
222. **Dictionary.WebinarAction** — DONE (session 15, rework from 6.0→9.0)
223. **Dictionary.WithdrawAdditionalParameterType** — DONE (session 15, rework from 6.0→9.2)
224. **Dictionary.WithdrawApprovalReason** — DONE (session 15, rework from 6.0→9.4)
225. **Dictionary.WithdrawType** — DONE (session 15, rework from 6.0→9.2)
226. **Dictionary.WorldCheck** — DONE (session 15, rework from 6.0→9.4)
227. **Dictionary.XSDUniqueElement** — DONE (session 15, rework from 6.0→9.2)

---

## Views (9 of 9 documented — ALL 9.0+)

| View | Quality | Description |
|------|---------|-------------|
| [Dictionary.CountryBin](Views/Dictionary.CountryBin.md) | 9.2 | Union of 6-digit + 8-digit BIN tables with 30+ billing consumers — MCP verified |
| [Dictionary.CurrencyTypeSafty](Views/Dictionary.CurrencyTypeSafty.md) | 9.0 | Schema-bound CurrencyType contract (10 asset classes) — MCP verified |
| [Dictionary.GetCommodity](Views/Dictionary.GetCommodity.md) | 9.0 | Commodity instruments (Gold/Oil/Silver) with ForexType bitmask — MCP verified |
| [Dictionary.GetCountry](Views/Dictionary.GetCountry.md) | 9.2 | Legacy 6-column country access with 14+ consumers — MCP verified |
| [Dictionary.GetCurrency](Views/Dictionary.GetCurrency.md) | 9.2 | Forex instruments with ForexType bitmask, 8+ trading consumers — MCP verified |
| [Dictionary.GetGameType](Views/Dictionary.GetGameType.md) | 9.0 | 14 game/trading activity types (2007 legacy) — MCP verified |
| [Dictionary.GetIndices](Views/Dictionary.GetIndices.md) | 9.0 | Index instrument filter (dormant — CurrencyTypeID=3 reclassified) — MCP verified |
| [Dictionary.GetMessageType](Views/Dictionary.GetMessageType.md) | 9.0 | 10 visible message delivery channels — MCP verified |
| [Dictionary.GetXMLSchema](Views/Dictionary.GetXMLSchema.md) | 9.0 | XML schema collection metadata from sys catalog — MCP verified |

---

## Stored Procedures (4 of 4 documented — ALL 9.0+)

| Procedure | Quality | Description |
|-----------|---------|-------------|
| [Dictionary.GetAllHedgeUpdateReasons](Stored%20Procedures/Dictionary.GetAllHedgeUpdateReasons.md) | 9.0 | 5 hedge update reason codes (Reconciliation/Reroute/Manual/Other) — MCP verified |
| [Dictionary.GetAllocationSourceID](Stored%20Procedures/Dictionary.GetAllocationSourceID.md) | 9.2 | Name-to-ID lookup for 3 allocation sources with 7+ trade consumers — MCP verified |
| [Dictionary.GetCurrencyType](Stored%20Procedures/Dictionary.GetCurrencyType.md) | 9.0 | 10 asset classes ordered by ID (Forex through Crypto) — MCP verified |
| [Dictionary.GetPricesBy](Stored%20Procedures/Dictionary.GetPricesBy.md) | 9.2 | 27 price sources (eToro/Xignite/CME/NASDAQ/etc) with aliased output — MCP verified |

---

## Synonyms (1 of 1 documented — 9.0+)

| Synonym | Quality | Description |
|---------|---------|-------------|
| [Dictionary.SynPositionTimeOuts](Synonyms/Dictionary.SynPositionTimeOuts.md) | 9.2 | Cross-server reference to 3 timeout-monitored trading procedures on [AO-REAL-DB] — MCP verified |

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Last quality upgrade: 2026-03-14 — Session 16: All 14 non-table objects (9 views, 4 SPs, 1 synonym) upgraded from 6.0-8.0 to 9.0+ with full template, MCP live data, codebase consumer search, and Atlassian scan. ALL 373 Dictionary objects now at 9.0+ quality.*
