# Pre-Resolved Upstream Bundle for `eMoney_Tribe.AccountsActivities_AccountActivity-833937`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.AccountsActivities_AccountActivity-833937.sql`

```sql
CREATE TABLE [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](40) NULL,
	[@AccountsActivities@Id-862157] [varchar](40) NULL,
	[FileDate] [varchar](max) NULL,
	[WorkDate] [varchar](max) NULL,
	[@WorkDate] [datetime2](7) NULL,
	[IssuerIdentificationNumber] [varchar](max) NULL,
	[ProgramName] [varchar](max) NULL,
	[ProgramId] [varchar](max) NULL,
	[ProductName] [varchar](max) NULL,
	[ProductId] [varchar](max) NULL,
	[SubProductId] [varchar](max) NULL,
	[HolderId] [varchar](max) NULL,
	[AccountId] [varchar](max) NULL,
	[BankAccountId] [varchar](max) NULL,
	[ExternalBankAccountId] [varchar](max) NULL,
	[BankAccountNumber] [varchar](max) NULL,
	[BankAccountSortCode] [varchar](max) NULL,
	[BankAccountIban] [varchar](max) NULL,
	[BankAccountBic] [varchar](max) NULL,
	[CardNumber] [varchar](max) NULL,
	[CardNumberId] [varchar](max) NULL,
	[CardRequestId] [varchar](max) NULL,
	[Bin] [varchar](max) NULL,
	[TransactionCode] [varchar](max) NULL,
	[TransactionCodeDescription] [varchar](max) NULL,
	[TransactionDateTime] [varchar](max) NULL,
	[TransactionAmount] [varchar](max) NULL,
	[TransactionCurrencyCode] [varchar](max) NULL,
	[TransactionCurrencyAlpha] [varchar](max) NULL,
	[TransLink] [varchar](max) NULL,
	[TraceId] [varchar](max) NULL,
	[TransactionCodeIdentifier] [varchar](max) NULL,
	[HolderAmount] [varchar](max) NULL,
	[HolderCurrencyCode] [varchar](max) NULL,
	[HolderCurrencyAlpha] [varchar](max) NULL,
	[FxRate] [varchar](max) NULL,
	[FeeGroupId] [varchar](max) NULL,
	[FeeGroupName] [varchar](max) NULL,
	[FxFeeName] [varchar](max) NULL,
	[FxFeeAmount] [varchar](max) NULL,
	[FxFeeCurrency] [varchar](max) NULL,
	[FxFeeReason] [varchar](max) NULL,
	[F0FeeName] [varchar](max) NULL,
	[F0FeeAmount] [varchar](max) NULL,
	[F0FeeCurrency] [varchar](max) NULL,
	[F0FeeReason] [varchar](max) NULL,
	[BillRateAmount] [varchar](max) NULL,
	[BillingDate] [varchar](max) NULL,
	[BillingAmount] [varchar](max) NULL,
	[BillingCurrencyCode] [varchar](max) NULL,
	[BillingCurrencyAlpha] [varchar](max) NULL,
	[SettlementAmount] [varchar](max) NULL,
	[SettlementCurrencyCode] [varchar](max) NULL,
	[SettlementCurrencyAlpha] [varchar](max) NULL,
	[SettlementConversionRate] [varchar](max) NULL,
	[CardPresent] [varchar](max) NULL,
	[TransactionId] [varchar](max) NULL,
	[TransactionClass] [varchar](max) NULL,
	[Action] [varchar](max) NULL,
	[Network] [varchar](max) NULL,
	[TransactionDescription] [varchar](max) NULL,
	[EntryModeCode] [varchar](max) NULL,
	[EntryModeCodeDescription] [varchar](max) NULL,
	[ReferenceNumber] [varchar](max) NULL,
	[CountryIson] [varchar](max) NULL,
	[LoadType] [varchar](max) NULL,
	[LoadSource] [varchar](max) NULL,
	[EpmMethodId] [varchar](max) NULL,
	[EpmTransactionId] [varchar](max) NULL,
	[ExternalEpmTransactionId] [varchar](max) NULL,
	[EpmTransactionType] [varchar](max) NULL,
	[EpmTransactionStatusCode] [varchar](max) NULL,
	[EpmMandateId] [varchar](max) NULL,
	[Reference] [varchar](max) NULL,
	[TransactionIdentifier] [varchar](max) NULL,
	[EndToEndIdentifier] [varchar](max) NULL,
	[Suspicious] [varchar](max) NULL,
	[RiskRuleCodes] [varchar](max) NULL,
	[BalanceAdjustmentType] [varchar](max) NULL,
	[EpmTransactionStatus] [varchar](max) NULL,
	[EpmTransactionReasonDescription] [varchar](max) NULL,
	[EpmTransactionBankProviderReasonCode] [varchar](max) NULL,
	[ParentTransactionId] [varchar](max) NULL,
	[DisputeId] [varchar](max) NULL,
	[ExternalDisputeId] [varchar](max) NULL,
	[ExternalPaymentScheme] [varchar](max) NULL,
	[ExternalIbanCountry] [varchar](max) NULL,
	[InternalIbanCountry] [varchar](max) NULL,
	[ExternalIban] [varchar](max) NULL,
	[ExternalBban] [varchar](max) NULL,
	[ExternalAccountName] [varchar](max) NULL,
	[ExternalAccountNumber] [varchar](max) NULL,
	[ExternalSortCode] [varchar](max) NULL,
	[ExternalBIC] [varchar](max) NULL,
	[OriginatorId] [varchar](max) NULL,
	[OriginatorName] [varchar](max) NULL,
	[OriginatorServiceUserNumber] [varchar](max) NULL,
	[TransactionReferenceNumber] [varchar](max) NULL,
	[ActualEndToEndIdentifier] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[Created] [datetime2](7) NULL,
	[ProductCode] [varchar](max) NULL,
	[MasterAccountId] [varchar](max) NULL,
	[MasterAccountName] [varchar](max) NULL,
	[MasterAccountIban] [varchar](max) NULL,
	[RequestReferenceId] [varchar](max) NULL,
	[ExternalEndToEndIdentifier] [varchar](max) NULL,
	[BankAccountBankStateBranch] [varchar](max) NULL,
	[ExternalBankStateBranch] [varchar](max) NULL,
	[BankAccountBankBranchCode] [varchar](max) NULL,
	[ExternalBankBranchCode] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [@Id] ),
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_AA_833937_Id] ON [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_AA_833937_c2] ON [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
(
	[@AccountsActivities@Id-862157] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_833937_Id] ON [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
