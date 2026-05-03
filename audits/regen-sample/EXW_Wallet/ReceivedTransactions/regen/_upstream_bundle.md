# Pre-Resolved Upstream Bundle for `EXW_Wallet.ReceivedTransactions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.ReceivedTransactions.sql`

```sql
CREATE TABLE [EXW_Wallet].[ReceivedTransactions]
(
	[Id] [bigint] NULL,
	[Occurred] [datetime2](7) NULL,
	[WalletId] [varchar](4000) NULL,
	[SenderAddress] [varchar](max) NULL,
	[ReceiverAddress] [varchar](max) NULL,
	[Amount] [numeric](36, 18) NULL,
	[BlockchainFee] [numeric](36, 18) NULL,
	[CorrelationId] [varchar](4000) NULL,
	[BlockchainTransactionId] [varchar](max) NULL,
	[BlockchainTransactionDate] [datetime2](7) NULL,
	[CryptoId] [int] NULL,
	[ReceivedTransactionTypeId] [int] NULL,
	[NormalizedSenderAddress] [varchar](max) NULL,
	[NormalizedReceiverAddress] [varchar](max) NULL,
	[ProviderTransactionId] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[ReceiveRequestCorrelationId] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [Id] ),
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
