# Pre-Resolved Upstream Bundle for `eMoney_Tribe.Authorizes_Authorize-312243`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.Authorizes_Authorize-312243.sql`

```sql
CREATE TABLE [eMoney_Tribe].[Authorizes_Authorize-312243]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](40) NULL,
	[@Authorizes@Id-837045] [varchar](40) NULL,
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
	[CardLimitsGroupName] [varchar](max) NULL,
	[CardLimitsGroupId] [varchar](max) NULL,
	[AccountLimitsGroupName] [varchar](max) NULL,
	[AccountLimitsGroupId] [varchar](max) NULL,
	[HolderLimitsGroupName] [varchar](max) NULL,
	[HolderLimitsGroupId] [varchar](max) NULL,
	[FeeGroupName] [varchar](max) NULL,
	[FeeGroupId] [varchar](max) NULL,
	[CardNumber] [varchar](max) NULL,
	[CardNumberId] [varchar](max) NULL,
	[CardRequestId] [varchar](max) NULL,
	[MtiCode] [varchar](max) NULL,
	[ResponseCode] [varchar](max) NULL,
	[ResponseCodeDescription] [varchar](max) NULL,
	[ResponseDeclineDescription] [varchar](max) NULL,
	[TransactionCode] [varchar](max) NULL,
	[TransactionCodeDescription] [varchar](max) NULL,
	[Bin] [varchar](max) NULL,
	[AuthorizationCode] [varchar](max) NULL,
	[TransactionDateTime] [varchar](max) NULL,
	[TransactionAmount] [varchar](max) NULL,
	[TransactionCurrencyCode] [varchar](max) NULL,
	[TransactionCurrencyAlpha] [varchar](max) NULL,
	[TransactionCountryCode] [varchar](max) NULL,
	[TransLink] [varchar](max) NULL,
	[Stan] [varchar](max) NULL,
	[TribeTransactionReference] [varchar](max) NULL,
	[FxRate] [varchar](max) NULL,
	[CumulativePaddingAmount] [varchar](max) NULL,
	[AppliedPaddingAmount] [varchar](max) NULL,
	[MccPaddingReason] [varchar](max) NULL,
	[BillRateAmount] [varchar](max) NULL,
	[BillingDate] [varchar](max) NULL,
	[BillingAmount] [varchar](max) NULL,
	[BillingCurrencyCode] [varchar](max) NULL,
	[BillingCurrencyAlpha] [varchar](max) NULL,
	[SettlementAmount] [varchar](max) NULL,
	[SettlementCurrencyCode] [varchar](max) NULL,
	[SettlementCurrencyAlpha] [varchar](max) NULL,
	[SettlementConversionRate] [varchar](max) NULL,
	[MerchantNumber] [varchar](max) NULL,
	[MerchantName] [varchar](max) NULL,
	[MerchantCountryCodeAlpha] [varchar](max) NULL,
	[MerchantCountryName] [varchar](max) NULL,
	[Mcc] [varchar](max) NULL,
	[CardPresent] [varchar](max) NULL,
	[PosDataDe22] [varchar](max) NULL,
	[PosDatDe61] [varchar](max) NULL,
	[AcquirerId] [varchar](max) NULL,
	[ReferenceNumber] [varchar](max) NULL,
	[TraceNumber] [varchar](max) NULL,
	[Action] [varchar](max) NULL,
	[Network] [varchar](max) NULL,
	[EntryModeCode] [varchar](max) NULL,
	[EntryModeCodeDescription] [varchar](max) NULL,
	[ECIIndicator] [varchar](max) NULL,
	[Suspicious] [varchar](max) NULL,
	[RiskRuleCodes] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[PosDataExtendedDe61] [varchar](max) NULL,
	[Created] [datetime2](7) NULL,
	[PosDataDe61] [varchar](max) NULL,
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
CREATE NONCLUSTERED INDEX [ClusteredIndex_Authorize_312243_c2] ON [eMoney_Tribe].[Authorizes_Authorize-312243]
(
	[@Authorizes@Id-837045] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_Authorizes_312243] ON [eMoney_Tribe].[Authorizes_Authorize-312243]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[Authorizes_Authorize-312243]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_312243_Id] ON [eMoney_Tribe].[Authorizes_Authorize-312243]
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
