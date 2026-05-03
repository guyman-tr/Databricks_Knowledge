# Pre-Resolved Upstream Bundle for `EXW_Wallet.AmlValidations`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.AmlValidations.sql`

```sql
CREATE TABLE [EXW_Wallet].[AmlValidations]
(
	[Id] [int] NULL,
	[AmlProviderId] [int] NULL,
	[IsSend] [bit] NULL,
	[Address] [varchar](max) NULL,
	[WalletId] [uniqueidentifier] NULL,
	[Amount] [numeric](36, 18) NULL,
	[ProviderStatus] [varchar](max) NULL,
	[IsPositiveDecision] [bit] NULL,
	[CorrelationId] [uniqueidentifier] NULL,
	[Created] [datetime2](7) NULL,
	[BlockchainTransactionId] [varchar](max) NULL,
	[DetailsJson] [varchar](max) NULL,
	[CryptoId] [int] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[CategoryId] [int] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CorrelationId] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
