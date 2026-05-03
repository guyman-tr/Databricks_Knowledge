# Pre-Resolved Upstream Bundle for `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239.sql`

```sql
CREATE TABLE [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](40) NULL,
	[@SettlementsTransactions@Id-333243] [varchar](40) NULL,
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
	[CardNumber] [varchar](max) NULL,
	[CardNumberId] [varchar](max) NULL,
	[CardRequestId] [varchar](max) NULL,
	[MtiCode] [varchar](max) NULL,
	[MessageReasonCode] [varchar](max) NULL,
	[Bin] [varchar](max) NULL,
	[TransactionCode] [varchar](max) NULL,
	[TransactionCodeDescription] [varchar](max) NULL,
	[AuthorizationCode] [varchar](max) NULL,
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
	[FxFeeCode] [varchar](max) NULL,
	[FxFeeAmount] [varchar](max) NULL,
	[FxFeeCurrency] [varchar](max) NULL,
	[FxFeeReason] [varchar](max) NULL,
	[F0FeeName] [varchar](max) NULL,
	[F0FeeCode] [varchar](max) NULL,
	[F0FeeAmount] [varchar](max) NULL,
	[F0FeeCurrency] [varchar](max) NULL,
	[F0FeeReason] [varchar](max) NULL,
	[BillRateAmount] [varchar](max) NULL,
	[BillingDate] [varchar](max) NULL,
	[BillingAmount] [varchar](max) NULL,
	[BillingCurrencyCode] [varchar](max) NULL,
	[BillingCurrencyAlpha] [varchar](max) NULL,
	[ReconciliationDate] [varchar](max) NULL,
	[SettlementDate] [varchar](max) NULL,
	[SettlementAmount] [varchar](max) NULL,
	[SettlementCurrencyCode] [varchar](max) NULL,
	[SettlementCurrencyAlpha] [varchar](max) NULL,
	[SettlementConversionRate] [varchar](max) NULL,
	[MerchantNumber] [varchar](max) NULL,
	[Merchant] [varchar](max) NULL,
	[MerchantName] [varchar](max) NULL,
	[MerchantAddress] [varchar](max) NULL,
	[MerchantCity] [varchar](max) NULL,
	[MerchantPostcode] [varchar](max) NULL,
	[MerchantCountryCodeAlpha] [varchar](max) NULL,
	[MerchantCountryName] [varchar](max) NULL,
	[Mcc] [varchar](max) NULL,
	[CardPresent] [varchar](max) NULL,
	[CardInputMode] [varchar](max) NULL,
	[CardholderAuthenticationMethod] [varchar](max) NULL,
	[PosDataDe22] [varchar](max) NULL,
	[PosDataDe61] [varchar](max) NULL,
	[AcquirerId] [varchar](max) NULL,
	[AcquirerReferenceNumber] [varchar](max) NULL,
	[TransactionId] [varchar](max) NULL,
	[InterchangeFeeAmount] [varchar](max) NULL,
	[InterchangeFeeCurrency] [varchar](max) NULL,
	[InterchangeFeeDirection] [varchar](max) NULL,
	[InterchangeRateDesignator] [varchar](max) NULL,
	[CycleNumber] [varchar](max) NULL,
	[CycleFileId] [varchar](max) NULL,
	[TransactionClass] [varchar](max) NULL,
	[Action] [varchar](max) NULL,
	[Network] [varchar](max) NULL,
	[TransactionDescription] [varchar](max) NULL,
	[EntryModeCode] [varchar](max) NULL,
	[EntryModeCodeDescription] [varchar](max) NULL,
	[ECIIndicator] [varchar](max) NULL,
	[Suspicious] [varchar](max) NULL,
	[RiskRuleCodes] [varchar](max) NULL,
	[FunctionCode] [varchar](max) NULL,
	[LoadType] [varchar](max) NULL,
	[LoadSource] [varchar](max) NULL,
	[SettlementFlag] [varchar](max) NULL,
	[TransactionCodeQualifier] [varchar](max) NULL,
	[BusinessFormatCode] [varchar](max) NULL,
	[CardType] [varchar](max) NULL,
	[ParentTransactionId] [varchar](max) NULL,
	[DisputeId] [varchar](max) NULL,
	[ExternalDisputeId] [varchar](max) NULL,
	[ActualAuthorizationId] [varchar](max) NULL,
	[FirstAuthorizationDate] [varchar](max) NULL,
	[InterchangeFeeAmountRounded] [varchar](max) NULL,
	[ReferenceNumber] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[PosDataExtendedDe61] [varchar](max) NULL,
	[Created] [datetime2](7) NULL,
	[TokenizedRequest] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_637239] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_637239_c2] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@SettlementsTransactions@Id-333243] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_637239_Id] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
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
