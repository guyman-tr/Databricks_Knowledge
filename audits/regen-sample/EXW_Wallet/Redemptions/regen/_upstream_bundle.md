# Pre-Resolved Upstream Bundle for `EXW_Wallet.Redemptions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.Redemptions.sql`

```sql
CREATE TABLE [EXW_Wallet].[Redemptions]
(
	[Id] [bigint] NULL,
	[OriginalRequestGuid] [uniqueidentifier] NULL,
	[SendRequestCorrelationId] [uniqueidentifier] NULL,
	[PositionId] [bigint] NULL,
	[RequestingGcid] [bigint] NULL,
	[CryptoId] [int] NULL,
	[RequestedAmount] [numeric](36, 18) NULL,
	[eToroFeeAmount] [numeric](36, 18) NULL,
	[RedemptionStatus] [int] NULL,
	[BillingTransId] [bigint] NULL,
	[BillingRedeemId] [bigint] NULL,
	[BeginDate] [datetime2](7) NULL,
	[EndDate] [datetime2](7) NULL,
	[EstimatedBlockchainFee] [numeric](36, 18) NULL,
	[InitialFeeAmount] [numeric](36, 18) NULL,
	[SourceWalletId] [uniqueidentifier] NULL,
	[TransactionTypeId] [int] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [SendRequestCorrelationId] ),
	HEAP
)

GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [EXW_Wallet].[Redemptions]
(
	[partition_date] ASC
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
