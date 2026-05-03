# Pre-Resolved Upstream Bundle for `EXW_Wallet.WalletPoolStatuses`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.WalletPoolStatuses.sql`

```sql
CREATE TABLE [EXW_Wallet].[WalletPoolStatuses]
(
	[Id] [bigint] NULL,
	[WalletPoolId] [bigint] NULL,
	[WalletPoolStatusId] [int] NULL,
	[Occurred] [datetime2](7) NULL,
	[PromotionTagId] [int] NULL,
	[CorrelationId] [uniqueidentifier] NULL,
	[Processed] [bit] NULL,
	[CryptoId] [int] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [WalletPoolId] ),
	HEAP
)

GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [EXW_Wallet].[WalletPoolStatuses]
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
