# Pre-Resolved Upstream Bundle for `EXW_Wallet.SentTransactions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.SentTransactions.sql`

```sql
CREATE TABLE [EXW_Wallet].[SentTransactions]
(
	[Id] [bigint] NULL,
	[BlockchainTransactionId] [varchar](4000) NULL,
	[WalletId] [varchar](4000) NULL,
	[Occurred] [datetime2](7) NULL,
	[CorrelationId] [uniqueidentifier] NULL,
	[TransactionTypeId] [int] NULL,
	[BlockchainFee] [numeric](36, 18) NULL,
	[CryptoId] [int] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [Id] ),
	HEAP
)

GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [EXW_Wallet].[SentTransactions]
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
